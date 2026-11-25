import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/core/config/neon_config.dart';
import 'package:wallet_wave/src/features/portfolio/data/wallet_backup_service.dart';
import 'package:wallet_wave/src/features/portfolio/domain/saved_wallet.dart';

/// Answers every request with one canned response and records what was sent.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.body, {this.status = 200});

  final String body;
  final int status;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const config = NeonConfig(
    authBaseUrl: 'https://auth.example/neondb/auth',
    dataApiUrl: 'https://data.example/neondb/rest/v1',
    functionsBaseUrl: 'https://functions.example/',
  );

  WalletBackupService serviceWith(
    _StubAdapter api,
    _StubAdapter transfer,
  ) {
    return WalletBackupService(
      config: config,
      api: Dio()..httpClientAdapter = api,
      transfer: Dio()..httpClientAdapter = transfer,
    );
  }

  test('backup uploads a versioned JSON file through the signed URL', () async {
    final api = _StubAdapter(
      jsonEncode({'url': 'https://s3.example/bucket/backups/u.json?X=1'}),
    );
    final transfer = _StubAdapter('');

    await serviceWith(api, transfer).backup(const [
      SavedWallet(id: 1, address: '0xabc', label: 'Main'),
    ]);

    expect(
      api.requests.single.uri.toString(),
      'https://functions.example/storage/upload-url',
    );

    final put = transfer.requests.single;
    expect(put.method, 'PUT');
    expect(put.uri.toString(), contains('/bucket/backups/u.json'));
    expect(put.contentType, Headers.jsonContentType);

    final body = jsonDecode(put.data as String) as Map<String, dynamic>;
    expect(body['version'], 1);
    expect(body['app'], 'walletwave');
    final wallets = body['wallets'] as List;
    expect(wallets.single, {'address': '0xabc', 'label': 'Main'});
  });

  test('download parses valid rows and skips malformed ones', () async {
    final api = _StubAdapter(
      jsonEncode({'url': 'https://s3.example/bucket/backups/u.json?X=1'}),
    );
    final transfer = _StubAdapter(
      jsonEncode({
        'version': 1,
        'wallets': [
          {'address': '0xabc', 'label': 'Main'},
          {'label': 'no address'},
          'not a row',
        ],
      }),
    );

    final entries = await serviceWith(api, transfer).download();

    expect(entries, hasLength(1));
    expect(entries!.single.address, '0xabc');
    expect(entries.single.label, 'Main');
  });

  test('a missing object is reported as no backup, not an error', () async {
    final api = _StubAdapter(
      jsonEncode({'url': 'https://s3.example/bucket/backups/u.json?X=1'}),
    );
    final transfer = _StubAdapter('NoSuchKey', status: 404);

    final entries = await serviceWith(api, transfer).download();

    expect(entries, isNull);
  });

  test('an expired session produces a friendly message', () async {
    final api = _StubAdapter('{"error":"expired"}', status: 401);

    expect(
      () => serviceWith(api, _StubAdapter('')).backup(const []),
      throwsA(
        isA<WalletBackupException>().having(
          (error) => error.message,
          'message',
          contains('session expired'),
        ),
      ),
    );
  });

  test('an unconfigured build refuses before any request', () async {
    const offline = NeonConfig(
      authBaseUrl: '',
      dataApiUrl: '',
      functionsBaseUrl: '',
    );
    final api = _StubAdapter('');
    final transfer = _StubAdapter('');
    final service = WalletBackupService(
      config: offline,
      api: Dio()..httpClientAdapter = api,
      transfer: Dio()..httpClientAdapter = transfer,
    );

    await expectLater(
      () => service.backup(const []),
      throwsA(isA<WalletBackupException>()),
    );
    expect(api.requests, isEmpty);
  });
}
