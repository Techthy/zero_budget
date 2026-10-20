import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database.dart';
import '../data/database_provider.dart';

part 'settings_providers.g.dart';

@riverpod
Stream<Setting> settings(Ref ref) =>
    ref.watch(appDatabaseProvider).watchSettings();

/// How budgets are listed; by category until the settings are loaded.
@riverpod
BudgetOrder budgetOrder(Ref ref) =>
    ref.watch(settingsProvider).value?.budgetOrder ?? BudgetOrder.category;

/// The buffer to keep in the bank account on top of the plan.
@riverpod
Stream<int> bufferCents(Ref ref) =>
    ref.watch(appDatabaseProvider).watchBufferCents();

/// The app's version as the build named it, like 1.2.0 for a release or
/// 1.2.0-nightly.57 for a nightly.
@riverpod
Future<String> appVersion(Ref ref) async =>
    (await PackageInfo.fromPlatform()).version;
