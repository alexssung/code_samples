require 'rails_helper'

describe Tank, type: :model do
  context "associations" do
    it { is_expected.to have_many(:tank_data) }
    it { is_expected.to have_many(:run_tickets) }
  end
  
  context "validations" do
    it { is_expected.to validate_numericality_of(:conversion_factor).is_greater_than_or_equal_to(0).is_less_than(10) }
  end
  
  let(:oil_tank) { create(:oil_tank) }
  
  describe "#run_ticket" do
    it "returns its run ticket, if any, on the specified date" do
      run_ticket = create(:run_ticket, date: Date.new(2000,1,15), tank: oil_tank)
      expect(oil_tank.run_ticket(Date.new(2000,1,15))).to eq(run_ticket)
    end
  end
  
  describe "#cumulative_production" do
    it "returns its cumulative production up to the specified date" do
      oil_tank.data.create(date: Date.new(2000,1,1), oil_production: 1)
      oil_tank.data.create(date: Date.new(2000,1,2), oil_production: 1)
      oil_tank.data.create(date: Date.new(2000,1,3), oil_production: 1)
      expect(oil_tank.cumulative_production(Date.new(2000,1,2))).to eq(2)
    end
  end
  
  describe "#connected_tanks" do
    it "returns all tanks associated to the same wells it is associated with" do
      well1 = create(:well)
      well2 = create(:well)
      well3 = create(:well)
      tank1 = create(:oil_tank, wells: [well1, well2] )
      tank2 = create(:oil_tank, wells: [well1, well3] )
      tank3 = create(:oil_tank, wells: [well2] )
      tank4 = create(:oil_tank, wells: [well3] )
      
      expect(tank1.connected_tanks).to contain_exactly(tank1, tank2, tank3)
    end
  end
end