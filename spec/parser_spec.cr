require "./spec_helper"

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
