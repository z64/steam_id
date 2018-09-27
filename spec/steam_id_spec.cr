require "./spec_helper"

private def it_formats(id, into string, with format)
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

  it "instance=" do
    id = Steam::ID.new(76561193739638996)
    id.instance.should eq 0
    id.instance = 1
    id.instance.should eq 1
  end

  it "account_type=" do
    id = Steam::ID.new(76561193739638996)
    id.account_type.should eq Steam::ID::AccountType::Individual
    id.account_type = :anon_user
    id.account_type.should eq Steam::ID::AccountType::AnonUser
  end

  it "sets universe" do
    id = Steam::ID.new(76561193739638996)
    id.universe.should eq Steam::ID::Universe::Public
    id.universe = :beta
    id.universe.should eq Steam::ID::Universe::Beta
  end
end
