import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Copies a picked photo into the app's own documents directory so the avatar
/// survives cache clears and keeps working with no network access.
class AvatarStore {
  const AvatarStore._();

  static Future<String> save(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('${dir.path}/avatars');
    if (!folder.existsSync()) folder.createSync(recursive: true);

    final extension = _extensionOf(source.path);
    final target =
        File('${folder.path}/avatar_${DateTime.now().millisecondsSinceEpoch}$extension');
    await source.copy(target.path);

    // Only the newest avatar is kept; older copies are dead weight.
    for (final entity in folder.listSync()) {
      if (entity is File && entity.path != target.path) {
        try {
          entity.deleteSync();
        } on FileSystemException {
          // Ignore files the OS still holds open.
        }
      }
    }
    return target.path;
  }

  static String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || path.length - dot > 6) return '.jpg';
    return path.substring(dot);
  }
}
