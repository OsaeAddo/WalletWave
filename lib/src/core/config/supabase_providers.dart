import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The initialized Supabase client, or `null` when this build has no keys.
///
/// A nullable provider keeps every consumer honest: cloud features must handle
/// "no backend" instead of assuming one exists.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);
