import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final dir = Directory('assets');
  Directory('.preview').createSync();
  for (final f in dir.listSync().whereType<File>()) {
    if (!f.path.toLowerCase().endsWith('.webp')) continue;
    final bytes = f.readAsBytesSync();
    final decoded = img.decodeWebP(bytes);
    if (decoded == null) {
      stdout.writeln('FAILED ${f.path}');
      continue;
    }
    final name = f.uri.pathSegments.last.replaceAll('.webp', '.png');
    final resized = decoded.width > 700
        ? img.copyResize(decoded, width: 700)
        : decoded;
    File('.preview/$name').writeAsBytesSync(img.encodePng(resized));
    stdout.writeln('$name ${decoded.width}x${decoded.height}');
  }
}
