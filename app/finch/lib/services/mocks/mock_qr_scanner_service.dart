import 'dart:async';

import '../qr_scanner_service.dart';

/// In-memory mock used by widget tests. Tests `add` payloads to the
/// controller to simulate scans; the widget under test reads them via
/// [scans].
class MockQrScannerService implements QrScannerService {
  MockQrScannerService();

  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  bool started = false;
  bool stopped = false;

  void emit(String payload) => _controller.add(payload);

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Stream<String> get scans => _controller.stream;

  @override
  String get platformViewType => 'dev.finch.qr_scanner_view.mock';

  Future<void> dispose() => _controller.close();
}
