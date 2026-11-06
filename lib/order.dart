class Order {
  const Order({
    required this.item,
    required this.itemName,
    required this.price,
    required this.currency,
    required this.quantity,
  });

  final String item;
  final String itemName;
  final double price;
  final String currency;
  final int quantity;

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItem = json['Item'];
    final rawItemName = json['ItemName'];
    final rawPrice = json['Price'];
    final rawCurrency = json['Currency'];
    final rawQuantity = json['Quantity'];

    if (rawItem is! String || rawItem.trim().isEmpty) {
      throw const FormatException('Item is required.');
    }
    if (rawItemName is! String || rawItemName.trim().isEmpty) {
      throw const FormatException('ItemName is required.');
    }
    if (rawPrice is! num || rawPrice < 0) {
      throw const FormatException('Price must be a non-negative number.');
    }
    if (rawCurrency is! String || rawCurrency.trim().isEmpty) {
      throw const FormatException('Currency is required.');
    }
    if (rawQuantity is! num || rawQuantity <= 0 || rawQuantity % 1 != 0) {
      throw const FormatException('Quantity must be a positive integer.');
    }

    return Order(
      item: rawItem.trim(),
      itemName: rawItemName.trim(),
      price: rawPrice.toDouble(),
      currency: rawCurrency.trim().toUpperCase(),
      quantity: rawQuantity.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'Item': item,
        'ItemName': itemName,
        'Price': price % 1 == 0 ? price.toInt() : price,
        'Currency': currency,
        'Quantity': quantity,
      };

  bool matchesItemName(String keyword) =>
      itemName.toLowerCase().contains(keyword.trim().toLowerCase());
}
