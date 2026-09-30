// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'welcome_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Months to shift the current month by, so moving through months can be
/// tried out in debug builds.

@ProviderFor(MonthOffset)
final monthOffsetProvider = MonthOffsetProvider._();

/// Months to shift the current month by, so moving through months can be
/// tried out in debug builds.
final class MonthOffsetProvider extends $NotifierProvider<MonthOffset, int> {
  /// Months to shift the current month by, so moving through months can be
  /// tried out in debug builds.
  MonthOffsetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthOffsetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthOffsetHash();

  @$internal
  @override
  MonthOffset create() => MonthOffset();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$monthOffsetHash() => r'e58d3471022ad5ac219b51c04dbf9603b9f0ba75';

/// Months to shift the current month by, so moving through months can be
/// tried out in debug builds.

abstract class _$MonthOffset extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<int, int>,
              int,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The year and month the app treats as the current one.

@ProviderFor(currentYearMonth)
final currentYearMonthProvider = CurrentYearMonthProvider._();

/// The year and month the app treats as the current one.

final class CurrentYearMonthProvider
    extends
        $FunctionalProvider<
          ({int month, int year}),
          ({int month, int year}),
          ({int month, int year})
        >
    with $Provider<({int month, int year})> {
  /// The year and month the app treats as the current one.
  CurrentYearMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentYearMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentYearMonthHash();

  @$internal
  @override
  $ProviderElement<({int month, int year})> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ({int month, int year}) create(Ref ref) {
    return currentYearMonth(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({int month, int year}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({int month, int year})>(value),
    );
  }
}

String _$currentYearMonthHash() => r'64c4c8eb65dd76933974abd0bcbaf3d05e058de2';

/// Id of the current month's row, created the first time it's needed.

@ProviderFor(currentMonthId)
final currentMonthIdProvider = CurrentMonthIdProvider._();

/// Id of the current month's row, created the first time it's needed.

final class CurrentMonthIdProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Id of the current month's row, created the first time it's needed.
  CurrentMonthIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthIdHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return currentMonthId(ref);
  }
}

String _$currentMonthIdHash() => r'ca3b114043f44e8a537932350b8bd5b189c657ac';

@ProviderFor(currentMonth)
final currentMonthProvider = CurrentMonthProvider._();

final class CurrentMonthProvider
    extends $FunctionalProvider<AsyncValue<Month>, Month, Stream<Month>>
    with $FutureModifier<Month>, $StreamProvider<Month> {
  CurrentMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthHash();

  @$internal
  @override
  $StreamProviderElement<Month> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Month> create(Ref ref) {
    return currentMonth(ref);
  }
}

String _$currentMonthHash() => r'b4efa705c2b9c3b386dec4f12b7cab6444fb4a53';

@ProviderFor(currentBudgets)
final currentBudgetsProvider = CurrentBudgetsProvider._();

final class CurrentBudgetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Budget>>,
          List<Budget>,
          Stream<List<Budget>>
        >
    with $FutureModifier<List<Budget>>, $StreamProvider<List<Budget>> {
  CurrentBudgetsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentBudgetsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentBudgetsHash();

  @$internal
  @override
  $StreamProviderElement<List<Budget>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Budget>> create(Ref ref) {
    return currentBudgets(ref);
  }
}

String _$currentBudgetsHash() => r'3b14d7fc3afec310f880e36559750213b01fc263';

@ProviderFor(currentIncomes)
final currentIncomesProvider = CurrentIncomesProvider._();

final class CurrentIncomesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Income>>,
          List<Income>,
          Stream<List<Income>>
        >
    with $FutureModifier<List<Income>>, $StreamProvider<List<Income>> {
  CurrentIncomesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentIncomesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentIncomesHash();

  @$internal
  @override
  $StreamProviderElement<List<Income>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Income>> create(Ref ref) {
    return currentIncomes(ref);
  }
}

String _$currentIncomesHash() => r'0f9bb4817f52a69d978c0ba6c10c296d3d6ca331';
