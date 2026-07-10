class SavingGoal {
  final String title;
  final double current;
  final double target;
  final String colorHex;

  SavingGoal({
    required this.title,
    required this.current,
    required this.target,
    required this.colorHex,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'current': current,
        'target': target,
        'colorHex': colorHex,
      };

  factory SavingGoal.fromJson(Map<String, dynamic> json) => SavingGoal(
        title: json['title'] as String,
        current: (json['current'] as num).toDouble(),
        target: (json['target'] as num).toDouble(),
        colorHex: json['colorHex'] as String,
      );
}
