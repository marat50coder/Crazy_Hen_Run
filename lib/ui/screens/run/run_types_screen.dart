import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/run_type.dart';
import '../../widgets/hen.dart';
import '../../widgets/surfaces.dart';
import 'live_run_screen.dart';

class RunTypesScreen extends StatelessWidget {
  const RunTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Run types')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          Text(
            'Six ways to move. Pick one and the whole live screen, the hen and the '
            'effort trace adapt to that flavour of running.',
            style: context.text.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          ...RunType.values.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _TypeCard(type: t),
              )),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({required this.type});

  final RunType type;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => LiveRunScreen(type: type)),
      ),
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  type.color,
                  Color.alphaBlend(Colors.black.withValues(alpha: 0.2), type.color),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
            ),
            child: Row(
              children: <Widget>[
                Icon(type.icon, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type.label,
                    style: context.text.titleLarge?.copyWith(color: Colors.white),
                  ),
                ),
                HenFigure(asset: type.henAsset, size: 54),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(type.blurb, style: context.text.bodyMedium)),
                const SizedBox(width: 8),
                TagChip(label: type.tag, color: type.color, dense: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
