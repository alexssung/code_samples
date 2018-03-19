require 'rails_helper'

describe TankData, type: :model do
  context "validations" do
    it { is_expected.to validate_numericality_of(:oil_production).is_greater_than_or_equal_to(-999_999).is_less_than(999_999).allow_nil }
    it { is_expected.to validate_numericality_of(:gauge_feet).is_greater_than_or_equal_to(0).is_less_than(999).allow_nil }
    it { is_expected.to validate_numericality_of(:gauge_inch).is_greater_than_or_equal_to(0).is_less_than(999).allow_nil }
    it { is_expected.to validate_length_of(:comments).is_at_most(200) }
  end
  
  let(:oil_tank) { create(:oil_tank, conversion_factor: 1.67 ) }
  
  describe "#cumulative_production" do
    it "returns its tank's cumulative production up to its date" do
      data1 = oil_tank.data.create(date: Date.new(2000,1,1), oil_production: 1)
      data2 = oil_tank.data.create(date: Date.new(2000,1,2), oil_production: 1)
      data3 = oil_tank.data.create(date: Date.new(2000,1,3), oil_production: 1)
      expect(data2.cumulative_production).to eq(2)
    end
  end
  
  describe "#tank_total" do
    it "returns the total bbl based on its gauge measurements (gauge total * tank's conversion factor)" do
      data = oil_tank.data.create(date: Date.new, gauge_feet: 1, gauge_inch: 6)
      expect(data.tank_total).to eq(30.06)
    end
  end
  
  describe "#run_total" do
    it "returns gross bbl of the associated run ticket, if any" do
      data = oil_tank.data.create(date: Date.new(2000, 1, 1))
      oil_tank.run_tickets.create(date: Date.new(2000, 1, 1), top_gauge_inch: 10, final_gauge_inch: 6)
      expect(data.run_total).to eq(6.68)
    end
  end
  
  describe "#has_gauge_measurements?" do
    it "returns true if data contains gauge measurements" do
      data = oil_tank.data.create(date: Date.new, gauge_inch: 6)
      expect(data.has_gauge_measurements?).to be true
    end
    
    it "returns false if data does not contain gauge measurements" do
      data = oil_tank.data.create(date: Date.new, comments: "no gauge measurements")
      expect(data.has_gauge_measurements?).to be false
    end
  end
  
  context "gauge setting logic" do
    before do
      @data1 = oil_tank.data.create date: Date.new(2000, 1, 1), gauge_inch: 6
      @data2 = oil_tank.data.create date: Date.new(2000, 1, 3), gauge_inch: 8
      @data3 = oil_tank.data.create date: Date.new(2000, 1, 4), gauge_inch: 10
      @data_outside_range = oil_tank.data.create date: Date.new(2000, 1, 31), gauge_inch: 12
      @data_without_gauge_measurements = oil_tank.data.create date: Date.new(2000), data: {}
    end
    
    it "sets itself and its next gauged data's oil production after save if data contains gauge measurements" do
      expect(@data1).to receive(:set_production_from_gauge)
      expect(@data1).to receive(:set_next_production_from_gauge)
      expect(@data_without_gauge_measurements).not_to receive(:set_production_from_gauge)
      @data1.save
      @data_without_gauge_measurements.save
    end
    
    it "sets the next tank data's oil production after destroy" do    
      expect(@data1).to receive(:set_next_production_from_gauge)
      @data1.destroy
    end
    
    describe "#set_production_from_gauge" do
      it "sets oil production based on the gauge measurements of the previous gauged data and itself" do
        @data3.set_production_from_gauge
        expect(@data3.oil_production).to eq(3.34)
      end
      it "creates new data with averaged oil production when there are days between the previous gauged data and itself" do
        @data2.set_production_from_gauge
        @data2 = oil_tank.data.where(date: Date.new(2000, 1, 3)).take
        created_data = oil_tank.data.where(date: Date.new(2000, 1, 2)).take
        expect(created_data.oil_production).to eq(1.67)
        expect(@data2.oil_production).to eq(1.67)
      end
    end
    
    describe "#set_next_production_from_gauge" do
      it "sets the next tank data's oil production based on its gauge measurements" do
        @data1.set_next_production_from_gauge
        expect(@data1.next_gauged_data.oil_production).to eq(1.67)
      end
    end
    
    describe "#prev_gauged_data" do
      it "finds the previous data with gauge measurements (within 14 days)" do
        expect(@data2.prev_gauged_data).to eq(@data1)
        expect(@data_outside_range.prev_gauged_data).to be nil
      end
    end
    
    describe "#next_gauged_data" do
      it "finds the next data with gauge measurements (within 14 days)" do
        expect(@data1.next_gauged_data).to eq(@data2)
        expect(@data3.next_gauged_data).to be nil
      end
    end
  end
end