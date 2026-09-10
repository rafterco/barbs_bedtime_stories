import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String icon; // emoji
  final String color; // hex string
  final int sortOrder;

  Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.sortOrder,
  });

  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Category(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      icon: (data['icon'] ?? '').toString(),
      color: (data['color'] ?? '#000000').toString(),
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'icon': icon,
      'color': color,
      'sortOrder': sortOrder,
    };
  }
}
