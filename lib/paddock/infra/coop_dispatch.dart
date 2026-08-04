import 'dart:convert';

import '../config/coop_config.dart';
import '../core/coop_log.dart';
import '../core/coop_models.dart';
import 'coop_vault.dart';
import 'stride_client.dart';

/// POSTs the flat attribution body to the config endpoint and parses the
/// verdict. A successful reply with a URL is cached (with its expiry) for
/// returning launches.
class CoopDispatch {
  CoopDispatch(this._client, this._vault);

  final StrideClient _client;
  final CoopVault _vault;

  Future<CoopReply> request(Map<String, dynamic> payload) async {
    if (!CoopConfig.grayCredentialsReady) {
      return CoopReply.rejected('credentials_unavailable');
    }
    try {
      chrTrace(() => '[CHR.DISPATCH] request ${jsonEncode(payload)}');
      final response = await _client.post(
        Uri.parse(CoopConfig.endpoint),
        headers: const <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));
      chrTrace(
        () => '[CHR.DISPATCH] response ${response.statusCode} ${response.body}',
      );
      if (response.statusCode != 200) {
        return CoopReply.rejected('http_${response.statusCode}');
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return CoopReply.rejected('invalid_response');
      final reply = CoopReply.fromJson(Map<String, dynamic>.from(decoded));
      if (reply.hasDestination) {
        await _vault.cacheUrl(reply.url!, reply.expiresAt);
      }
      return reply;
    } catch (error) {
      chrTrace(() => '[CHR.DISPATCH] failed: $error');
      return CoopReply.rejected('network_failure');
    }
  }
}
