import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show Supabase, SupabaseClient;

import '../data/auth_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
      (ref) => Supabase.instance.client,
);

final authRepositoryProvider = Provider<AuthRepository>(
      (ref) => AuthRepository(ref.watch(supabaseClientProvider)),
);