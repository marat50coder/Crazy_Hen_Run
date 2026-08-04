/// Persisted routing decision for a returning launch.
enum CoopPath {
  native,
  portal,
  undecided;

  String get storageValue => switch (this) {
    CoopPath.native => 'native',
    CoopPath.portal => 'portal',
    CoopPath.undecided => 'undecided',
  };

  static CoopPath parse(String? value) => switch (value) {
    'portal' || 'web' => CoopPath.portal,
    'native' || 'game' => CoopPath.native,
    _ => CoopPath.undecided,
  };
}

/// Parsed response from the config endpoint.
class CoopReply {
  const CoopReply({
    required this.accepted,
    this.url,
    this.expiresAt,
    this.reason,
  });

  factory CoopReply.fromJson(Map<String, dynamic> json) {
    final rawExpiry = json['expires'];
    return CoopReply(
      accepted: json['ok'] == true,
      url: json['url'] is String ? json['url'] as String : null,
      expiresAt: rawExpiry is num
          ? rawExpiry.toInt()
          : int.tryParse(rawExpiry?.toString() ?? ''),
      reason: json['message']?.toString(),
    );
  }

  factory CoopReply.rejected(String reason) =>
      CoopReply(accepted: false, reason: reason);

  final bool accepted;
  final String? url;
  final int? expiresAt;
  final String? reason;

  bool get hasDestination => accepted && (url?.isNotEmpty ?? false);
}

/// Where the boot gate should route once the pipeline resolves.
sealed class CoopDest {
  const CoopDest();
}

final class NativeStop extends CoopDest {
  const NativeStop();
}

final class PortalStop extends CoopDest {
  const PortalStop(this.url, {this.coldLaunch = false});

  final String url;
  final bool coldLaunch;
}

final class OfflineStop extends CoopDest {
  const OfflineStop({required this.returnToNative});

  final bool returnToNative;
}
