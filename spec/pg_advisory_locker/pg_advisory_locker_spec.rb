require 'spec_helper'

class Temp < ActiveRecord::Base
  include PgAdvisoryLocker
end

describe PgAdvisoryLocker do

  before do
    ActiveRecord::Base.connection.execute <<-SQL
      create table temps
      (
          id                       serial not null primary key,
          created_at               timestamp not null default now(),
          name                     text null unique,
          identification_number    integer not null unique
      );
    SQL
  end

  let(:lock_id) { 239 }
  subject { Temp.new }

  describe "advisory_lock" do
    it "should receive lock_record" do
      Temp.should_receive(:lock_record)
      subject.advisory_lock
    end
  end # advisory_lock

  describe "advisory_try_lock" do
    it "should receive try_lock_record" do
      Temp.should_receive(:try_lock_record)
      subject.advisory_try_lock
    end
  end # advisory_try_lock

  describe "advisory_unlock" do
    it "should receive unlock_record" do
      Temp.should_receive(:unlock_record)
      subject.advisory_unlock
    end
  end # advisory_unlock

  describe "table_oid" do
    it "returns table_oid" do
      Temp.find_by_sql("SELECT * FROM pg_class WHERE pg_class.oid = #{Temp.table_oid}").
          first.relname.should == "temps"
    end
  end # table_oid

  describe "lock_record" do
    it "locks record" do
      Temp.lock_record(lock_id)
      Temp.find_by_sql("select * from pg_locks").
          select{|x| x.objid == "#{lock_id}" && x.classid == "#{Temp.table_oid}"}.
          should have(1).item
      Temp.unlock_record(lock_id)
    end
  end # lock_record

  describe "try_lock_record" do
    it "locks record" do
      Temp.try_lock_record(lock_id)
      Temp.find_by_sql("select * from pg_locks").
          select{|x| x.objid == "#{lock_id}" && x.classid == "#{Temp.table_oid}"}.
          should have(1).item
      Temp.unlock_record(lock_id)
    end
  end # try_lock_record

  describe "unlock_record" do
    it "unlocks record" do
      Temp.lock_record(lock_id)
      Temp.unlock_record(lock_id)
      Temp.find_by_sql("select * from pg_locks").
          select{|x| x.objid == "#{lock_id}" && x.classid == "#{Temp.table_oid}"}.
          should be_blank
    end
  end # unlock_record

end # PgAdvisoryLocker