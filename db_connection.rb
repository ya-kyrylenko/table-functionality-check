require './convert_helper.rb'
class DbConnection
  include ConvertHelper
  attr_reader :dbname, :user, :password

  def initialize(args = {})
    @dbname =   args[:dbname]
    @user =     args[:user]
    @password = args[:password]
  end

  def create_table_and_fill_data_in_db(data)
    fill_data_in_db(data) { |con| create_table(con) }
  end

  def fill_data_in_db(data)
    connect_to_db do |con|
      yield(con) if block_given?

      data.each do |item|
        con.exec "INSERT INTO Items VALUES('%s', %s, %s)" %
          [ "#{item[:name]}", item[:count], item[:price] ]      
      end
    end
  end

  def get_data_from_db
    rs = nil
    connect_to_db do |con|
      rs = con.exec "SELECT * FROM Items"
      convert_pg_result(rs)
    end
  ensure
    rs.clear if rs
  end

  private
  ##############################################################################

  def connect_to_db
    con = PG.connect :dbname => dbname, :user => user, :password  => password
    yield(con)

  rescue PG::Error => e
    puts e.message 
  ensure
    con.close if con
  end

  def remove_table_if_exists(con)
    con.exec "DROP TABLE IF EXISTS Items"
  end

  def create_table(connection)
    remove_table_if_exists(connection)
    connection.exec "CREATE TABLE Items(Name VARCHAR(30), Count INT, Price INT)"
  end

  def convert_pg_result(pg_result)
    pg_result.to_a.map { |hash| convert_to_desired_format(hash) }
  end

  def convert_to_desired_format(hash)
    Hash[hash.map { |k, v| [k.to_sym, convert_number_string(v)] }]
  end
end
