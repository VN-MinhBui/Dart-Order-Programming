import 'dart:convert';
import 'dart:io';

import '../lib/order.dart';

final Directory projectDirectory = File.fromUri(Platform.script).parent.parent;
final File orderFile = File('${projectDirectory.path}${Platform.pathSeparator}data${Platform.pathSeparator}order.json');
final Directory webDirectory = Directory('${projectDirectory.path}${Platform.pathSeparator}web');

Future<void> main(List<String> arguments) async {
  final port = arguments.isNotEmpty ? int.tryParse(arguments.first) ?? 8080 : 8080;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);

  stdout.writeln('My Order is running at http://localhost:$port');
  stdout.writeln('Press Ctrl+C to stop.');

  await for (final request in server) {
    try {
      await handleRequest(request);
    } catch (error, stackTrace) {
      stderr.writeln('$error\n$stackTrace');
      try {
        await sendJson(request.response, HttpStatus.internalServerError, {
          'message': 'Unexpected server error.',
        });
      } catch (_) {}
    }
  }
}

Future<void> handleRequest(HttpRequest request) async {
  final path = request.uri.path;

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  if (path == '/api/orders') {
    if (request.method == 'GET') {
      await getOrders(request);
      return;
    }
    if (request.method == 'POST') {
      await insertOrder(request);
      return;
    }
    await sendJson(request.response, HttpStatus.methodNotAllowed, {
      'message': 'Method not allowed.',
    });
    return;
  }

  if (request.method != 'GET') {
    await sendJson(request.response, HttpStatus.methodNotAllowed, {
      'message': 'Method not allowed.',
    });
    return;
  }

  await serveStaticFile(request);
}

Future<List<Order>> readOrders() async {
  if (!await orderFile.exists()) return [];
  final content = await orderFile.readAsString();
  final decoded = jsonDecode(content);
  if (decoded is! List) {
    throw const FormatException('order.json must contain a JSON list.');
  }
  return decoded
      .map((entry) => Order.fromJson(Map<String, dynamic>.from(entry as Map)))
      .toList();
}

Future<void> writeOrders(List<Order> orders) async {
  final encoder = const JsonEncoder.withIndent('  ');
  await orderFile.writeAsString('${encoder.convert(orders.map((order) => order.toJson()).toList())}\n');
}

Future<void> getOrders(HttpRequest request) async {
  final keyword = request.uri.queryParameters['search']?.trim() ?? '';
  final orders = await readOrders();
  final result = keyword.isEmpty
      ? orders
      : orders.where((order) => order.matchesItemName(keyword)).toList();

  await sendJson(request.response, HttpStatus.ok, {
    'orders': result.map((order) => order.toJson()).toList(),
    'count': result.length,
  });
}

Future<void> insertOrder(HttpRequest request) async {
  try {
    final body = await utf8.decoder.bind(request).join();
    final decoded = jsonDecode(body);
    if (decoded is! Map) {
      throw const FormatException('Request body must be a JSON object.');
    }

    final order = Order.fromJson(Map<String, dynamic>.from(decoded));
    final orders = await readOrders();
    final isDuplicate = orders.any(
      (existing) => existing.item.toLowerCase() == order.item.toLowerCase(),
    );
    if (isDuplicate) {
      await sendJson(request.response, HttpStatus.conflict, {
        'message': 'Item code already exists.',
      });
      return;
    }

    orders.add(order);
    await writeOrders(orders);
    await sendJson(request.response, HttpStatus.created, {
      'message': 'Order inserted successfully.',
      'order': order.toJson(),
    });
  } on FormatException catch (error) {
    await sendJson(request.response, HttpStatus.badRequest, {
      'message': error.message,
    });
  }
}

Future<void> serveStaticFile(HttpRequest request) async {
  final files = <String, String>{
    '/': 'index.html',
    '/index.html': 'index.html',
    '/styles.css': 'styles.css',
    '/main.dart.js': 'main.dart.js',
  };
  final fileName = files[request.uri.path];
  if (fileName == null) {
    await sendJson(request.response, HttpStatus.notFound, {
      'message': 'Not found.',
    });
    return;
  }

  final file = File('${webDirectory.path}${Platform.pathSeparator}$fileName');
  if (!await file.exists()) {
    await sendJson(request.response, HttpStatus.notFound, {
      'message': '$fileName has not been built yet.',
    });
    return;
  }

  request.response.headers.contentType = switch (fileName.split('.').last) {
    'html' => ContentType.html,
    'css' => ContentType('text', 'css', charset: 'utf-8'),
    'js' => ContentType('text', 'javascript', charset: 'utf-8'),
    _ => ContentType.binary,
  };
  await request.response.addStream(file.openRead());
  await request.response.close();
}

Future<void> sendJson(
  HttpResponse response,
  int statusCode,
  Object body,
) async {
  response.statusCode = statusCode;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}
