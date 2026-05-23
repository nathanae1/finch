import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_paths_provider.g.dart';

/// The platform's application-support directory. Starling writes media blobs,
/// indexes, and other non-user-visible state here — not into the user's
/// Documents dir (which is surfaced in the iOS Files app / iTunes file
/// sharing).
///
/// Tests override this with a tmp dir.
@riverpod
Future<Directory> appSupportDirectory(Ref ref) =>
    getApplicationSupportDirectory();

/// User-visible export drop. The bundle is written here and then handed to
/// the OS share sheet; the user picks the final destination (Files, iCloud,
/// AirDrop, etc.). Cleared opportunistically — no retention policy yet.
@riverpod
Future<Directory> exportDirectory(Ref ref) async {
  final support = await ref.watch(appSupportDirectoryProvider.future);
  final dir = Directory('${support.path}/exports');
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  return dir;
}
