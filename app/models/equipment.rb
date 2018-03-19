# STI model for equipment, e.g. tanks, meters, etc
class Equipment < ApplicationRecord
  audited
  has_ancestry
  default_scope { order(created_at: :asc) }

  include PgSearch
  multisearchable :against => :name
  
  belongs_to :lease
  has_one :client, through: :lease
  has_many :data_points
  has_many :cost_entries, as: :costable
  has_and_belongs_to_many :wells
  
  validates :name, length: { minimum: 1, maximum: 30 }
  validates :lease_id, presence: true
  
  store_accessor :preferences, :input_attributes, :readonly_attributes
  
  # attributes used for recording input
  def input_attributes
    super || default_attributes
  end
  
  # readonly attributes
  def readonly_attributes
    super || []
  end
  
  # all attributes
  def all_attributes
    input_attributes.to_a + readonly_attributes.to_a
  end
  
  # stored_attributes of equipment's data model
  def default_attributes
    data.klass.stored_attributes[:data].map(&:to_s)
  end
  
  def data
    raise NotImplementedError, "Subclasses must alias_attribute `data`"
  end
  
  def data_type
    data.klass.name
  end
  
  # Returns relevant daily and monthly data
  # Prioritize daily data, therefore exclude monthly data where daily data exists in month
  def filter_relevant_data(_data = data)
    daily_data = _data.daily
    monthly_data = _data.monthly
    relevant_monthly_data = monthly_data.where.not(date: daily_data.collect{ |d| d.date.beginning_of_month }.uniq )
    daily_data + relevant_monthly_data
  end
end