import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database.dart';
import '../data/database_provider.dart';

part 'settings_providers.g.dart';

@riverpod
Stream<Setting> settings(Ref ref) =>
    ref.watch(appDatabaseProvider).watchSettings();

/// The app's version as the build named it, like 1.2.0 for a release or
/// 1.2.0-nightly.57 for a nightly.
@riverpod
Future<String> appVersion(Ref ref) async =>
    (await PackageInfo.fromPlatform()).version;
