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

describe Steam::ID::Parser do
  it "expects a string or char" do
    Steam::ID::Parser.parse("foobarZbaz") do
      expect("foo").should be_true
      expect("bar").should be_true
      expect('Z').should be_true
      expect_raises(Steam::ID::Parser::Error, %(Expected "foo", got: "baz")) do
        expect("foo")
      end
    end
  end

  it "expects a bracketed string" do
    Steam::ID::Parser.parse("[foo]") do
      bracket do
        expect("foo")
      end
    end
  end

  it "consumes an integer" do
    Steam::ID::Parser.parse("foo123barbaz") do
      expect("foo")
      consume_int.should eq 123
      expect("bar")

      expect_raises(Steam::ID::Parser::Error, "Invalid UInt64") do
        consume_int
      end
    end
  end

  it "parses account type" do
    Steam::ID::Parser.parse("Uz") do
      account_type.should eq Steam::ID::AccountType::Individual
      expect_raises(Steam::ID::Parser::Error, "Unknown account type identifier: z") do
        account_type
      end
    end
  end

  it "parses steam ID" do
    Steam::ID::Parser.parse("STEAM_1:0:11101") do
      steam
      consume_int.should eq 1
      seperator
      consume_int.should eq 0
      seperator
      consume_int.should eq 11101
    end
  end

  it "parses community 32 ID" do
    Steam::ID::Parser.parse("[U:1:22202]") do
      bracket do
        account_type.should eq Steam::ID::AccountType::Individual
        seperator
        consume_int.should eq 1
        seperator
        consume_int.should eq 22202
      end
    end
  end
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

  it "parses STEAM_1:0:11101" do
    id = Steam::ID.new("STEAM_1:0:11101", Steam::ID::Format::Default)
    id.universe.should eq Steam::ID::Universe::Public
    id.lowest_bit.should eq 0
    id.account_id.should eq 11101
  end

  it "parses 76561197960287930" do
    id = Steam::ID.new("76561197960287930", Steam::ID::Format::Community64)
    id.should eq Steam::ID.new(76561197960287930)
  end

  it "parses [U:1:22202]" do
    id = Steam::ID.new("[U:1:22202]", Steam::ID::Format::Community32)
    id.account_type.should eq Steam::ID::AccountType::Individual
    id.lowest_bit.should eq 0
    id.account_id.should eq 11101
  end

  it "parses any format" do
    {"STEAM_1:0:11101", "76561197960287930", "[U:1:22202]"}.each do |input|
      Steam::ID.new(input)
    end

    expect_raises(Steam::ID::Error, "Unknown Steam ID format: foo") do
      Steam::ID.new("foo")
    end
  end
end
