// E-Wallet data model
class WalletItem {
  final String name;
  double balance;
  final String cardNumber;
  final String designType; // 'blue', 'teal', 'purple', 'slate'

  WalletItem({
    required this.name,
    required this.balance,
    required this.cardNumber,
    required this.designType,
  });
}
