import 'dart:typed_data';

class Profile {
  const Profile({
    required this.displayName,
    this.bio,
    this.avatarHash,
    this.avatarBytes,
  });

  final String displayName;
  final String? bio;
  final String? avatarHash;
  final Uint8List? avatarBytes;

  Profile copyWith({
    String? displayName,
    String? bio,
    String? avatarHash,
    Uint8List? avatarBytes,
  }) {
    return Profile(
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarHash: avatarHash ?? this.avatarHash,
      avatarBytes: avatarBytes ?? this.avatarBytes,
    );
  }
}
