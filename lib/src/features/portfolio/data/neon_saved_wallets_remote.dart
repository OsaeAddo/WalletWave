import 'package:dio/dio.dart';

import '../../../core/config/neon_config.dart';
import 'saved_wallets_remote.dart';

/// [SavedWalletsRemote] backed by Neon's PostgREST-compatible Data API.
///
/// No user id is sent: the table defaults `user_id` to `auth.uid()` and Row
/// Level Security scopes every read and write to the signed-in user. The Dio
/// instance this gets is already wired with [AuthInterceptor], so each request
/// carries a fresh JWT.
class NeonSavedWalletsRemote implements SavedWalletsRemote {
  NeonSavedWalletsRemote({required NeonConfig config, required Dio dio})
      : _base = '${config.dataUrl}/saved_wallets',
        _dio = dio;

  final String _base;
  final Dio _dio;

  @override
  Future<List<RemoteSavedWallet>> fetchAll() async {
    final response = await _dio.get<List<dynamic>>(
      _base,
      queryParameters: {
        'select': 'address,label',
        'order': 'created_at.desc',
      },
    );

    final rows = response.data ?? const <dynamic>[];
    return [
      for (final row in rows)
        if (row is Map)
          RemoteSavedWallet(
            address: row['address'] as String,
            label: row['label'] as String,
          ),
    ];
  }

  @override
  Future<void> upsert({required String address, required String label}) async {
    await _dio.post<dynamic>(
      _base,
      // Matches `saved_wallets_user_address_key`, so saving the same wallet
      // twice updates its label instead of failing.
      queryParameters: {'on_conflict': 'user_id,address'},
      options: Options(
        headers: {'Prefer': 'resolution=merge-duplicates,return=minimal'},
      ),
      data: {'address': address.toLowerCase(), 'label': label},
    );
  }

  @override
  Future<void> remove(String address) async {
    await _dio.delete<dynamic>(
      _base,
      queryParameters: {'address': 'eq.${address.toLowerCase()}'},
    );
  }
}
