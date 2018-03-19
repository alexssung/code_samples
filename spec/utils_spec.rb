require 'rails_helper'

describe Utils do
  let(:test_class) { Class.new { include Utils }.new }
  
  describe "#monthly_dates" do
    it "returns an array of the first of each month of the dates provided" do
      dates = Date.new(2000)..Date.new(2000,3)
      expect(test_class.monthly_dates(dates)).to contain_exactly(
        Date.new(2000,1),
        Date.new(2000,2),
        Date.new(2000,3)
      )
    end
  end
  
  describe "#date_included" do
    date1 = Date.new(2000,1,15)
    date2 = Date.new(2000,2,1)
    date3 = Date.new(2000,2,15)
    
    context "if dates is a range" do
      dates = Date.new(2000,1,1)..Date.new(2000,1,31)
      it "checks if date is within range" do
        expect(test_class.date_included?(date1, dates)).to be true
        expect(test_class.date_included?(date2, dates)).to be false
      end
    end
    
    context "if dates is an array" do
      dates = [Date.new(2000,1,15), Date.new(2000,2,1)..Date.new(2000,2,10), Date.new(2000,3,1)]
      it "checks if date is included in dates" do
        expect(test_class.date_included?(date1, dates)).to be true
        expect(test_class.date_included?(date2, dates)).to be true
        expect(test_class.date_included?(date3, dates)).to be false
      end
    end
    
    context "if dates is a date" do
      dates = Date.new(2000,2,1)
      it "checks if date is equal to dates" do
        expect(test_class.date_included?(date1, dates)).to be false
        expect(test_class.date_included?(date2, dates)).to be true
      end
    end
  end
  
  describe "#beginning_of_month" do
    it "returns the first day of the month of the provided date" do
      expect(test_class.beginning_of_month(Date.new(2000,1,15))).to eq(Date.new(2000,1,1))
    end
  end
  
  describe "#get_average" do
    it "returns the average of provided array of values" do
      values = [1,2,3]
      expect(test_class.get_average(values)).to eq(2)
    end
  end
  
  describe "#ensure_iterable" do
    it "returns an iterable version of the provided object" do
      expect(test_class.ensure_iterable("string")).to eq(["string"])
      expect(test_class.ensure_iterable([1])).to eq([1])
    end
  end

  describe "#to_ranges" do
    it "converts an array of objects to an array of ranges" do
      dates = [
        Date.new(2000,1,1),
        Date.new(2000,1,2),
        Date.new(2000,1,3),
        Date.new(2000,1,5),
        Date.new(2000,1,6),
        Date.new(2000,1,10)
      ]
      expect(test_class.to_ranges(dates)).to contain_exactly(
        Date.new(2000,1,1)..Date.new(2000,1,3),
        Date.new(2000,1,5)..Date.new(2000,1,6),
        Date.new(2000,1,10)
      )
    end
  end
  
  describe "#numeric?" do
    it "returns true if provided object is numeric" do
      expect(test_class.numeric?(123)).to be true
      expect(test_class.numeric?("321")).to be true
    end
    
    it "returns false if provided object is not numeric" do
      expect(test_class.numeric?("text")).to be false
    end
  end
  
  describe "#xlsx_safe_name" do
    it "returns a version of the provided string replacing characters (that are forbidden in xlsx worksheet naming) with empty spaces" do
      name = "[test:name]?"
      expect(test_class.xlsx_safe_name(name)).to eq("test name")
    end
  end
end