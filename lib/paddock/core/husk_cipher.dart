/// Position-keyed FNV-1a keystream obfuscation.
///
/// Sensitive strings (config endpoint, AppsFlyer key, Firebase number, legal
/// URLs, UA fragments) never live in the binary as plaintext — they are stored
/// as byte arrays and revealed at runtime by [revealHusk].
///
/// The keystream is a 32-bit FNV-1a hash folded over the pepper and the byte
/// index, so each position gets its own pseudo-random mask. Change [_huskPepper]
/// (and re-run tool/encode_coop_values.dart) for every new app so two binaries
/// never share the same encoded bytes.
library;

const List<int> _huskPepper = <int>[
  0x63, 0x48, 0x72, 0x75, 0x6E, 0x23, 0x34, 0x32, 0x4B, 0x78,
];

int _huskByte(int index) {
  var hash = 0x811c9dc5;
  const prime = 0x01000193;
  for (final unit in _huskPepper) {
    hash = ((hash ^ unit) * prime) & 0xFFFFFFFF;
  }
  for (var shift = 0; shift < 4; shift++) {
    hash = ((hash ^ ((index >> (shift * 8)) & 0xFF)) * prime) & 0xFFFFFFFF;
  }
  return (hash ^ (hash >> 15)) & 0xFF;
}

/// Reveals a byte array produced by tool/encode_coop_values.dart.
String revealHusk(List<int> encoded) {
  if (encoded.isEmpty) return '';
  final plain = List<int>.generate(
    encoded.length,
    (index) => (encoded[index] - _huskByte(index) - (index * 29)) & 0xFF,
  );
  return String.fromCharCodes(plain);
}
