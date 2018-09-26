# :nodoc:
struct Steam::ID::Formatter
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
