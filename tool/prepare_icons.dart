import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  final logo = img.decodeWebP(File('assets/logo.webp').readAsBytesSync())!;
  stdout.writeln('logo numChannels=${logo.numChannels}');
  final c = logo.getPixel(2, 2);
  stdout.writeln('logo corner rgba=${c.r},${c.g},${c.b},${c.a}');

  final icon = img.decodePng(File('assets/icon.png').readAsBytesSync())!;
  final ic = icon.getPixel(3, 3);
  stdout.writeln('icon corner rgba=${ic.r},${ic.g},${ic.b},${ic.a}');

  // Adaptive foreground: the artwork fills the full 1024 canvas.
  // Android clips adaptive icons with a launcher mask, so no extra inset here —
  // the XML no longer wraps it in <inset>, which was causing a visible border.
  const canvas = 1024;
  const inner = 1024; // fill the whole canvas; the dark background does the rest
  final fg = img.Image(width: canvas, height: canvas, numChannels: 4);
  img.fill(fg, color: img.ColorRgba8(0, 0, 0, 0));
  final art = img.copyResize(icon, width: inner, height: inner);
  img.compositeImage(fg, art, dstX: 0, dstY: 0);
  File('assets/icon_foreground.png').writeAsBytesSync(img.encodePng(fg));

  // Monochrome variant for themed launcher icons.
  final mono = img.Image(width: canvas, height: canvas, numChannels: 4);
  img.fill(mono, color: img.ColorRgba8(0, 0, 0, 0));
  final grey = img.grayscale(img.copyResize(icon, width: inner, height: inner));
  img.compositeImage(mono, grey, dstX: 0, dstY: 0);
  File('assets/icon_monochrome.png').writeAsBytesSync(img.encodePng(mono));

  stdout.writeln('written foreground + monochrome');
}
