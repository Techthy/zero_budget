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
