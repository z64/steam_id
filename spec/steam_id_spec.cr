require "./spec_helper"

def check_mask(mask, is value)
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

def it_formats(id, into string, with format)
  it "formats #{id} into #{string} with #{format}" do
    id.to_s(format).should eq string
  end
end

describe Steam::ID do
  it "#initialize with steam64" do
    id = Steam::ID.new(76561198092541763)
    id.to_u64.should eq 76561198092541763
    id.lowest_bit.should eq 1
    id.account_id.should eq 66138017
    id.instance.should eq 1
    id.account_type.should eq Steam::ID::AccountType::Individual
    id.universe.should eq Steam::ID::Universe::Public
  end

  it "can compare account id with different instance" do
    id_a = Steam::ID.new(76561193739638996)
    id_b = Steam::ID.new(76561198034606292)
    id_a.account_id.should eq id_b.account_id
  end

  describe "#to_s" do
    id = Steam::ID.new(76561197960287930)

    it_formats(
      id,
      into: "STEAM_1:0:11101",
      with: Steam::ID::Format::Default)

    it_formats(
      id,
      into: "76561197960287930",
      with: Steam::ID::Format::Community64)

    it_formats(
      id,
      into: "[U:1:22202]",
      with: Steam::ID::Format::Community32)
  end
end
