// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_requests_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$inboundRequestsStreamHash() =>
    r'f95ae13683ff3ba2f325d58d66ccb59d97890825';

/// Live pending inbound follow requests for the Friends tab banner.
///
/// Copied from [inboundRequestsStream].
@ProviderFor(inboundRequestsStream)
final inboundRequestsStreamProvider =
    AutoDisposeStreamProvider<List<FollowRequest>>.internal(
      inboundRequestsStream,
      name: r'inboundRequestsStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$inboundRequestsStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef InboundRequestsStreamRef =
    AutoDisposeStreamProviderRef<List<FollowRequest>>;
String _$outboundRequestsStreamHash() =>
    r'6473997036880c4329e1710e4ee70ea84cf62258';

/// Live outbound follow requests (any status) for the Friends tab "Pending"
/// rows.
///
/// Copied from [outboundRequestsStream].
@ProviderFor(outboundRequestsStream)
final outboundRequestsStreamProvider =
    AutoDisposeStreamProvider<List<FollowRequest>>.internal(
      outboundRequestsStream,
      name: r'outboundRequestsStreamProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$outboundRequestsStreamHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OutboundRequestsStreamRef =
    AutoDisposeStreamProviderRef<List<FollowRequest>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
