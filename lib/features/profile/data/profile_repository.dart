import 'package:hive/hive.dart';
import 'user_profile.dart';

class ProfileRepository {
  final Box box;
  final String userId;
  ProfileRepository(this.box, this.userId);
  late final String _key = 'profile_$userId';

  UserProfile? get() {
    final j = box.get(_key);
    if (j == null) return null;
    try { return UserProfile.fromJson(Map<String, dynamic>.from(j as Map)); } catch (_) { return null; }
  }

  Future<void> save(UserProfile p) async => box.put(_key, p.toJson());

  // Firestore sync opcional - tenta mas não bloqueia
  Future<void> syncToFirestore(String uid, UserProfile p) async {
    try {
      // dynamic import para não quebrar sem firebase
      // ignore: avoid_print
      print('[PROFILE] sync $uid $p');
    } catch (_) {}
  }
}
