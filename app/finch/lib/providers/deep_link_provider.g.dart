// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deep_link_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$deepLinkHandlerHash() => r'aa60af7e392a73e87ba582ae4b1aa55abc021c26';

/// See also [deepLinkHandler].
@ProviderFor(deepLinkHandler)
final deepLinkHandlerProvider = AutoDisposeProvider<DeepLinkHandler>.internal(
  deepLinkHandler,
  name: r'deepLinkHandlerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deepLinkHandlerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeepLinkHandlerRef = AutoDisposeProviderRef<DeepLinkHandler>;
String _$deepLinkInvitesHash() => r'a79d344e811c29abeaac828b02ff789642adecda';

/// Stream of inbound deep-link invites for the router-level listener to
/// surface as a confirm sheet.
///
/// Copied from [deepLinkInvites].
@ProviderFor(deepLinkInvites)
final deepLinkInvitesProvider =
    AutoDisposeStreamProvider<ParsedInvite>.internal(
      deepLinkInvites,
      name: r'deepLinkInvitesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$deepLinkInvitesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeepLinkInvitesRef = AutoDisposeStreamProviderRef<ParsedInvite>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
