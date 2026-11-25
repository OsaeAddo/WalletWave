import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_wave/src/core/config/neon_config.dart';
import 'package:wallet_wave/src/features/portfolio/data/neon_saved_wallets_remote.dart';

/// Records the requests the remote makes and answers with canned JSON.
class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body);

  final String body;
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
      200,
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
    functionsBaseUrl: '',
  );

  NeonSavedWalletsRemote remoteWith(_RecordingAdapter adapter) {
    final dio = Dio()..httpClientAdapter = adapter;
    return NeonSavedWalletsRemote(config: config, dio: dio);
  }

  test('fetchAll asks for the two columns, newest first', () async {
    final adapter = _RecordingAdapter(
      jsonEncode([
        {'address': '0xabc', 'label': 'Main'},
      ]),
    );

    final rows = await remoteWith(adapter).fetchAll();

    expect(rows.single.address, '0xabc');
    expect(rows.single.label, 'Main');
    final request = adapter.requests.single;
    expect(request.uri.toString(),
        startsWith('https://data.example/neondb/rest/v1/saved_wallets'));
    expect(request.queryParameters['select'], 'address,label');
    expect(request.queryParameters['order'], 'created_at.desc');
  });

  test('upsert lowercases the address and merges duplicates', () async {
    final adapter = _RecordingAdapter('');

    await remoteWith(adapter).upsert(address: '0xABC', label: 'Main');

    final request = adapter.requests.single;
    expect(request.method, 'POST');
    expect(request.queryParameters['on_conflict'], 'user_id,address');
    expect(request.headers['Prefer'],
        'resolution=merge-duplicates,return=minimal');
    expect((request.data as Map)['address'], '0xabc');
  });

  test('remove filters by the lowercase address', () async {
    final adapter = _RecordingAdapter('');

    await remoteWith(adapter).remove('0xABC');

    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.queryParameters['address'], 'eq.0xabc');
  });
}
