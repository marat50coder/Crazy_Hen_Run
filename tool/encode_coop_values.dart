// ignore_for_file: avoid_print

/// Encoder for the paddock (gray-flow) secrets.
///
/// 1. Fill [values] below with this app's plaintext.
/// 2. Keep [_huskPepper] identical to lib/paddock/core/husk_cipher.dart.
/// 3. Run: dart run tool/encode_coop_values.dart
/// 4. Paste the printed byte arrays into lib/paddock/config/coop_config.dart.
///    The VERIFY line must confirm every value round-trips byte-for-byte.
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

List<int> foldHusk(String value) {
  final units = value.codeUnits;
  return List<int>.generate(
    units.length,
    (index) => (units[index] + _huskByte(index) + (index * 29)) & 0xFF,
  );
}

String revealHusk(List<int> encoded) {
  if (encoded.isEmpty) return '';
  return String.fromCharCodes(
    List<int>.generate(
      encoded.length,
      (index) => (encoded[index] - _huskByte(index) - (index * 29)) & 0xFF,
    ),
  );
}

void main() {
  const values = <String, String>{
    'config': 'https://crazyhennrun.com/config.php',
    'privacy': 'https://crazyhennrun.com/privacy-policy.html',
    'support': 'https://crazyhennrun.com/support.html',
    'gcd': 'https://gcdsdk.appsflyer.com/install_data/v5.0/',
    'webkit': '605.1.15',
    'safari': '18.7',
    'safariTail': '604.1',
    'appsFlyerDevKey': 'HxiGyKQNpvWDytNED5fKaP',
    'firebaseProjectNumber': '541169687251',
    'oneLinkHost': 'crazyhenrun.onelink.me',
  };

  for (final entry in values.entries) {
    final encoded = foldHusk(entry.value);
    print('${entry.key}: <int>[${encoded.join(', ')}]');
    if (revealHusk(encoded) != entry.value) {
      throw StateError('Round-trip failed for ${entry.key}');
    }
  }
  print('VERIFY: all values round-tripped');
}
