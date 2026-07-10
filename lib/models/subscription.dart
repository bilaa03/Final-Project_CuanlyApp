class SubscriptionItem {
  final String name;
  final double price;
  final String status;
  final String colorHex;

  SubscriptionItem({
    required this.name,
    required this.price,
    required this.status,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'status': status,
        'colorHex': colorHex,
      };

  factory SubscriptionItem.fromJson(Map<String, dynamic> json) => SubscriptionItem(
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        status: json['status'] as String,
        colorHex: json['colorHex'] as String,
      );
}
