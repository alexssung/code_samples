require 'rails_helper'

describe Equipment, type: :model do
  context "associations" do
    it { is_expected.to belong_to(:lease) }
    it { is_expected.to have_one(:client).through(:lease) }
    it { is_expected.to have_many(:data_points) }
    it { is_expected.to have_many(:cost_entries) }
    it { is_expected.to have_and_belong_to_many(:wells) }
  end
  
  context "validations" do
    it { is_expected.to validate_length_of(:name).is_at_least(1).is_at_most(30) }
    it { is_expected.to validate_presence_of(:lease_id) }
  end
  
  let(:equipment) { create(:equipment, preferences: nil) }
  let(:equipment_with_specified_attributes) { create(:equipment, input_attributes: ['gauge_feet', 'gauge_inch'], readonly_attributes: ['oil_production'] )}
  let(:oil_tank) { create(:oil_tank, preferences: nil) }
  
  describe "#input_attributes" do
    context "when preferences['input_attributes'] is blank" do
      it "returns its default_attributes" do
        expect(oil_tank.input_attributes).to eq(oil_tank.default_attributes)
      end
    end
    context "when preferences['input_attributes'] is present" do
      it "returns preferences['input_attributes']" do
        expect(equipment_with_specified_attributes.input_attributes).to contain_exactly('gauge_feet', 'gauge_inch')
      end
    end
  end
  
  describe "#readonly_attributes" do
    context "when preferences['readonly_attributes'] is blank" do
      it "returns an empty array" do
        expect(equipment.readonly_attributes).to eq([])
      end
    end
    context "when preferences['readonly_attributes'] is present" do
      it "returns preferences['readonly_attributes']" do
        expect(equipment_with_specified_attributes.readonly_attributes).to contain_exactly('oil_production')
      end
    end
  end
  
  describe "#all_attributes" do
    it "returns an array of its input_attributes and readonly_attributes" do
      expect(equipment_with_specified_attributes.all_attributes).to contain_exactly('oil_production', 'gauge_feet', 'gauge_inch')
    end
  end
  
  describe "#default_attributes" do
    it "returns the stored_attributes (converted to strings) of its data class" do
      expect(oil_tank.default_attributes).to eq(TankData.stored_attributes[:data].map(&:to_s))
    end
  end
  
  describe "#data" do
    context "as the base class Equipment" do
      it "raises NotImplementedError" do
        expect { equipment.data }.to raise_error(NotImplementedError)
      end
    end
    
    context "as a subclass of Equipment" do
      it "returns its collection of data depending on its type" do
        data1 = DataPoint.create(equipment: oil_tank, type: oil_tank.data_type, date: Date.new(2000, 1, 1))
        data2 = DataPoint.create(equipment: oil_tank, type: oil_tank.data_type, date: Date.new(2000, 1, 2))
        expect(oil_tank.data).to contain_exactly(data1, data2)
      end
    end
  end
  
  describe "#data_type" do
    it "returns the class name of its data" do
      expect(oil_tank.data_type).to eq("TankData")
    end
  end
  
  describe "#filter_relevant_data" do
    it "returns a collection of its daily data_points, along with monthly data_points where no daily data exists for the month" do
      data1 = oil_tank.data.daily.create(date: Date.new(2000, 1))
      data2 = oil_tank.data.monthly.create(date: Date.new(2000, 1))
      data3 = oil_tank.data.monthly.create(date: Date.new(2000, 2))
      expect(oil_tank.filter_relevant_data).to contain_exactly(data1, data3)
    end
  end
end