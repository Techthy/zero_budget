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
