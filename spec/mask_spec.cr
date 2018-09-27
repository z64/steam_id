require "./spec_helper"

private def check_mask(mask, is value)
  describe mask do
    it "masks the correct value (#{value})" do
      mask.mask.should eq value
    end
  end
end

describe Steam::ID::Mask do
  it "initializes" do
    mask = Steam::ID::Mask.new(4, 4)
    mask.mask.should eq 0b11110000_u64
    mask.size.should eq 4
    mask.offset.should eq 4
  end

  it "extracts values" do
    mask = Steam::ID::Mask.new(4, 4)
    masked = 0b1010_1111_u64
    mask.extract_from(masked).should eq 0b1010
  end

  it "offsets values" do
    mask = Steam::ID::Mask.new(4, 4)
    mask.offset(1).should eq 0b10000
  end

  check_mask(
    Steam::ID::Mask::LowestBit,
    is: 0b0000000000000000000000000000000000000000000000000000000000000001_u64)

  check_mask(
    Steam::ID::Mask::AccountID,
    is: 0b0000000000000000000000000000000011111111111111111111111111111110_u64)

  check_mask(
    Steam::ID::Mask::Instance,
    is: 0b0000000000001111111111111111111100000000000000000000000000000000_u64)

  check_mask(
    Steam::ID::Mask::AccountType,
    is: 0b0000000011110000000000000000000000000000000000000000000000000000_u64)

  check_mask(
    Steam::ID::Mask::Universe,
    is: 0b1111111100000000000000000000000000000000000000000000000000000000_u64)
end
