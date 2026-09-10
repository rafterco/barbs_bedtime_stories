import 'package:cloud_firestore/cloud_firestore.dart';

class Testimonial {
  final String id;
  final String author;
  final String role;
  final String text;
  final int rating; // 1 to 5
  final String avatar; // emoji or image URL
  final bool isPublished;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Testimonial({
    required this.id,
    required this.author,
    required this.role,
    required this.text,
    this.rating = 5,
    this.avatar = '🌙',
    this.isPublished = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Testimonial.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Testimonial.fromMap(data, id: doc.id);
  }

  factory Testimonial.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return Testimonial(
      id: id.isNotEmpty ? id : (data['id'] as String? ?? ''),
      author: data['author'] as String? ?? data['name'] as String? ?? 'Kind Listener',
      role: data['role'] as String? ?? data['location'] as String? ?? 'Bedtime Listener',
      text: data['text'] as String? ?? data['quote'] as String? ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 5,
      avatar: data['avatar'] as String? ?? '🌙',
      isPublished: data['isPublished'] as bool? ?? true,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'author': author,
      'role': role,
      'text': text,
      'rating': rating,
      'avatar': avatar,
      'isPublished': isPublished,
      'sortOrder': sortOrder,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static List<Testimonial> get defaultTestimonials => const [
    Testimonial(
      id: 'default-1',
      author: 'Sarah M.',
      role: 'Mother of two',
      text: 'Barbara’s gentle storytelling cadence has completely transformed our nighttime routine. The kids drift off to sleep peacefully within minutes.',
      rating: 5,
      avatar: '🌸',
      sortOrder: 0,
    ),
    Testimonial(
      id: 'default-2',
      author: 'David K.',
      role: 'Night shift nurse',
      text: 'A quiet place for a busy mind to rest. Whenever I have trouble winding down after long shifts, Barb’s stories bring instant calm.',
      rating: 5,
      avatar: '🌙',
      sortOrder: 1,
    ),
    Testimonial(
      id: 'default-3',
      author: 'Emma & Liam',
      role: 'Bedtime Listeners',
      text: 'The combination of soothing nature themes, gentle pauses, and 100% ad-free listening makes this our absolute favourite bedtime sanctuary.',
      rating: 5,
      avatar: '✨',
      sortOrder: 2,
    ),
  ];
}
