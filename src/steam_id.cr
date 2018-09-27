# A Steam ID is an encoded 64 bit integer that contains various metadata
# about a Steam account.
#
# A given ID does not uniquely identify an account,
# as encoded IDs may be missing certain pieces of metadata if it was decoded
# from certain formats (see `Steam::ID::Format` for more info).
struct Steam::ID
  VERSION = "0.2.0"

  # Exception that is raised when parsing an `ID` fails
  class Error < Exception
  end

  # Universe identities a Steam ID can belong to
  enum Universe
    Individual = 0
    Public     = 1
    Beta       = 2
    Internal   = 3
    Dev        = 4
    RC         = 5

    # :nodoc:
    def self.new(int : UInt64)
      new(int.to_i32)
    end
  end

  # Types of accounts a Steam ID can belong to
  enum AccountType
    Invalid        =  0
    Individual     =  1
    Multiseat      =  2
    GameServer     =  3
    AnonGameServer =  4
    Pending        =  5
    ContentServer  =  6
    Clan           =  7
    Chat           =  8
    P2PSuperSeeder =  9
    AnonUser       = 10

    # :nodoc:
    def self.new(int : UInt64)
      new(int.to_i32)
    end
  end

  # An enum for selecting the various formats a Steam ID can be parsed or
  # serialized from.
  #
  # NOTE: Every format except for `Community64` are "lossy" formats and
  # does not encode all possible information that can be stored in a Steam ID.
  #
  # **IDs that are parsed or serialized with these formats are missing the
  # following information:**
  # - `Default` does not encode `AccountType` or instance
  # - `Community32` does not encode `Universe` or instance
  enum Format
    # The standard textual representation of a Steam ID. ex: `"STEAM_1:0:11101"`
    Default

    # A string format for short "community" URLs. ex: `"[U:1:22202]"`
    Community32

    # A 64 bit integer, represented as a string. ex: `"76561197960287930"`
    Community64
  end

  # :nodoc:
  AccountTypeLetter = {
    'I', # Invalid
    'U', # Individual
    'M', # Multiseat
    'G', # GameServer
    'A', # AnonGameServer
    'P', # Pending
    'C', # ContentServer
    'g', # Clan
    'T', # Chat
    nil, # P2PSuperSeeder
    'a', # AnonUser
  }

  # Create a Steam ID from a 64 bit value
  def initialize(@value : UInt64)
  end

  # Attempts to parse the given string as an ID of any of `Format`. Raises
  # `Error` if no format parses well.
  def self.new(string : String)
    Format.each do |format|
      begin
        return new(string, format)
      rescue Parser::Error
        # Try next format
      end
    end
    raise Error.new("Unknown Steam ID format: #{string}")
  end

  # Parses a string as the given `Format`. Raises `Error` if parsing fails.
  def self.new(string : String, format : Format)
    value = 0_u64
    Parser.parse(string) do
      case format
      when Format::Default
        steam
        value = Mask::Universe.offset(consume_int) | value
        seperator
        value = Mask::LowestBit.offset(consume_int) | value
        seperator
        value = Mask::AccountID.offset(consume_int) | value
      when Format::Community32
        bracket do
          value = Mask::AccountType.offset(account_type.value.to_u64)
          seperator
          one
          seperator
          value = consume_int | value
        end
      when Format::Community64
        value = consume_int
      end
    end
    new(value)
  end

  # Serializes this `ID` as the given `Format`
  def to_s(format : Format = Format::Community64)
    String.build do |io|
      to_s(io, format)
    end
  end

  # Serializes this `ID` as the given `Format`, writing to the given IO
  def to_s(io : IO, format : Format = Format::Community64)
    Formatter.format(self, io) do
      case format
      when Format::Default
        steam
        universe
        seperator
        lowest_bit
        seperator
        account_id
      when Format::Community32
        bracket do
          account_type
          seperator
          one
          seperator
          account_id(with_lowest_bit: true)
        end
      when Format::Community64
        uint64
      end
    end
  end

  def to_u64
    @value
  end

  # The lowest bit value of this `ID`. Used for encoding an `ID` into a
  # string of a given `Format`
  def lowest_bit
    Mask::LowestBit.extract_from(@value)
  end

  # The account ID this `ID` represents
  def account_id(with_lowest_bit : Bool = false)
    value = Mask::AccountID.extract_from(@value)
    if with_lowest_bit
      (value << 1) + lowest_bit
    else
      value
    end
  end

  # The instance of this account
  def instance
    Mask::Instance.extract_from(@value)
  end

  # Re-encodes this ID with an updated instance value
  def instance=(new_value : UInt64)
    @value = calculate_id(account_id(true), new_value, account_type, universe)
  end

  # The `AccountType` this `ID` represents
  def account_type
    AccountType.new(Mask::AccountType.extract_from(@value))
  end

  # Re-encodes this ID with an updated `AccountType`
  def account_type=(new_value : AccountType)
    @value = calculate_id(account_id(true), instance, new_value, universe)
  end

  # The `Universe` this `ID` belongs to
  def universe
    Universe.new(Mask::Universe.extract_from(@value))
  end

  # Re-encodes this ID with an updated `Universe`
  def universe=(new_value : Universe)
    @value = calculate_id(account_id(true), instance, account_type, new_value)
  end

  # Encodes a UInt64 with the provided data
  private def calculate_id(account_id : UInt64, instance : UInt64,
                           account_type : AccountType, universe : Universe)
    value = account_id
    value = Mask::Instance.offset(instance.to_u64) | value
    value = Mask::AccountType.offset(account_type.to_u64) | value
    value = Mask::Universe.offset(universe.to_u64) | value
    value
  end
end

require "./mask"
require "./parser"
require "./formatter"
