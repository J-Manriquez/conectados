import 'package:flutter/material.dart';

class AppInfo {
  final String name;
  final String packageName;
  bool isSelected;
  final Color color;
  final IconData iconData;
  
  AppInfo({
    required this.name,
    required this.packageName,
    required this.isSelected,
    required this.color,
    required this.iconData,
  });
}