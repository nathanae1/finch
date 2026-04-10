enum EventKind {
  post(1),
  profile(2),
  followList(3),
  comment(4),
  like(5),
  delete(6);

  const EventKind(this.value);
  final int value;

  static EventKind fromValue(int value) {
    return EventKind.values.firstWhere(
      (kind) => kind.value == value,
      orElse: () => throw ArgumentError('Unknown EventKind value: $value'),
    );
  }
}
