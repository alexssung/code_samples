class TankData < DataPoint
  store_accessor :data, :oil_production, :gauge_feet, :gauge_inch, :comments
  
  validates :oil_production, numericality: { greater_than_or_equal_to: -999_999, less_than: 999_999, allow_blank: true }
  validates :gauge_feet, numericality: { greater_than_or_equal_to: 0, less_than: 999, allow_blank: true }
  validates :gauge_inch, numericality: { greater_than_or_equal_to: 0, less_than: 999, allow_blank: true }
  validates :comments, length: { maximum: 200 }
  
  after_save :set_production_from_gauge, :set_next_production_from_gauge, if: :has_gauge_measurements?
  after_destroy :set_next_production_from_gauge, if: :has_gauge_measurements?
  
  alias_attribute :tank, :equipment
  
  GAUGE_ATTRIBUTES = ['gauge_feet', 'gauge_inch']
  
  scope :gauged, -> { daily.where("data->>'gauge_feet' IS NOT NULL OR data->>'gauge_inch' IS NOT NULL") }
  
  def cumulative_production
    tank.cumulative_production(date)
  end
  
  # Total bbl in tank = gauge total * tank's conversion factor
  def tank_total
    return nil if gauge_total.nil?
    (gauge_total * tank.conversion_factor).round(2)
  end
  
  # Total gauge in inches
  def gauge_total
    return nil if gauge_feet.nil? && gauge_inch.nil?
    (gauge_feet.to_f * 12 + gauge_inch.to_f).round(2)
  end
  
  # Gross BBL of run ticket on the date of this data
  def run_total
    run_ticket = tank.run_tickets.find_by(date: date)
    run_ticket ? run_ticket.gross_bbl : 0
  end
  
  def has_gauge_measurements?
    GAUGE_ATTRIBUTES.any? { |a| data && data[a].present? }
  end
  
  # Calculates and sets daily production from gauge measurements
  def set_production_from_gauge
    prev_data = prev_gauged_data
    prev_total = prev_data&.tank_total
    current_total = tank_total
    if prev_total && current_total
      production = ( current_total.to_f + run_total.to_f - prev_total.to_f ).round(2)
      days_diff = date - prev_data.date  
      if days_diff == 1
        new_data = data.merge("oil_production" => production)
        update_column(:data, new_data)
      elsif days_diff > 1
        # If there are days between prev measured data and self, set production for all days in between
        date_range = prev_data.date.next_day..date
        date_range.each do |day|
          record = tank.data.daily.find_or_create_by(date: day)
          old_data = record.data || {}
          new_data = old_data.merge("oil_production" => ( production / days_diff ).round(2))
          record.update_column(:data, new_data)
        end
      end
    end
    return
  end
  
  def set_next_production_from_gauge
    next_gauged_data&.set_production_from_gauge
  end
  
  # find previous data with gauge measurements (within 14 days)
  def prev_gauged_data
    tank.data.gauged.where(date: date.prev_day(14)...date).order("date desc").take
  end
  
  # find next data with gauge measurements (within 14 days)
  def next_gauged_data
    tank.data.gauged.where(date: date.next_day..date.next_day(14)).order("date asc").take
  end
end
