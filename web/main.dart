// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:html';

import '../lib/order.dart';

final form = querySelector('#order-form') as FormElement;
final itemInput = querySelector('#item') as InputElement;
final itemNameInput = querySelector('#item-name') as InputElement;
final priceInput = querySelector('#price') as InputElement;
final quantityInput = querySelector('#quantity') as InputElement;
final currencySelect = querySelector('#currency') as SelectElement;
final searchInput = querySelector('#search') as InputElement;
final tableBody = querySelector('#orders-body') as TableSectionElement;
final emptyState = querySelector('#empty-state') as DivElement;
final resultCount = querySelector('#result-count') as HtmlElement;
final totalQuantity = querySelector('#total-quantity') as HtmlElement;
final totalValue = querySelector('#total-value') as HtmlElement;
final submitButton = querySelector('#submit-button') as ButtonElement;
final resetButton = querySelector('#reset-button') as ButtonElement;
final toast = querySelector('#toast') as DivElement;

Timer? searchTimer;

Future<void> main() async {
  form.onSubmit.listen((event) {
    event.preventDefault();
    insertOrder();
  });
  resetButton.onClick.listen((_) => resetForm());
  searchInput.onInput.listen((_) {
    searchTimer?.cancel();
    searchTimer = Timer(const Duration(milliseconds: 250), loadOrders);
  });

  await loadOrders();
}

Future<void> loadOrders() async {
  setLoadingRows();
  try {
    final keyword = searchInput.value?.trim() ?? '';
    final uri = Uri(
      path: '/api/orders',
      queryParameters: keyword.isEmpty ? null : {'search': keyword},
    );
    final response = await HttpRequest.request(uri.toString());
    final payload = jsonDecode(response.responseText ?? '{}') as Map<String, dynamic>;
    final rawOrders = payload['orders'] as List<dynamic>? ?? [];
    final orders = rawOrders
        .map((entry) => Order.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();
    renderOrders(orders);
  } catch (error) {
    window.console.error('loadOrders failed: $error');
    tableBody.children.clear();
    emptyState.classes.remove('hidden');
    showToast('Cannot load orders. Check that the Dart server is running.', true);
  }
}

Future<void> insertOrder() async {
  final price = double.tryParse(priceInput.value ?? '');
  final quantity = int.tryParse(quantityInput.value ?? '');
  if (price == null || price < 0 || quantity == null || quantity <= 0) {
    showToast('Please enter a valid price and quantity.', true);
    return;
  }

  final order = Order(
    item: itemInput.value!.trim(),
    itemName: itemNameInput.value!.trim(),
    price: price,
    currency: currencySelect.value ?? 'USD',
    quantity: quantity,
  );

  setSubmitting(true);
  try {
    final response = await HttpRequest.request(
      '/api/orders',
      method: 'POST',
      requestHeaders: {'Content-Type': 'application/json'},
      sendData: jsonEncode(order.toJson()),
    );
    final payload = jsonDecode(response.responseText ?? '{}') as Map<String, dynamic>;
    showToast(payload['message']?.toString() ?? 'Order inserted successfully.');
    resetForm();
    searchInput.value = '';
    await loadOrders();
  } on ProgressEvent catch (_) {
    showToast('Could not insert the order. The item code may already exist.', true);
  } catch (_) {
    showToast('Could not insert the order.', true);
  } finally {
    setSubmitting(false);
  }
}

void renderOrders(List<Order> orders) {
  tableBody.children.clear();
  emptyState.classes.toggle('hidden', orders.isNotEmpty);
  resultCount.text = '${orders.length}';
  totalQuantity.text = '${orders.fold<int>(0, (sum, order) => sum + order.quantity)}';
  final value = orders.fold<double>(
    0,
    (sum, order) => sum + order.price * order.quantity,
  );
  totalValue.text = formatPrice(value);

  for (var index = 0; index < orders.length; index++) {
    final order = orders[index];
    final row = TableRowElement();
    row.children.add(TableCellElement()..text = '${index + 1}');
    row.children.add(TableCellElement()
      ..append(SpanElement()
        ..className = 'item-code'
        ..text = order.item));
    row.children.add(TableCellElement()
      ..append(SpanElement()
        ..className = 'item-name-cell'
        ..text = order.itemName));
    row.children.add(TableCellElement()..text = '${order.quantity}');
    row.children.add(TableCellElement()..text = formatPrice(order.price));
    row.children.add(TableCellElement()
      ..append(SpanElement()
        ..className = 'currency-badge'
        ..text = order.currency));
    tableBody.children.add(row);
  }
}

void setLoadingRows() {
  emptyState.classes.add('hidden');
  tableBody.children
    ..clear()
    ..add(TableRowElement()
      ..children.add(TableCellElement()
        ..colSpan = 6
        ..className = 'loading-cell'
        ..text = 'Loading orders...'));
}

void resetForm() {
  form.reset();
  currencySelect.value = 'USD';
  quantityInput.value = '1';
  itemInput.focus();
}

void setSubmitting(bool isSubmitting) {
  submitButton.disabled = isSubmitting;
  submitButton.text = isSubmitting ? 'Saving...' : 'Add order';
}

void showToast(String message, [bool isError = false]) {
  toast
    ..text = message
    ..classes.toggle('error', isError)
    ..classes.add('show');
  Timer(const Duration(seconds: 3), () => toast.classes.remove('show'));
}

String formatPrice(double value) {
  final plain = value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(2);
  final parts = plain.split('.');
  final reversed = parts.first.split('').reversed.toList();
  final groups = <String>[];
  for (var index = 0; index < reversed.length; index += 3) {
    groups.add(reversed.skip(index).take(3).toList().reversed.join());
  }
  final whole = groups.reversed.join(',');
  return parts.length == 2 ? '$whole.${parts[1]}' : whole;
}
