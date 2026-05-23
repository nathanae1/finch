// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_requests_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Live pending inbound follow requests for the Friends tab banner.

@ProviderFor(inboundRequestsStream)
final inboundRequestsStreamProvider = InboundRequestsStreamProvider._();

/// Live pending inbound follow requests for the Friends tab banner.

final class InboundRequestsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FollowRequest>>,
          List<FollowRequest>,
          Stream<List<FollowRequest>>
        >
    with
        $FutureModifier<List<FollowRequest>>,
        $StreamProvider<List<FollowRequest>> {
  /// Live pending inbound follow requests for the Friends tab banner.
  InboundRequestsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboundRequestsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboundRequestsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<FollowRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<FollowRequest>> create(Ref ref) {
    return inboundRequestsStream(ref);
  }
}

String _$inboundRequestsStreamHash() =>
    r'52acf15cba04c40351050400574a8423203bb23f';

/// Live actioned inbound rows (status != 'pending') — peers who scanned
/// our QR and whom we've already accepted (or are still trying to deliver
/// the accept to). The friends list shows these as "Follows you" rows
/// when we don't follow them back yet.

@ProviderFor(inboundFollowersStream)
final inboundFollowersStreamProvider = InboundFollowersStreamProvider._();

/// Live actioned inbound rows (status != 'pending') — peers who scanned
/// our QR and whom we've already accepted (or are still trying to deliver
/// the accept to). The friends list shows these as "Follows you" rows
/// when we don't follow them back yet.

final class InboundFollowersStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FollowRequest>>,
          List<FollowRequest>,
          Stream<List<FollowRequest>>
        >
    with
        $FutureModifier<List<FollowRequest>>,
        $StreamProvider<List<FollowRequest>> {
  /// Live actioned inbound rows (status != 'pending') — peers who scanned
  /// our QR and whom we've already accepted (or are still trying to deliver
  /// the accept to). The friends list shows these as "Follows you" rows
  /// when we don't follow them back yet.
  InboundFollowersStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboundFollowersStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboundFollowersStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<FollowRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<FollowRequest>> create(Ref ref) {
    return inboundFollowersStream(ref);
  }
}

String _$inboundFollowersStreamHash() =>
    r'9556f849d3e50a6b6dc91ebbec25904ee4a6cdb9';

/// Live outbound follow requests (any status) for the Friends tab "Pending"
/// rows.

@ProviderFor(outboundRequestsStream)
final outboundRequestsStreamProvider = OutboundRequestsStreamProvider._();

/// Live outbound follow requests (any status) for the Friends tab "Pending"
/// rows.

final class OutboundRequestsStreamProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FollowRequest>>,
          List<FollowRequest>,
          Stream<List<FollowRequest>>
        >
    with
        $FutureModifier<List<FollowRequest>>,
        $StreamProvider<List<FollowRequest>> {
  /// Live outbound follow requests (any status) for the Friends tab "Pending"
  /// rows.
  OutboundRequestsStreamProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'outboundRequestsStreamProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$outboundRequestsStreamHash();

  @$internal
  @override
  $StreamProviderElement<List<FollowRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<FollowRequest>> create(Ref ref) {
    return outboundRequestsStream(ref);
  }
}

String _$outboundRequestsStreamHash() =>
    r'e0c9ff9495ff84744d06cf9ff43d6f1db1b26d21';
