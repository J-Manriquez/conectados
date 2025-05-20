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
  
  // Método para convertir a Map para almacenamiento
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'packageName': packageName,
      'isSelected': isSelected,
      'color': color.value,
      'iconData': iconData.codePoint,
    };
  }
  
  // Método para crear desde Map
  factory AppInfo.fromMap(Map<String, dynamic> map) {
    return AppInfo(
      name: map['name'],
      packageName: map['packageName'],
      isSelected: map['isSelected'] ?? false,
      color: Color(map['color'] ?? Colors.blue.value),
      iconData: IconData(
        map['iconData'] ?? Icons.android.codePoint,
        fontFamily: 'MaterialIcons',
      ),
    );
  }
}