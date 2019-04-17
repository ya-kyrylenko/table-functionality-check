require 'byebug'
require 'capybara/dsl'
require 'pg'
require 'capybara/rspec'
require './table_page.rb'
require './db_connection.rb'

describe 'Testing table functionality' do
  subject(:table_page) { TablePage.new }
  let(:table_path) { TablePage::TABLE_PATH }
  let(:existing_items) { table_page.scrape_table_data }
  before(:each) { table_page.visit_page }

  context 'when visiting table page' do
    it { expect(table_page).to have_xpath table_path }
  end

  context 'when we add new items to the table' do
    let(:db_connection) { DbConnection.new dbname: 'test_task_db',
      user: 'test_user', password: 'test_password' }
    let(:new_items) do 
      [ { name: 'Гидродинамическая лопатка', count: '3', price: '12' },
        { name: 'Обычная лопатка', count: '1', price: '5' } ]
    end

    it 'fills the table correctly' do
      db_connection.create_table_and_fill_data_in_db(existing_items)
      table_page.fill_in_items(new_items)
      db_connection.fill_data_in_db(new_items)
      expect(table_page.scrape_table_data).to eq db_connection.get_data_from_db
    end
  end

  context 'when we try remove existing item' do
    it 'removes it correctly' do
      removed_item = existing_items.first
      table_page.remove_item(removed_item)
      new_table_data = table_page.scrape_table_data
      expect(new_table_data.count).to eq(existing_items.count - 1)
      expect(new_table_data).not_to include(removed_item)
    end
  end

  context 'when we try to sort data using table\'s titles' do
    it 'sort data correctly' do
      [:name, :count, :price].each do |key|
        table_page.sort_by_key(key)
        existing_items.sort_by! { |hsh| hsh[key] }
        sorted_table_data = table_page.scrape_table_data
        sorted_table_data.each_with_index do |data_hash, i|
          expect(data_hash).to eq(existing_items[i])
        end
      end
    end
  end
end
