# steam_id

A library for parsing and serializing Steam IDs.

- [Library docs](https://z64.github.io/steam_id/)
- [SteamID official documentation](https://developer.valvesoftware.com/wiki/SteamID)

## Background

I wrote this library because:

- Understanding Steam IDs can be confusing
- A lot of libraries implement Steam IDs wrong
- IDs encountered "in the wild" may be missing information, or "wrong"

The important detail to understand is that any observed Steam ID is *not* a
unique identifier in the traditional sense. For an application that observes
Steam IDs from *multiple* sources, it would be unwise to use a Steam ID as a
primary key, for instance.

**A Steam ID is an integer that contains encoded account metadata. Depending
on how and where you observe a Steam ID, some of this metadata may be
wrong or missing, but still refer to the same account.**

## ID Formats

An ID can be represented in three main ways.

1. As a 64 bit integer (`Steam::ID::Format::Community64`). ex: `76561197960287930`

  This is a *lossless* format that contains *all* metadata. This is the format of
  ID that is used when interacting with the Steam API.

2. As a string (`Steam::ID::Format::Default`). ex: `STEAM_1:0:11101`

  This is the standard "textual" format as described by the SteamID docs.

  This is a *lossy* format that is missing account type and account instance.

3. As a string (`Steam::ID::Format::Community32`). ex: `[U:1:22202]`

  This is a special format for forming "short" URLs to Steam community
  pages.

  This is a *lossy* format that is missing account universe and account instance.

It's important to consider what your application needs, and whether the format
you are handling Steam IDs in contains that information. Each format encodes
and *account ID* and is most likely what you want to use to uniquely identify
users, presumably within the same universe.

I've included a fair amount of documentation on `Steam::ID::Format`, as well as
`Steam::ID::Mask`, a low level set of structs for decoding/encoding Steam IDs,
that may help improve your understanding of the format.

## Examples of manipulating IDs

Sometimes you may encounter "wrongly" encoded IDs that are somehow not encoded
in a way that can be used with the Steam API. Here are a few "real world" examples of
manipulating IDs into a usable format.

### Old Source games

Games such as Garry's mod (and other GoldSrc, Orange Box games)  may always encode
 a universe of `STEAM_0`. Attempting to parse this ID, and then to call the API
 with the resulting 64 bit ID, will usually result in an error. You can see why
in the example below.

You can use `Steam::ID::Mask` against the parsed value to programatically construct
a new ID with the correct universe value:

```crystal
id = Steam::ID.new("STEAM_0:0:37170282")
id.universe # => Individual
id.to_u64   # => 74340564_u64 (Can't be sent to the API..)
corrected_id = (1_u64 << Steam::ID::Mask::Universe.offset) | id.to_u64

corrected = Steam::ID.new(corrected_id)
corrected.universe # => Public
corrected.to_u64   # => 72057594112268500_u64 (OK!)
corrected.to_s(Steam::ID::Format::Default) # => STEAM_1:0:37170282
```

### Discord API

Discord's OAuth2 API may return a Steam ID with the instance bit as `0`.
While this is still a valid ID that will work in Steam's HTTP API, it will
not match Steam IDs you may have received from other sources.

Similarly, we can build a corrected ID:

```crystal
id = Steam::ID.new(76561193739638996)
id.instance # => 0
correct_instance = (1_u64 << Steam::ID::Mask::Instance.offset) | id.to_u64

corrected = Steam::ID.new(correct_instance)
corrected.instance # => 1
corrected.to_u64 # => 76561198034606292_u64
```

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  steam_id:
    github: z64/steam_id
```

## Usage

```crystal
require "steam_id"

# Create an ID from a UInt64
id = Steam::ID.new(76561198092541763)
id.account_id   # => 66138017
id.account_type # => Steam::ID::AcountType::Individual
id.universe     # => Steam::ID::Universe::Public
id.to_u64       # => 76561197960287930

# For enum attributes, you can use interrogation style methods:
id.universe.public? # => true

# Parse an ID from an unknown format
Steam::ID.new("STEAM_1:0:11101") # => Steam::ID
Steam::ID.new("foo")             # => raises Steam::ID::Error

# Parse an ID from a known format (better performance)
Steam::ID.new("STEAM_1:0:11101", Steam::ID::Format::Default)
  # => Steam::ID
Steam::ID.new("76561197960287930", Steam::ID::Format::Default)
  # => raises Steam::ID::Error
```

## Contributors

- [Zac Nowicki](https://github.com/z64) - creator, maintainer
