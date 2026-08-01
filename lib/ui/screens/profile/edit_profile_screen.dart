import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/avatar_store.dart';
import '../../../state/app_state.dart';
import '../../widgets/avatar.dart';
import '../../widgets/surfaces.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _name;
  late final TextEditingController _tagline;
  late int _dailyGoal;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().profile;
    _name = TextEditingController(text: profile.name);
    _tagline = TextEditingController(text: profile.tagline);
    _dailyGoal = profile.dailyGoal;
  }

  @override
  void dispose() {
    _name.dispose();
    _tagline.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 900,
        maxHeight: 900,
        imageQuality: 88,
      );
      if (picked == null) return;
      final path = await AvatarStore.save(File(picked.path));
      if (!mounted) return;
      final app = context.read<AppState>();
      await app.updateProfile(app.profile.copyWith(avatarPath: path));
      // The file name changes on every save, so the image cache cannot serve
      // a stale bitmap — but old entries are still worth dropping.
      imageCache.clear();
      imageCache.clearLiveImages();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that photo.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _showPhotoSheet() async {
    final app = context.read<AppState>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 6, bottom: 10),
                child: Text('Profile photo', style: context.text.titleLarge),
              ),
              _SheetAction(
                icon: Icons.photo_camera_rounded,
                label: 'Take a photo',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pick(ImageSource.camera);
                },
              ),
              _SheetAction(
                icon: Icons.photo_library_rounded,
                label: 'Choose from gallery',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _pick(ImageSource.gallery);
                },
              ),
              if (app.profile.avatarPath.isNotEmpty)
                _SheetAction(
                  icon: Icons.delete_outline_rounded,
                  label: 'Remove photo',
                  danger: true,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    app.clearAvatar();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    await app.updateProfile(
      app.profile.copyWith(
        name: _name.text.trim().isEmpty ? 'Runner' : _name.text.trim(),
        tagline: _tagline.text.trim(),
        dailyGoal: _dailyGoal,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final c = context.palette;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: <Widget>[
                ProfileAvatar(
                  profile: app.profile,
                  size: 140,
                  ringWidth: 3.5,
                  onTap: _showPhotoSheet,
                ),
                GestureDetector(
                  onTap: _showPhotoSheet,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.canvas, width: 3),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            Icons.add_a_photo_rounded,
                            size: 16,
                            color: c.accent.computeLuminance() > 0.55
                                ? c.textPrimary
                                : Colors.white,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(
            child: TextButton.icon(
              onPressed: _showPhotoSheet,
              icon: const Icon(Icons.photo_camera_back_rounded, size: 18),
              label: const Text('Change photo'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Display name', style: context.text.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(hintText: 'Your name'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Tagline', style: context.text.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: _tagline,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'What are you working towards?',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Daily goal', style: context.text.titleSmall),
                Text(
                  'How many habits you aim to close each day.',
                  style: context.text.bodySmall,
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Slider(
                        value: _dailyGoal.toDouble(),
                        min: 1,
                        max: 12,
                        divisions: 11,
                        label: '$_dailyGoal',
                        onChanged: (v) => setState(() => _dailyGoal = v.round()),
                      ),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '$_dailyGoal',
                        textAlign: TextAlign.right,
                        style: context.text.titleMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(onPressed: _save, child: const Text('Save changes')),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.palette;
    final tone = danger ? c.danger : c.textPrimary;
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      leading: Icon(icon, color: tone),
      title: Text(
        label,
        style: context.text.titleSmall?.copyWith(color: tone),
      ),
    );
  }
}
