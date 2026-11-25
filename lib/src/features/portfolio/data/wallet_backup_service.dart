import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/config/neon_config.dart';
import '../domain/saved_wallet.dart';

/// A user-readable backup failure.
class WalletBackupException implements Exception {
  const WalletBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One wallet in a backup file.
class WalletBackupEntry {
  const WalletBackupEntry({required this.address, required this.label});

  final String address;
  final String label;
}

/// Uploads and downloads the user's wallet list as one JSON object.
///
/// The file lives in the private `uploads` bucket under a key the *server*
/// derives from the JWT, never from anything the client sends. The app only
/// ever holds a five-minute presigned URL. Two Dio instances are used on
/// purpose: the function call needs the auth header, while S3 rejects a request
/// whose headers do not match the signature, so the transfer must be anonymous.
class WalletBackupService {
  WalletBackupService({
    required NeonConfig config,
    required Dio api,
    Dio? transfer,
  })  : _config = config,
        _api = api,
        _transfer = transfer ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 20),
                receiveTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(seconds: 30),
              ),
            );

  static const int formatVersion = 1;

  final NeonConfig _config;
  final Dio _api;
  final Dio _transfer;

  /// Replaces the cloud copy with exactly [wallets].
  Future<void> backup(List<SavedWallet> wallets) async {
    final url = await _signedUrl('/storage/upload-url');
    final body = jsonEncode({
      'version': formatVersion,
      'app': 'walletwave',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'wallets': [
        for (final wallet in wallets)
          {'address': wallet.address, 'label': wallet.label},
      ],
    });

    try {
      await _transfer.put<dynamic>(
        url,
        data: body,
        options: Options(
          contentType: Headers.jsonContentType,
          // S3 answers with an empty body; do not try to parse it as JSON.
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
    } on DioException catch (error) {
      throw WalletBackupException(_transferMessage(error));
    }
  }

  /// Downloads the cloud copy, or `null` when the user has no backup yet.
  Future<List<WalletBackupEntry>?> download() async {
    final url = await _signedUrl('/storage/download-url');

    late final Response<String> response;
    try {
      response = await _transfer.get<String>(
        url,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } on DioException catch (error) {
      throw WalletBackupException(_transferMessage(error));
    }

    if (response.statusCode == 404 || response.statusCode == 403) {
      // A missing object is not an error the user needs to troubleshoot.
      return null;
    }
    if ((response.statusCode ?? 500) >= 400) {
      throw const WalletBackupException(
        'Storage refused the download. Try again in a moment.',
      );
    }

    return _parse(response.data);
  }

  Future<String> _signedUrl(String path) async {
    if (!_config.hasFunctions) {
      throw const WalletBackupException(
        'Cloud backup is not configured in this build.',
      );
    }

    try {
      final response = await _api.post<Map<String, dynamic>>(
        '${_config.functionsUrl}$path',
      );
      final url = response.data?['url'];
      if (url is! String || url.isEmpty) {
        throw const WalletBackupException(
          'The server did not return a storage URL.',
        );
      }
      return url;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401) {
        throw const WalletBackupException(
          'Your session expired. Sign in again to use cloud backup.',
        );
      }
      throw const WalletBackupException(
        'Could not reach cloud backup. Check your connection and try again.',
      );
    }
  }

  List<WalletBackupEntry> _parse(String? body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body ?? '');
    } catch (_) {
      throw const WalletBackupException(
        'That backup file could not be read.',
      );
    }
    if (decoded is! Map || decoded['wallets'] is! List) {
      throw const WalletBackupException(
        'That backup file is not a WalletWave backup.',
      );
    }

    final entries = <WalletBackupEntry>[];
    for (final row in decoded['wallets'] as List) {
      if (row is! Map) continue;
      final address = row['address'];
      final label = row['label'];
      if (address is! String || address.isEmpty) continue;
      entries.add(
        WalletBackupEntry(
          address: address,
          label: label is String && label.isNotEmpty ? label : address,
        ),
      );
    }
    return entries;
  }

  String _transferMessage(DioException error) {
    if (error.response?.statusCode == 403) {
      return 'The storage link expired. Try again.';
    }
    return 'The backup transfer failed. Check your connection and try again.';
  }
}
