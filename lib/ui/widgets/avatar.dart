import 'dart:io';

import 'package:flutter/material.dart';

import '../../foundation/theme/palette.dart';
import '../../persistence/models/profile.dart';

/// Circular profile picture with an initials fallback. The photo lives in the
/// app's documents directory, so it renders without any network access.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.profile,
    this.size = 44,
    this.ringColor,
    this.ringWidth = 2,
    this.onTap,
  });

  final Profile profile;
  final double size;
  final Color? ringColor;
  final double ringWidth;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final ring = ringColor ?? c.accent;
    final path = profile.avatarPath;
    final hasPhoto = path.isNotEmpty && File(path).existsSync();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(ringWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[ring, ring.withValues(alpha: 0.45)],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.surface,
          ),
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: hasPhoto
                ? Image.file(
                    File(path),
                    key: ValueKey<String>('$path-${File(path).lengthSync()}'),
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (context, _, _) => _Initials(
                      profile: profile,
                      size: size,
                    ),
                  )
                : _Initials(profile: profile, size: size),
          ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.profile, required this.size});

  final Profile profile;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    return Container(
      color: c.accentSoft,
      alignment: Alignment.center,
      child: Text(
        profile.initials,
        style: TextStyle(
          fontFamily: 'SpaceGrotesk',
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: c.accent,
        ),
      ),
    );
  }
}
