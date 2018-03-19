# General helper methods
module Utils
  # Returns an array of the first of each month in date range
  def monthly_dates(dates)
    dates.collect { |e| beginning_of_month(e) }.uniq!
  end
  
  # Checks if provided date is within date range or dates
  def date_included?(date, dates)
    if dates.is_a? Range
      date.between? dates.first, dates.last
    elsif dates.is_a? Array
      dates.any? { |d| date_included? date, d }
    else
      dates == date
    end
  end
  
  # more performant implemention of Date#beginning_of_month optimized only for Date class
  def beginning_of_month(date)
    Date.new(date.year, date.month)
  end
  
  def get_average(values, options = {})
    round_to = options[:round_to] || 0
    values.present? ? ( values.sum.to_f / values.length ).round(round_to) : 0
  end
  
  # Ensure passed parameter is iterable
  def ensure_iterable(args)
    args.respond_to?(:each) ? args : Array.wrap(args)
  end
  
  # Converts an array of objects to an array of ranges
  def to_ranges(array)
    return if array.any? { |obj| obj.is_a? Range }
    array = array.compact.uniq.sort
    ranges = []
    if !array.empty?
      # Initialize the left and right endpoints of the range
      left, right = array.first, nil
      array.each do |obj|
        # If the right endpoint is set and obj is not equal to right's successor 
        # then we need to create a range.
        if right && obj != right.succ
          ranges << ( left == right ? left : Range.new(left,right) )
          left = obj
        end
        right = obj
      end
      ranges << ( left == right ? left : Range.new(left,right) )
    end
    ranges
  end
  
  # Checks if object is numeric
  def numeric?(obj)
    true if Float(obj) rescue false
  end
  
  # Certain characters are not allowed when naming worksheets in xlsx
  def xlsx_safe_name(name)
    forbidden_characters = ["\\", "/", "*", "[", "]", ":", "?"]
    safe_name = name.dup
    forbidden_characters.each do |c|
      safe_name.gsub!(c,' ')
    end
    safe_name.strip
  end
  
  private
  
    # Transforms a collection of objects to a hash grouped by dates.
    def group_by_date(col)
      col.map { |e| e.date }.zip(col).to_h
    end
end