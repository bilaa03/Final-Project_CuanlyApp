import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final Color color;
  final DateTime date;

  AppNotification({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.color,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'desc': desc,
        'icon': icon.codePoint,
        'color': color.value,
        'date': date.toIso8601String(),
      };
}
