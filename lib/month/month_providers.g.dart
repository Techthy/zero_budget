// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'month_providers.dart';

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

/// The month after the current one, to ask the user whether to move on to
/// it, from [planAheadDays] before it starts; null if there's none, see
/// [newMonthToOffer].

@ProviderFor(monthToOffer)
final monthToOfferProvider = MonthToOfferProvider._();

/// The month after the current one, to ask the user whether to move on to
/// it, from [planAheadDays] before it starts; null if there's none, see
/// [newMonthToOffer].

final class MonthToOfferProvider
    extends
        $FunctionalProvider<
          AsyncValue<YearMonth?>,
          YearMonth?,
          FutureOr<YearMonth?>
        >
    with $FutureModifier<YearMonth?>, $FutureProvider<YearMonth?> {
  /// The month after the current one, to ask the user whether to move on to
  /// it, from [planAheadDays] before it starts; null if there's none, see
  /// [newMonthToOffer].
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

@ProviderFor(currentExpenses)
final currentExpensesProvider = CurrentExpensesProvider._();

final class CurrentExpensesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Expense>>,
          List<Expense>,
          Stream<List<Expense>>
        >
    with $FutureModifier<List<Expense>>, $StreamProvider<List<Expense>> {
  CurrentExpensesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentExpensesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentExpensesHash();

  @$internal
  @override
  $StreamProviderElement<List<Expense>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Expense>> create(Ref ref) {
    return currentExpenses(ref);
  }
}

String _$currentExpensesHash() => r'585c4cf8e149b0697627ad5d3814a6890ebc7476';

/// The current month's details, once all of them are loaded.

@ProviderFor(currentMonthDetails)
final currentMonthDetailsProvider = CurrentMonthDetailsProvider._();

/// The current month's details, once all of them are loaded.

final class CurrentMonthDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<MonthDetails>,
          AsyncValue<MonthDetails>,
          AsyncValue<MonthDetails>
        >
    with $Provider<AsyncValue<MonthDetails>> {
  /// The current month's details, once all of them are loaded.
  CurrentMonthDetailsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentMonthDetailsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentMonthDetailsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<MonthDetails>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<MonthDetails> create(Ref ref) {
    return currentMonthDetails(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<MonthDetails> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<MonthDetails>>(value),
    );
  }
}

String _$currentMonthDetailsHash() =>
    r'e58f81a25e620965f8484ccb7f3d72db813b47f1';

/// Any month's details, like one looked back at, once all of them are
/// loaded.

@ProviderFor(monthDetails)
final monthDetailsProvider = MonthDetailsFamily._();

/// Any month's details, like one looked back at, once all of them are
/// loaded.

final class MonthDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<MonthDetails>,
          AsyncValue<MonthDetails>,
          AsyncValue<MonthDetails>
        >
    with $Provider<AsyncValue<MonthDetails>> {
  /// Any month's details, like one looked back at, once all of them are
  /// loaded.
  MonthDetailsProvider._({
    required MonthDetailsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'monthDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthDetailsHash();

  @override
  String toString() {
    return r'monthDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<MonthDetails>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<MonthDetails> create(Ref ref) {
    final argument = this.argument as int;
    return monthDetails(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<MonthDetails> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<MonthDetails>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MonthDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthDetailsHash() => r'c032519e2b1d59b8d59291de2a5429a2dbbe4158';

/// Any month's details, like one looked back at, once all of them are
/// loaded.

final class MonthDetailsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<MonthDetails>, int> {
  MonthDetailsFamily._()
    : super(
        retry: null,
        name: r'monthDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Any month's details, like one looked back at, once all of them are
  /// loaded.

  MonthDetailsProvider call(int monthId) =>
      MonthDetailsProvider._(argument: monthId, from: this);

  @override
  String toString() => r'monthDetailsProvider';
}

@ProviderFor(_monthById)
final _monthByIdProvider = _MonthByIdFamily._();

final class _MonthByIdProvider
    extends $FunctionalProvider<AsyncValue<Month>, Month, Stream<Month>>
    with $FutureModifier<Month>, $StreamProvider<Month> {
  _MonthByIdProvider._({
    required _MonthByIdFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'_monthByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_monthByIdHash();

  @override
  String toString() {
    return r'_monthByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<Month> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Month> create(Ref ref) {
    final argument = this.argument as int;
    return _monthById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _MonthByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_monthByIdHash() => r'ecd911721704ba32fe2b0e81616ac1aa6e43846a';

final class _MonthByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Month>, int> {
  _MonthByIdFamily._()
    : super(
        retry: null,
        name: r'_monthByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _MonthByIdProvider call(int monthId) =>
      _MonthByIdProvider._(argument: monthId, from: this);

  @override
  String toString() => r'_monthByIdProvider';
}

@ProviderFor(_incomesOfMonth)
final _incomesOfMonthProvider = _IncomesOfMonthFamily._();

final class _IncomesOfMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Income>>,
          List<Income>,
          Stream<List<Income>>
        >
    with $FutureModifier<List<Income>>, $StreamProvider<List<Income>> {
  _IncomesOfMonthProvider._({
    required _IncomesOfMonthFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'_incomesOfMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_incomesOfMonthHash();

  @override
  String toString() {
    return r'_incomesOfMonthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Income>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Income>> create(Ref ref) {
    final argument = this.argument as int;
    return _incomesOfMonth(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _IncomesOfMonthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_incomesOfMonthHash() => r'c6bc6de8d63221dfadb201d74d768354fb986892';

final class _IncomesOfMonthFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Income>>, int> {
  _IncomesOfMonthFamily._()
    : super(
        retry: null,
        name: r'_incomesOfMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _IncomesOfMonthProvider call(int monthId) =>
      _IncomesOfMonthProvider._(argument: monthId, from: this);

  @override
  String toString() => r'_incomesOfMonthProvider';
}

@ProviderFor(_budgetsOfMonth)
final _budgetsOfMonthProvider = _BudgetsOfMonthFamily._();

final class _BudgetsOfMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Budget>>,
          List<Budget>,
          Stream<List<Budget>>
        >
    with $FutureModifier<List<Budget>>, $StreamProvider<List<Budget>> {
  _BudgetsOfMonthProvider._({
    required _BudgetsOfMonthFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'_budgetsOfMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_budgetsOfMonthHash();

  @override
  String toString() {
    return r'_budgetsOfMonthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Budget>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Budget>> create(Ref ref) {
    final argument = this.argument as int;
    return _budgetsOfMonth(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _BudgetsOfMonthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_budgetsOfMonthHash() => r'72830a353c15b696196b215a65f8bc3067e47b2b';

final class _BudgetsOfMonthFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Budget>>, int> {
  _BudgetsOfMonthFamily._()
    : super(
        retry: null,
        name: r'_budgetsOfMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _BudgetsOfMonthProvider call(int monthId) =>
      _BudgetsOfMonthProvider._(argument: monthId, from: this);

  @override
  String toString() => r'_budgetsOfMonthProvider';
}

@ProviderFor(_expensesOfMonth)
final _expensesOfMonthProvider = _ExpensesOfMonthFamily._();

final class _ExpensesOfMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Expense>>,
          List<Expense>,
          Stream<List<Expense>>
        >
    with $FutureModifier<List<Expense>>, $StreamProvider<List<Expense>> {
  _ExpensesOfMonthProvider._({
    required _ExpensesOfMonthFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'_expensesOfMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$_expensesOfMonthHash();

  @override
  String toString() {
    return r'_expensesOfMonthProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<Expense>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Expense>> create(Ref ref) {
    final argument = this.argument as int;
    return _expensesOfMonth(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is _ExpensesOfMonthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$_expensesOfMonthHash() => r'87642a5ec5b9c656db55fc455c349b7806a18396';

final class _ExpensesOfMonthFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Expense>>, int> {
  _ExpensesOfMonthFamily._()
    : super(
        retry: null,
        name: r'_expensesOfMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  _ExpensesOfMonthProvider call(int monthId) =>
      _ExpensesOfMonthProvider._(argument: monthId, from: this);

  @override
  String toString() => r'_expensesOfMonthProvider';
}
