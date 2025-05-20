import 'package:flutter/material.dart';

class PermissionItem extends StatelessWidget {
  final String title;
  final bool isGranted;
  
  const PermissionItem({
    super.key,
    required this.title,
    required this.isGranted,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isGranted ? Icons.check_circle : Icons.error,
          color: isGranted ? Colors.green : Colors.red,
        ),
        const SizedBox(width: 8),
        Text(title),
        const Spacer(),
        Text(
          isGranted ? 'Concedido' : 'No concedido',
          style: TextStyle(
            color: isGranted ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}