require 'yaml'

# pg?
case ENV['BUNDLE_GEMFILE']
when /pg/
  if ENV['TRAVIS']
    ActiveRecord::Base.establish_connection(:adapter => 'postgresql', :database => 'minidusen_test', :username => 'postgres')
  else
    ActiveRecord::Base.establish_connection(:adapter => 'postgresql', :database => 'minidusen_test')
  end
# mysql2?
when /mysql2/
  config = { :adapter => 'mysql2', :encoding => 'utf8', :database => 'minidusen_test' }
  custom_config_path = File.join(File.dirname(__FILE__), 'database.yml')
  if File.exists?(custom_config_path)
    custom_config = YAML.load_file(custom_config_path)
    config.merge!(custom_config)
  end
  ActiveRecord::Base.establish_connection(config)
when /sqlite3/
  ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => ':memory:')
else
  raise "Unknown database type in Gemfile suffix: #{ENV['BUNDLE_GEMFILE']}"
end


connection = ::ActiveRecord::Base.connection
connection.tables.each do |table|
  connection.drop_table table
end

ActiveRecord::Migration.class_eval do

  create_table :users do |t|
    t.string :name
    t.string :email
    t.string :city
  end

  create_table :recipes do |t|
    t.string :name
    t.integer :category_id
  end

  create_table :recipe_ingredients do |t|
    t.string :name
    t.integer :recipe_id
  end

  create_table :recipe_categories do |t|
    t.string :name
  end

end