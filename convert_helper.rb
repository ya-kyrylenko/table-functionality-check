module ConvertHelper
  def convert_number_string(string)
    string.match?(/\A[\d]+\z/) ? string.to_i : string
  end
end
