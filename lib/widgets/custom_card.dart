import 'package:flutter/material.dart';

class CustomStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const CustomStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

class CustomDeviceCard extends StatelessWidget {
  final String name;
  final String storage;
  final String status;

  const CustomDeviceCard({
    super.key,
    required this.name,
    required this.storage,
    required this.status,
  });

  Color getStatusColor() {
    switch (status) {
      case "READY":
        return Colors.green;
      case "COMPLETE":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            const Spacer(),
            Text("Storage: $storage",
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 6),
            Text("Status: $status",
                style: TextStyle(
                    color: getStatusColor(), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
