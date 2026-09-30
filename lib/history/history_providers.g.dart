// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every month except the current one, newest first.

@ProviderFor(pastMonths)
final pastMonthsProvider = PastMonthsProvider._();

/// Every month except the current one, newest first.

final class PastMonthsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MonthSummary>>,
          List<MonthSummary>,
          Stream<List<MonthSummary>>
        >
    with
        $FutureModifier<List<MonthSummary>>,
        $StreamProvider<List<MonthSummary>> {
  /// Every month except the current one, newest first.
  PastMonthsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pastMonthsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pastMonthsHash();

  @$internal
  @override
  $StreamProviderElement<List<MonthSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<MonthSummary>> create(Ref ref) {
    return pastMonths(ref);
  }
}

String _$pastMonthsHash() => r'be92159cb16e3474e61e07ed1e152a072007cbea';

@ProviderFor(monthById)
final monthByIdProvider = MonthByIdFamily._();

final class MonthByIdProvider
    extends $FunctionalProvider<AsyncValue<Month>, Month, Stream<Month>>
    with $FutureModifier<Month>, $StreamProvider<Month> {
  MonthByIdProvider._({
    required MonthByIdFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'monthByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthByIdHash();

  @override
  String toString() {
    return r'monthByIdProvider'
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
    return monthById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthByIdHash() => r'20cea98570b70d9da26676a0df108e34e2508353';

final class MonthByIdFamily extends $Family
    with $FunctionalFamilyOverride<Stream<Month>, int> {
  MonthByIdFamily._()
    : super(
        retry: null,
        name: r'monthByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MonthByIdProvider call(int monthId) =>
      MonthByIdProvider._(argument: monthId, from: this);

  @override
  String toString() => r'monthByIdProvider';
}

@ProviderFor(incomesForMonth)
final incomesForMonthProvider = IncomesForMonthFamily._();

final class IncomesForMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Income>>,
          List<Income>,
          Stream<List<Income>>
        >
    with $FutureModifier<List<Income>>, $StreamProvider<List<Income>> {
  IncomesForMonthProvider._({
    required IncomesForMonthFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'incomesForMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$incomesForMonthHash();

  @override
  String toString() {
    return r'incomesForMonthProvider'
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
    return incomesForMonth(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is IncomesForMonthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$incomesForMonthHash() => r'3a8091e5372a91c307eaa6357517586321d114b6';

final class IncomesForMonthFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Income>>, int> {
  IncomesForMonthFamily._()
    : super(
        retry: null,
        name: r'incomesForMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  IncomesForMonthProvider call(int monthId) =>
      IncomesForMonthProvider._(argument: monthId, from: this);

  @override
  String toString() => r'incomesForMonthProvider';
}

@ProviderFor(budgetsForMonth)
final budgetsForMonthProvider = BudgetsForMonthFamily._();

final class BudgetsForMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Budget>>,
          List<Budget>,
          Stream<List<Budget>>
        >
    with $FutureModifier<List<Budget>>, $StreamProvider<List<Budget>> {
  BudgetsForMonthProvider._({
    required BudgetsForMonthFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'budgetsForMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$budgetsForMonthHash();

  @override
  String toString() {
    return r'budgetsForMonthProvider'
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
    return budgetsForMonth(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BudgetsForMonthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$budgetsForMonthHash() => r'f976b75e8626474b17239c8cd6c95bf210da93a7';

final class BudgetsForMonthFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Budget>>, int> {
  BudgetsForMonthFamily._()
    : super(
        retry: null,
        name: r'budgetsForMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BudgetsForMonthProvider call(int monthId) =>
      BudgetsForMonthProvider._(argument: monthId, from: this);

  @override
  String toString() => r'budgetsForMonthProvider';
}

@ProviderFor(expensesForMonth)
final expensesForMonthProvider = ExpensesForMonthFamily._();

final class ExpensesForMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Expense>>,
          List<Expense>,
          Stream<List<Expense>>
        >
    with $FutureModifier<List<Expense>>, $StreamProvider<List<Expense>> {
  ExpensesForMonthProvider._({
    required ExpensesForMonthFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'expensesForMonthProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$expensesForMonthHash();

  @override
  String toString() {
    return r'expensesForMonthProvider'
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
    return expensesForMonth(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ExpensesForMonthProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$expensesForMonthHash() => r'42feeace6c1833c7f3cdaf8a78e98641d2f3c2a4';

final class ExpensesForMonthFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<Expense>>, int> {
  ExpensesForMonthFamily._()
    : super(
        retry: null,
        name: r'expensesForMonthProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ExpensesForMonthProvider call(int monthId) =>
      ExpensesForMonthProvider._(argument: monthId, from: this);

  @override
  String toString() => r'expensesForMonthProvider';
}
