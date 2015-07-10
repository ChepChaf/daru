require 'spec_helper'
include Daru

describe DateOffset, focus: true do
  context "#initialize, #+" do
    it "creates a seconds offset" do
      offset = DateOffset.new(secs: 5)
      expect(offset + DateTime.new(2012,3,4,23,4,00)).to eq(
        DateTime.new(2012,3,4,23,4,05))
    end

    it "creates a minutes offset"  do
      offset = DateOffset.new(mins: 2)
      expect(offset + DateTime.new(2013,4,5,12,45,44)).to eq(
        DateTime.new(2013,4,5,12,47,44))
    end

    it "creates an hours offset" do
      offset = DateOffset.new(hours: 3)
      expect(offset + DateTime.new(2024,3,2)).to eq(
        DateTime.new(2024,3,2,03,0,0))
    end

    it "creates a days offset" do
      offset = DateOffset.new(days: 12)
      expect(offset + DateTime.new(2012,5,4)).to eq(
        DateTime.new(2012,5,16))
    end

    it "creates a weeks offset" do
      offset = DateOffset.new(weeks: 2)
      expect(offset + DateTime.new(2012,3,1)).to eq(
        DateTime.new(2012,3,15))
    end

    it "creates a months offset" do
      offset = DateOffset.new(months: 1)
      expect(offset + DateTime.new(2012,3,1)).to eq(
        DateTime.new(2012,4,1))
    end

    it "supports 'n' option to apply same offset multiple times" do
      offset = DateOffset.new(days: 3, n: 4)
      expect(offset + DateTime.new(2012,3,1)).to eq(
        DateTime.new(2012,3,13))
    end
  end
end

include Daru::Offsets
describe Offsets do
  describe Second do
    context "#initialize" do
      it "creates a seconds offset" do
        offset = Offsets::Second.new(5)
        expect(offset + DateTime.new(2012,3,4,23,4,00)).to eq(
          DateTime.new(2012,3,4,23,4,05))
      end
    end

    context "#on_offset?" do
    end
  end

  describe Minute do
    context "#initialize" do
      it "creates a minutes offset" do
        offset = Offsets::Minute.new(2)
        expect(offset + DateTime.new(2013,4,5,12,45,44)).to eq(
          DateTime.new(2013,4,5,12,47,44))
      end
    end
  end

  describe Hour do
    context "#initialize" do
      it "creates an hours offset" do
        offset = Offsets::Hour.new(3)
        expect(offset + DateTime.new(2024,3,2)).to eq(
          DateTime.new(2024,3,2,03,0,0))
      end
    end
  end

  describe Day do
    context "#initialize" do
      it "creates a days offset" do
        offset = Offsets::Day.new(12)
        expect(offset + DateTime.new(2012,5,4)).to eq(
          DateTime.new(2012,5,16))
      end
    end
  end

  describe Week do
    DAYS = {
      sunday:    DateTime.new(2015,7,12),
      monday:    DateTime.new(2015,7,13),
      tuesday:   DateTime.new(2015,7,14),
      wednesday: DateTime.new(2015,7,15),
      thursday:  DateTime.new(2015,7,16),
      friday:    DateTime.new(2015,7,17),
      saturday:  DateTime.new(2015,7,11)
    }

    DAYS.each.with_index do |day_date, i|
      offset = Offsets::Week.new(weekday: i)

      context "#initialize" do
        date = DateTime.new(2015,7,10)

        it "creates anchored Week offset for #{day_date[0]}" do
          expect(offset + date).to eq(day_date[1])
        end
      end

      context "#on_offset?" do
        it "checks if given DateTime is on the offset itself? (#{day_date[0]})" do
          expect(offset.on_offset?(DAYS[day_date[1]])).to eq(true)
        end
      end
    end
  end

  describe Month do
    context "#initialize" do
      it "creates a month offset" do
        offset = Offsets::Month.new(3)
        expect(offset + DateTime.new(2012,2,29)).to eq(
          DateTime.new(2012,5,29))
      end
    end
  end

  describe MonthBegin do
    context "#initialize" do
      it "creates a month begin offset" do
        offset = Offsets::MonthBegin.new
        expect(offset + DateTime.new(2012,3,25)).to eq(
          DateTime.new(2012,4,1))
      end
    end

    context "#on_offset?" do
    end
  end

  describe MonthEnd do
    context "#initialize" do
      it "creates a month end offset" do
        offset = Offsets::MonthEnd.new
        expect(offset + DateTime.new(2012,3,25)).to eq(
          DateTime.new(2012,3,31))
      end
    end

    context "#+" do
      it "increases on offset date to end of next month" do
        offset = Offsets::MonthEnd.new
        expect(offset + DateTime.new(2012,2,29)).to eq(
          DateTime.new(2012,3,31))
      end
    end
  end

  describe YearBegin do
    context "#initialize" do
      it "creates a year begin offset" do
        offset = Offsets::YearBegin.new
        expect(offset + DateTime.new(2012,3,25)).to eq(
          DateTime.new(2013,1,1))
      end
    end

    context "#on_offset?" do
    end
  end

  describe YearEnd do
    context "#initialize" do
      it "creates a year end offset" do
        offset = Offsets::YearEnd.new
        expect(offset + DateTime.new(2012,2,29)).to eq(
          DateTime.new(2012,12,31))
      end
    end

    context "#+" do
    end

    context "#on_offset?" do
    end
  end
end
