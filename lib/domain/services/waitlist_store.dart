import 'package:certifications/dal/local/local_source_adapter.dart';
import 'package:certifications/domain/services/waitlist_api_service.dart';
import 'package:flutter/material.dart';

class WaitlistStore extends ChangeNotifier {
  static final WaitlistStore instance = WaitlistStore._();
  WaitlistStore._() {
    _load();
  }

  final LocalSourceAdapter _storage =
      LocalSourceAdapter(namespace: 'certifications.waitlist');
  final WaitlistApiService _api = WaitlistApiService();

  String? savedEmail;
  Set<String> joinedPlans = {};

  Future<void> _load() async {
    final email = await _storage.read<String>('email');
    final plans = await _storage.read<List<dynamic>>('joined_plans');
    if (email != null && email.isNotEmpty) savedEmail = email;
    if (plans != null) {
      joinedPlans = plans.map((e) => e.toString()).toSet();
    }
    notifyListeners();
  }

  bool isJoined(String planId) {
    return joinedPlans.contains(planId) || joinedPlans.contains('all');
  }

  Future<void> joinWaitlist(String planId, String email) async {
    final cleanEmail = email.trim();

    joinedPlans.add(planId);
    if (cleanEmail.isNotEmpty && cleanEmail != 'authenticated_user') {
      savedEmail = cleanEmail;
      await _storage.upsert('email', cleanEmail);
    }
    await _storage.upsert('joined_plans', joinedPlans.toList());

    notifyListeners();

    try {
      await _api.joinFreePlanWaitlist(email: cleanEmail);
    } catch (_) {
      // Local state is already persisted safely
    }
  }
}
