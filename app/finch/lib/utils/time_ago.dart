/// Compact relative-time formatting for post cards and friend rows. The
/// codebase normalizes on Unix seconds — `nowUnixSeconds` from the `Clock`
/// service is the production source. Tests pass an explicit `now` so they
/// don't depend on real time.
String timeAgo(int unixSeconds, {required int nowUnixSeconds}) {
  final delta = nowUnixSeconds - unixSeconds;
  if (delta < 60) return 'just now';
  if (delta < 3600) {
    final m = delta ~/ 60;
    return '${m}m';
  }
  if (delta < 86400) {
    final h = delta ~/ 3600;
    return '${h}h';
  }
  if (delta < 86400 * 2) return 'yesterday';
  if (delta < 86400 * 7) {
    final d = delta ~/ 86400;
    return '${d}d';
  }
  if (delta < 86400 * 30) {
    final w = delta ~/ (86400 * 7);
    return '${w}w';
  }
  if (delta < 86400 * 365) {
    final mo = delta ~/ (86400 * 30);
    return '${mo}mo';
  }
  final y = delta ~/ (86400 * 365);
  return '${y}y';
}
