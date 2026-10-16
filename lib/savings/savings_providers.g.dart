// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'savings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Progress towards the savings goal in the period of the month the user
/// works in.

@ProviderFor(savingsProgress)
final savingsProgressProvider = SavingsProgressProvider._();

/// Progress towards the savings goal in the period of the month the user
/// works in.

final class SavingsProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<SavingsProgress>,
          SavingsProgress,
          Stream<SavingsProgress>
        >
    with $FutureModifier<SavingsProgress>, $StreamProvider<SavingsProgress> {
  /// Progress towards the savings goal in the period of the month the user
  /// works in.
  SavingsProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savingsProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savingsProgressHash();

  @$internal
  @override
  $StreamProviderElement<SavingsProgress> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<SavingsProgress> create(Ref ref) {
    return savingsProgress(ref);
  }
}

String _$savingsProgressHash() => r'4a110c2cc7bd16037ad6910fa1a7c3e5eda8003c';
