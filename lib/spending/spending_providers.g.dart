// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'spending_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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
