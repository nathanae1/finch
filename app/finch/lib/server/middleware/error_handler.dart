import 'dart:async';
import 'dart:convert';

import 'package:shelf/shelf.dart';

/// Catches exceptions thrown by inner handlers and returns sanitized
/// responses. `FormatException` / `ArgumentError` map to 400; anything
/// else maps to 500. The response body never includes `e.toString()` or
/// a stack trace.
Middleware errorHandlerMiddleware() {
  return (Handler inner) {
    return (Request request) async {
      try {
        return await inner(request);
      } on FormatException {
        return Response(400, body: 'bad request');
      } on ArgumentError {
        return Response(400, body: 'bad request');
      } catch (_) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'internal error'}),
          headers: const {'content-type': 'application/json; charset=utf-8'},
        );
      }
    };
  };
}

/// Caps POST/PUT request bodies at [maxBytes]. If the inbound
/// `Content-Length` is set and over the cap, returns 413 immediately
/// without reading the body. If `Content-Length` is absent, wraps the
/// body stream with a running counter that converts an over-cap read
/// into a 413 response.
Middleware bodySizeLimitMiddleware({required int maxBytes}) {
  return (Handler inner) {
    return (Request request) async {
      if (request.method != 'POST' && request.method != 'PUT') {
        return inner(request);
      }
      final contentLength = request.contentLength;
      if (contentLength != null && contentLength > maxBytes) {
        return Response(413, body: 'payload too large');
      }
      final wrapped = request.change(
        body: _cappedStream(request.read(), maxBytes),
      );
      try {
        return await inner(wrapped);
      } on _BodyTooLarge {
        return Response(413, body: 'payload too large');
      }
    };
  };
}

Stream<List<int>> _cappedStream(Stream<List<int>> source, int maxBytes) async* {
  var total = 0;
  await for (final chunk in source) {
    total += chunk.length;
    if (total > maxBytes) {
      throw const _BodyTooLarge();
    }
    yield chunk;
  }
}

class _BodyTooLarge implements Exception {
  const _BodyTooLarge();
}
