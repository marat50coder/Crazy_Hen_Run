import 'dart:io';

import 'package:image/image.dart' as img;

String hex(img.Pixel p) =>
    '#${p.r.toInt().toRadixString(16).padLeft(2, '0')}'
    '${p.g.toInt().toRadixString(16).padLeft(2, '0')}'
    '${p.b.toInt().toRadixString(16).padLeft(2, '0')}';

void main() {
  for (final name in ['boot_portrait', 'boot_landscape']) {
    final im = img.decodeWebP(File('assets/$name.webp').readAsBytesSync())!;
    stdout.writeln('$name ${im.width}x${im.height}');
    stdout.writeln('  top-left  ${hex(im.getPixel(4, 4))}');
    stdout.writeln('  top-mid   ${hex(im.getPixel(im.width ~/ 2, 4))}');
    stdout.writeln('  mid       ${hex(im.getPixel(im.width ~/ 2, im.height ~/ 2))}');
    stdout.writeln('  bottom    ${hex(im.getPixel(im.width ~/ 2, im.height - 5))}');
  }
}
