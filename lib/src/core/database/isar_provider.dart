import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/market/data/local/market_coin_entity.dart';
import '../../features/portfolio/data/local/saved_wallet_entity.dart';

// initialized synchronously in main.dart, which guarantees
// the rest of the app can read the database without awaiting it.
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('isarProvider must be overridden in main.dart');
});

Future<Isar> initIsar() async {
  final dir = await getApplicationDocumentsDirectory();
  return await Isar.open(
    [MarketCoinEntitySchema, SavedWalletEntitySchema],
    directory: dir.path,
  );
}
