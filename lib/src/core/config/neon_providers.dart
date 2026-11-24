import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'neon_config.dart';

/// Public backend URLs, read once at build time.
///
/// Tests override this with a fake config; builds without `--dart-define`
/// values get an unconfigured instance and run fully offline.
final neonConfigProvider = Provider<NeonConfig>((ref) => NeonConfig.current);
