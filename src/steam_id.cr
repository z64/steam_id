# A Steam ID is an encoded 64 bit integer that contains various metadata
# about a Steam account.
#
# A given ID does not uniquely identify an account,
# as encoded IDs may be missing certain pieces of metadata if it was decoded
# from certain formats (see `Steam::ID::Format` for more info).
struct Steam::ID
  VERSION = "0.1.0"

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

  # A `Mask` is used as basic wrapper around `UInt64` for performing
  # binary operations, specifically for composing the binary format
  # of a Steam `ID`. Its namespace includes constants for each component of an
  # `ID` that can be used to decode a `UInt64` with `#extract_from`.
  #
  # ## Masks
  #
  #
  # `LowestBit` - The first bit of the number. It is used only in encoding
  # a 64 bit ID into certain string formats.
  # ```
  # 0b0000000000000000000000000000000000000000000000000000000000000001
  # ```
  #
  # `AccountID` - The canonical ID of the account encoded in the ID
  # ```
  # 0b0000000000000000000000000000000011111111111111111111111111111110
  # ```
  #
  # `Instance` - The instance of the account
  # ```
  # 0b0000000000001111111111111111111100000000000000000000000000000000
  # ```
  #
  # `AccountType` - The type of this account. Abstracted as `ID::AccountType`
  # ```
  # 0b0000000011110000000000000000000000000000000000000000000000000000
  # ```
  #
  # `Universe` - The universe this account belongs to. Abstracted as `ID::Universe`
  # ```
  # 0b1111111100000000000000000000000000000000000000000000000000000000
  # ```
  #
  # ### Example
  #
  # ![example](https://imgur.com/rlvxB34.jpg)
  #
  # (Taken from [SteamID docs](https://developer.valvesoftware.com/wiki/SteamID#Format))
  #
  # ```
  # binary = 0b00000001_0001_00000000000000000001_0000011111100010010111110100001_1
  # #                 A    B                    C                               D E
  # # A: Universe
  # Steam::ID::Mask::Universe.extract_from(binary) # => 1
  # # B: AccountType
  # Steam::ID::Mask::AccountType.extract_from(binary) # => 1
  # # C: Instance
  # Steam::ID::Mask::Instance.extract_from(binary) # => 1
  # # D: AccountID
  # Steam::ID::Mask::AccountID.extract_from(binary) # => 66138017
  # # E: LowestBit
  # Steam::ID::Mask::LowestBit.extract_from(binary) # => 1
  # ```
  struct Mask
    getter size : UInt64

    getter offset : UInt64

    getter mask : UInt64

    def initialize(@size : UInt64, @offset : UInt64 = 0)
      @mask = ((1_u64 << size).to_u64 - 1) << offset
    end

    def self.new(size : UInt64, after : Mask)
      new(size, after.size + after.offset)
    end

    def extract_from(value : UInt64)
      (value & @mask) >> offset
    end

    LowestBit   = Mask.new(1, 0)
    AccountID   = Mask.new(31, LowestBit)
    Instance    = Mask.new(20, AccountID)
    AccountType = Mask.new(4, Instance)
    Universe    = Mask.new(8, AccountType)
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

  # :nodoc:
  struct Formatter
    def initialize(@id : ID, @io : IO)
    end

    def self.format(id : ID, io : IO)
      with new(id, io) yield
    end

    def uint64
      @io << @id.to_u64
    end

    def steam
      @io << "STEAM_"
    end

    def seperator
      @io << ':'
    end

    def bracket
      @io << '['
      yield
      @io << ']'
    end

    def universe
      @io << @id.universe.to_i
    end

    def lowest_bit
      @io << @id.lowest_bit
    end

    def account_id(with_lowest_bit : Bool = false)
      @io << @id.account_id(with_lowest_bit)
    end

    def account_type
      @io << AccountTypeLetter[@id.account_type.to_i]
    end

    def one
      @io << '1'
    end
  end

  # :nodoc:
  struct Parser
    class Error < Exception
    end

    def initialize(string)
      @reader = Char::Reader.new(string)
    end

    def self.parse(string)
      with new(string) yield
    end

    delegate current_char, next_char, has_next?, to: @reader

    def expect(string : String)
      parsed = String.build do |str|
        string.size.times do
          str << current_char
          next_char if has_next?
        end
      end
      string == parsed || raise Error.new("Expected #{string.inspect}, got: #{parsed.inspect}")
    end

    def expect(char : Char)
      char == current_char || raise Error.new("Expected #{char}, got: #{char}")
      next_char
      true
    end

    def consume_int
      value = String.build do |str|
        loop do
          char = current_char
          break unless char.number? && has_next?
          str << char
          next_char
        end
      end
      value.to_u64? || raise Error.new("Invalid UInt64")
    end

    def steam
      expect("STEAM_")
    end

    def seperator
      expect(':')
    end

    def bracket
      expect('[')
      yield
      expect(']')
    end

    def one
      expect('1')
    end

    def account_type
      char = current_char
      next_char
      index = AccountTypeLetter.index(char) || raise Error.new("Unknown account type identifier: #{char}")
      AccountType.new(index)
    end

    def universe
      value = consume_int
      Universe.new(value)
    end
  end

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
        value = (universe.value.to_u64 << Mask::Universe.offset) | value
        seperator
        value = (consume_int << Mask::LowestBit.offset) | value
        seperator
        value = (consume_int << Mask::AccountID.offset) | value
      when Format::Community32
        bracket do
          value = (account_type.value.to_u64 << Mask::AccountType.offset) | value
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

  # The `AccountType` this `ID` represents
  def account_type
    AccountType.new(Mask::AccountType.extract_from(@value))
  end

  # The `Universe` this `ID` belongs to
  def universe
    Universe.new(Mask::Universe.extract_from(@value))
  end
end
