module PgAdvisoryLocker
  def self.included(base)
    base.extend(ClassMethods)
  end

  # advisory lock this row associated identified by model#id
  #
  # blocks until advisory lock is release
  # acquires lock on return
  #
  # if block is passed in, lock/unlock around the block
  def advisory_lock(&block)
    return self.class.lock_record(id, &block)
  end

  # advisory try lock this row associated identified by model#id
  #
  # if lock is acquired, acquires lock and returns true
  # if lock is currently acquired, returns false
  # never blocks
  #
  # if block is passed in, lock/unlock around the block
  # executing block only if lock is acquired
  def advisory_try_lock(&block)
    return self.class.try_lock_record(id, &block)
  end

  # advisory unlock this row associated identified by model#id
  #
  # on return releases lock
  def advisory_unlock
    self.class.unlock_record(id)
  end

  module ClassMethods
    # table_oid is good unique identifier value for the table
    # We could use a has of the name if the thought there would
    # be no collisions
    # The OID is always unique, so we use it
    def table_oid
      if @table_oid.nil?
        sql_table_components = table_name.split('.')
        if sql_table_components.length == 1
          sql_table_components.prepend('public')
        end
        sql = <<-SQL
         SELECT
           pg_class.oid
         FROM
           pg_class,pg_namespace
         WHERE
           pg_namespace.nspname = ? AND
           pg_class.relnamespace = pg_namespace.oid AND
           pg_class.relname = ?
        SQL
        @table_oid = find_by_sql([sql, *sql_table_components]).first.oid.to_i
      end
      return @table_oid
    end

    # advisory lock for this model, with key2 as argument
    # blocks until advisory lock is release
    # acquires lock on return
    #
    # if block is passed in, lock/unlock around the block
    def lock_record(key2, &block)
      return pg_advisory_lock(table_oid, key2, &block)
    end

    # advisory try lock for this model, with key2 as argument
    #
    # if lock is acquired, acquires lock and returns true
    # if lock is currently acquired, returns false
    # never blocks
    #
    # if block is passed in, lock/unlock around the block
    # executing block only if lock is acquired
    def try_lock_record(key2, &block)
      return pg_try_advisory_lock(table_oid, key2, &block)
    end

    # advisory unlock for this model, with key2 as argument
    # on return releases lock
    def unlock_record(key2)
      return pg_advisory_unlock(table_oid, key2)
    end

    # pg_advisory_lock - direct access to postgres pg_advisory_lock function
    # key1: int
    # key2: int
    # if block is passed in, lock/unlock around the block
    def pg_advisory_lock(key1, key2, &block)
      locked = uncached do
        find_by_sql(["select pg_advisory_lock(?, ?) AS result", key1, key2]).first.result
      end
      if block.present?
        begin
          return block.call
        ensure
          pg_advisory_unlock(key1, key2)
        end
      end
      return locked
    end

    # pg_try_advisory_lock - direct access to postgres pg_try_advisory_lock function
    # key1: int
    # key2: int
    #
    # if lock is acquired, acquires lock and returns true
    # if lock is currently acquired, returns false
    # never blocks
    #
    # if block is passed in, lock/unlock around the block
    # executing block only if lock is acquired
    def pg_try_advisory_lock(key1, key2, &block)
      locked = uncached do
        find_by_sql(["select pg_try_advisory_lock(?, ?) AS result", key1, key2]).first.result
      end
      if locked
        if block.present?
          begin
            block.call
          ensure
            pg_advisory_unlock(key1, key2)
          end
        end
      end
      return locked
    end

    # pg_advisory_unlock - direct access to postgres pg_advisory_unlock function
    # key1: int
    # key2: int
    #
    # on return releases lock
    def pg_advisory_unlock(key1, key2)
      unlocked = uncached do
        find_by_sql(["select pg_advisory_unlock(?, ?) AS result", key1, key2]).first.result
      end
      return unlocked
    end
  end
end
