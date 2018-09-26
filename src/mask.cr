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
struct Steam::ID::Mask
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
