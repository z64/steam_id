struct Steam::ID
  VERSION = "0.1.0"

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

  # :nodoc:
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

  enum Format
    Default
    Community32
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
  # `Error` if no format prases well.
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

  def lowest_bit
    Mask::LowestBit.extract_from(@value)
  end

  def account_id(with_lowest_bit : Bool = false)
    value = Mask::AccountID.extract_from(@value)
    if with_lowest_bit
      (value << 1) + lowest_bit
    else
      value
    end
  end

  def instance
    Mask::Instance.extract_from(@value)
  end

  def account_type
    AccountType.new(Mask::AccountType.extract_from(@value))
  end

  def universe
    Universe.new(Mask::Universe.extract_from(@value))
  end
end
