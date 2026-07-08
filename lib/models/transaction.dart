// Transaction item data model
class TransactionItem {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final double amount;
  final bool isExpense;
  final String wallet;

  TransactionItem({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.isExpense,
    required this.wallet,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'date': date.toIso8601String(),
        'amount': amount,
        'isExpense': isExpense,
        'wallet': wallet,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num).toDouble(),
        isExpense: json['isExpense'] as bool,
        wallet: json['wallet'] as String,
      );
}
