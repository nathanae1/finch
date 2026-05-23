/// Represents who content is encrypted for.
///
/// v1 has one variant: [broadcast] — encrypt with feed key, key shared
/// pairwise with each follower.
///
/// Future: [group] for MLS-based group encryption.
enum Audience {
  /// Encrypt once with feed key. Feed key is shared pairwise with each follower.
  broadcast,
}
