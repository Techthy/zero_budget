// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(settings)
final settingsProvider = SettingsProvider._();

final class SettingsProvider
    extends $FunctionalProvider<AsyncValue<Setting>, Setting, Stream<Setting>>
    with $FutureModifier<Setting>, $StreamProvider<Setting> {
  SettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsHash();

  @$internal
  @override
  $StreamProviderElement<Setting> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Setting> create(Ref ref) {
    return settings(ref);
  }
}

String _$settingsHash() => r'e7ebe58834936753a5598249462db6aa6b81f85b';

/// How budgets are listed; by category until the settings are loaded.

@ProviderFor(budgetOrder)
final budgetOrderProvider = BudgetOrderProvider._();

/// How budgets are listed; by category until the settings are loaded.

final class BudgetOrderProvider
    extends $FunctionalProvider<BudgetOrder, BudgetOrder, BudgetOrder>
    with $Provider<BudgetOrder> {
  /// How budgets are listed; by category until the settings are loaded.
  BudgetOrderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'budgetOrderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$budgetOrderHash();

  @$internal
  @override
  $ProviderElement<BudgetOrder> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  BudgetOrder create(Ref ref) {
    return budgetOrder(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BudgetOrder value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BudgetOrder>(value),
    );
  }
}

String _$budgetOrderHash() => r'244b6cc802c9d3dbb8da04930ce8122ba96129e9';

/// The buffer to keep in the bank account on top of the plan.

@ProviderFor(bufferCents)
final bufferCentsProvider = BufferCentsProvider._();

/// The buffer to keep in the bank account on top of the plan.

final class BufferCentsProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// The buffer to keep in the bank account on top of the plan.
  BufferCentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bufferCentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bufferCentsHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return bufferCents(ref);
  }
}

String _$bufferCentsHash() => r'37f36c6ee8651a4b9568a083b1ec2003c50a715f';

/// The app's version as the build named it, like 1.2.0 for a release or
/// 1.2.0-nightly.57 for a nightly.

@ProviderFor(appVersion)
final appVersionProvider = AppVersionProvider._();

/// The app's version as the build named it, like 1.2.0 for a release or
/// 1.2.0-nightly.57 for a nightly.

final class AppVersionProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The app's version as the build named it, like 1.2.0 for a release or
  /// 1.2.0-nightly.57 for a nightly.
  AppVersionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appVersionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appVersionHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return appVersion(ref);
  }
}

String _$appVersionHash() => r'ba3c22ffcbb681a34abb9097ad16cde90c9e2247';
