import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_paths_provider.g.dart';

/// The platform's application-support directory. Finch writes media blobs,
/// indexes, and other non-user-visible state here — not into the user's
/// Documents dir (which is surfaced in the iOS Files app / iTunes file
/// sharing).
///
/// Tests override this with a tmp dir.
@riverpod
Future<Directory> appSupportDirectory(AppSupportDirectoryRef ref) =>
    getApplicationSupportDirectory();
