// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deep_link_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(deepLinkHandler)
final deepLinkHandlerProvider = DeepLinkHandlerProvider._();

final class DeepLinkHandlerProvider
    extends
        $FunctionalProvider<DeepLinkHandler, DeepLinkHandler, DeepLinkHandler>
    with $Provider<DeepLinkHandler> {
  DeepLinkHandlerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deepLinkHandlerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deepLinkHandlerHash();

  @$internal
  @override
  $ProviderElement<DeepLinkHandler> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DeepLinkHandler create(Ref ref) {
    return deepLinkHandler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DeepLinkHandler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DeepLinkHandler>(value),
    );
  }
}

String _$deepLinkHandlerHash() => r'77e41ba746277af3f97b3c9635a5f33732423711';

/// Stream of inbound deep-link invites for the router-level listener to
/// surface as a confirm sheet.

@ProviderFor(deepLinkInvites)
final deepLinkInvitesProvider = DeepLinkInvitesProvider._();

/// Stream of inbound deep-link invites for the router-level listener to
/// surface as a confirm sheet.

final class DeepLinkInvitesProvider
    extends
        $FunctionalProvider<
          AsyncValue<ParsedInvite>,
          ParsedInvite,
          Stream<ParsedInvite>
        >
    with $FutureModifier<ParsedInvite>, $StreamProvider<ParsedInvite> {
  /// Stream of inbound deep-link invites for the router-level listener to
  /// surface as a confirm sheet.
  DeepLinkInvitesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'deepLinkInvitesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$deepLinkInvitesHash();

  @$internal
  @override
  $StreamProviderElement<ParsedInvite> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<ParsedInvite> create(Ref ref) {
    return deepLinkInvites(ref);
  }
}

String _$deepLinkInvitesHash() => r'f106cc5e5373de28ce51c7e21a15cbf0268598db';
