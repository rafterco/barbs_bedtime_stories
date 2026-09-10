import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:barbs_bedtime_stories/data/models/testimonial.dart';

class TestimonialRepository {
  TestimonialRepository._();
  static final TestimonialRepository instance = TestimonialRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('testimonials');

  /// Stream published testimonials sorted by sortOrder ascending.
  Stream<List<Testimonial>> watchTestimonials() {
    return _collection
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Testimonial.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (list.isEmpty) {
        return Testimonial.defaultTestimonials;
      }
      return list;
    }).handleError((error) {
      debugPrint('Error fetching testimonials: $error');
      return Testimonial.defaultTestimonials;
    });
  }

  /// Get published testimonials once.
  Future<List<Testimonial>> getTestimonials() async {
    try {
      final snapshot = await _collection
          .where('isPublished', isEqualTo: true)
          .get();
      final list = snapshot.docs
          .map((doc) => Testimonial.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (list.isEmpty) {
        return Testimonial.defaultTestimonials;
      }
      return list;
    } catch (e) {
      debugPrint('Error loading testimonials: $e');
      return Testimonial.defaultTestimonials;
    }
  }
}
