import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/profile_repository.dart';
import '../data/user_profile.dart';

final profileRepoProvider = Provider<ProfileRepository>((ref) {
  final box = Hive.box('mamba_box');
  final auth = ref.watch(authProvider);
  return ProfileRepository(box, auth.userId);
});

final profileProvider = StateNotifierProvider.autoDispose<ProfileNotifier, UserProfile?>((ref) {
  final repo = ref.watch(profileRepoProvider);
  return ProfileNotifier(repo);
});

class ProfileNotifier extends StateNotifier<UserProfile?> {
  final ProfileRepository repo;
  ProfileNotifier(this.repo) : super(repo.get());

  Future<void> save(UserProfile p) async {
    await repo.save(p);
    state = p;
  }

  Future<void> updateWeight(double w) async {
    if (state == null) return;
    final upd = state!.copyWith(weight: w);
    await save(upd);
  }

  Future<void> updateTarget(double t) async {
    if (state == null) return;
    final upd = state!.copyWith(targetWeight: t);
    await save(upd);
  }
}
