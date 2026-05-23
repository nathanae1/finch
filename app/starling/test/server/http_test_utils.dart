import 'dart:io';
import 'dart:typed_data';

class HttpResponseSnapshot {
  HttpResponseSnapshot({
    required this.statusCode,
    required this.headers,
    required this.body,
  });

  final int statusCode;
  final Map<String, List<String>> headers;
  final Uint8List body;
}

Future<HttpResponseSnapshot> fetchHttp(
  int port,
  String path, {
  String method = 'GET',
  List<int>? body,
  Map<String, String> headers = const {},
  Duration timeout = const Duration(seconds: 5),
}) async {
  final client = HttpClient();
  try {
    final uri = Uri.parse('http://127.0.0.1:$port$path');
    final req = await client.openUrl(method, uri).timeout(timeout);
    headers.forEach(req.headers.add);
    if (body != null) {
      req.headers.contentLength = body.length;
      req.add(body);
    }
    final res = await req.close().timeout(timeout);
    final builder = BytesBuilder(copy: false);
    await for (final chunk in res) {
      builder.add(chunk);
    }
    final headerMap = <String, List<String>>{};
    res.headers.forEach((name, values) => headerMap[name] = values);
    return HttpResponseSnapshot(
      statusCode: res.statusCode,
      headers: headerMap,
      body: builder.toBytes(),
    );
  } finally {
    client.close(force: true);
  }
}
