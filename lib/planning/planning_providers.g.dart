// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Days to shift today by, so moving through time can be tried out in debug
/// builds.

@ProviderFor(DayOffset)
final dayOffsetProvider = DayOffsetProvider._();

/// Days to shift today by, so moving through time can be tried out in debug
/// builds.
final class DayOffsetProvider extends $NotifierProvider<DayOffset, int> {
  /// Days to shift today by, so moving through time can be tried out in debug
  /// builds.
  DayOffsetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dayOffsetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dayOffsetHash();

  @$internal
  @override
  DayOffset create() => DayOffset();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$dayOffsetHash() => r'3dc08eece1b67661b3938453fbbea72e9116944f';

/// Days to shift today by, so moving through time can be tried out in debug
/// builds.

abstract class _$DayOffset extends $Notifier<int> {
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

/// Today's date, shifted by [DayOffset] in debug builds.
///
/// Invalidate it when the app comes back to the foreground, as the day may
/// have changed.

@ProviderFor(today)
final todayProvider = TodayProvider._();

/// Today's date, shifted by [DayOffset] in debug builds.
///
/// Invalidate it when the app comes back to the foreground, as the day may
/// have changed.

final class TodayProvider
    extends $FunctionalProvider<DateTime, DateTime, DateTime>
    with $Provider<DateTime> {
  /// Today's date, shifted by [DayOffset] in debug builds.
  ///
  /// Invalidate it when the app comes back to the foreground, as the day may
  /// have changed.
  TodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayHash();

  @$internal
  @override
  $ProviderElement<DateTime> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DateTime create(Ref ref) {
    return today(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$todayHash() => r'bcaae42e5a83533c3cf357e8ab4770f68fcb3553';

/// The month the user works in, which they choose themselves.
///
/// The app starts in today's month and stays in it, even once a new month
/// starts, until the user moves on.

@ProviderFor(currentYearMonth)
final currentYearMonthProvider = CurrentYearMonthProvider._();

/// The month the user works in, which they choose themselves.
///
/// The app starts in today's month and stays in it, even once a new month
/// starts, until the user moves on.

final class CurrentYearMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<YearMonth>,
          YearMonth,
          FutureOr<YearMonth>
        >
    with $FutureModifier<YearMonth>, $FutureProvider<YearMonth> {
  /// The month the user works in, which they choose themselves.
  ///
  /// The app starts in today's month and stays in it, even once a new month
  /// starts, until the user moves on.
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
  $FutureProviderElement<YearMonth> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<YearMonth> create(Ref ref) {
    return currentYearMonth(ref);
  }
}

String _$currentYearMonthHash() => r'6c3ba40037bffe22135ad00aad3a19fae65862c1';

@ProviderFor(selectedYearMonth)
final selectedYearMonthProvider = SelectedYearMonthProvider._();

final class SelectedYearMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<YearMonth?>,
          YearMonth?,
          Stream<YearMonth?>
        >
    with $FutureModifier<YearMonth?>, $StreamProvider<YearMonth?> {
  SelectedYearMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedYearMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedYearMonthHash();

  @$internal
  @override
  $StreamProviderElement<YearMonth?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<YearMonth?> create(Ref ref) {
    return selectedYearMonth(ref);
  }
}

String _$selectedYearMonthHash() => r'3af0cd51868fc7f06e2385d4d50553e4a222c2b1';

/// The months the user can switch to, newest first.

@ProviderFor(selectableMonths)
final selectableMonthsProvider = SelectableMonthsProvider._();

/// The months the user can switch to, newest first.

final class SelectableMonthsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<YearMonth>>,
          List<YearMonth>,
          Stream<List<YearMonth>>
        >
    with $FutureModifier<List<YearMonth>>, $StreamProvider<List<YearMonth>> {
  /// The months the user can switch to, newest first.
  SelectableMonthsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectableMonthsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectableMonthsHash();

  @$internal
  @override
  $StreamProviderElement<List<YearMonth>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<YearMonth>> create(Ref ref) {
    return selectableMonths(ref);
  }
}

String _$selectableMonthsHash() => r'910d6fd87fdd6048feee92095b43ce17d9e84d6a';

/// A month that started after the current one, to ask the user whether to
/// move on to it; null if there's none.

@ProviderFor(monthToOffer)
final monthToOfferProvider = MonthToOfferProvider._();

/// A month that started after the current one, to ask the user whether to
/// move on to it; null if there's none.

final class MonthToOfferProvider
    extends
        $FunctionalProvider<
          AsyncValue<YearMonth?>,
          YearMonth?,
          FutureOr<YearMonth?>
        >
    with $FutureModifier<YearMonth?>, $FutureProvider<YearMonth?> {
  /// A month that started after the current one, to ask the user whether to
  /// move on to it; null if there's none.
  MonthToOfferProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthToOfferProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthToOfferHash();

  @$internal
  @override
  $FutureProviderElement<YearMonth?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<YearMonth?> create(Ref ref) {
    return monthToOffer(ref);
  }
}

String _$monthToOfferHash() => r'317b3991a7e5b6c96aab357f4fbb71eddf0561c8';

@ProviderFor(offeredYearMonth)
final offeredYearMonthProvider = OfferedYearMonthProvider._();

final class OfferedYearMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<YearMonth?>,
          YearMonth?,
          Stream<YearMonth?>
        >
    with $FutureModifier<YearMonth?>, $StreamProvider<YearMonth?> {
  OfferedYearMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offeredYearMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offeredYearMonthHash();

  @$internal
  @override
  $StreamProviderElement<YearMonth?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<YearMonth?> create(Ref ref) {
    return offeredYearMonth(ref);
  }
}

String _$offeredYearMonthHash() => r'8997cf467a0853d315d12591099f01e726a31c43';

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

String _$currentMonthIdHash() => r'33ea39abb1240dbcb727ce5831cb3eb6b63fcc37';

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
