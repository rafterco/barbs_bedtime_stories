import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:barbs_bedtime_stories/core/constants/firestore_paths.dart';
import 'package:barbs_bedtime_stories/data/models/app_config.dart';

class ConfigRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<AppConfig?> getAppConfig() {
    return _firestore.collection(FirestorePaths.appConfig).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final generalDoc = snapshot.docs.where((d) => d.id == 'general').firstOrNull;
      final doc = generalDoc ?? snapshot.docs.first;
      return AppConfig.fromFirestore(doc);
    });
  }
}
