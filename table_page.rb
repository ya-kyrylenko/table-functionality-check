require './convert_helper.rb'
class TablePage
  include Capybara::DSL
  include ConvertHelper

  WHAT_BUY = 'Что купить'
  TABLE_PATH = "//table[contains(.,'#{WHAT_BUY}')]/tbody/tr"

  Capybara.register_driver :selenium do |app|
    Capybara::Selenium::Driver.new(app, :browser => :chrome)
  end
  Capybara.current_driver = :selenium

  def visit_page
    visit 'http://tereshkova.test.kavichki.com/'
  end

  def scrape_table_data
    table_rows.map { |row| scrape_row_data(row) }
  end

  def fill_in_items(items)
    find(:xpath, "//a[@id='open']").click
    items.each { |item| fill_in_table(item) }
  end

  def remove_item(item)
    find_row_with_item(item).click_link 'Удалить'
  end

  def sort_by_key(key)
    title = titles_hash[key]
    find(:xpath, "//th[.='#{title}']").click
  end

  private
  ##############################################################################

  def titles_hash
    { name: WHAT_BUY, count: 'Количество', price: 'стоимсть, кр' }
  end

  def table_rows
    all(:xpath, TABLE_PATH)
  end

  def scrape_row_data(row)
    item = {}
    titles_hash.each { |key, value| item[key] = scrape_info(row, value) }
    item
  end

  def fill_in_table(item)
    item.each { |key, value| fill_in key, with: value }
    click_on 'add'
  end

  def scrape_info(row, title)
    row_text = row.find(:xpath, td_path(title)).text
    convert_number_string(row_text)
  end

  def td_path(title)
    "./td[count(//th[contains(text(), '#{title}')]/preceding-sibling::th)+1]"
  end

  def find_row_with_item(item)
    table_rows.each do |row|
      return row if scrape_row_data(row) == item
    end
  end
end
