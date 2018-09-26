# :nodoc:
struct Steam::ID::Parser
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
