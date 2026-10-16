import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database.dart';
import '../data/database_provider.dart';

part 'settings_providers.g.dart';

@riverpod
Stream<Setting> settings(Ref ref) =>
    ref.watch(appDatabaseProvider).watchSettings();
