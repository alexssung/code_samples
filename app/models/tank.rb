class Tank < Equipment
  has_many :tank_data, foreign_key: :equipment_id
  has_many :run_tickets, foreign_key: :tank_id
  
  store_accessor :preferences, :conversion_factor
  validates :conversion_factor, numericality: { greater_than_or_equal_to: 0, less_than: 10 }
  
  alias_attribute :data, :tank_data
  
  DEFAULT_CONVERSION_FACTOR = 1.67
  
  def conversion_factor
    super || DEFAULT_CONVERSION_FACTOR
  end
  
  def run_ticket(date)
    run_tickets.where(date: date).take
  end
  
  # Total production up to date
  def cumulative_production(date)
    cumulative_data = filter_relevant_data data.where("date <= ?", date)
    cumulative = cumulative_data.reduce(0) { |sum, data| sum + data.oil_production.to_f }
    cumulative.round(2)
  end
  
  # Returns all tanks connected to the same wells
  def connected_tanks
    Tank.includes(:wells).where(wells: { id: wells.ids } ).uniq
  end
end
