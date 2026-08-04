import 'package:flutter/material.dart';

import 'paddock/coop_marshal.dart';
import 'paddock/pages/warmup_gate.dart';

/// Root of the gray-flow shell. It only hosts the boot gate; the white game
/// (`CrazyHenRunApp`) owns its own MaterialApp + providers and is pushed by
/// [WarmupGate] on the organic path.
class HenGateApp extends StatelessWidget {
  const HenGateApp({super.key, this.marshal});

  final CoopMarshal? marshal;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crazy Hen Run',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF02311D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F8E4A),
          brightness: Brightness.light,
        ),
      ),
      home: WarmupGate(marshal: marshal),
    );
  }
}
