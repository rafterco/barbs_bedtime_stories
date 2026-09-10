import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }
  
  static Future<void> completeOnboarding({String? sleepGoal}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (sleepGoal != null) {
      await prefs.setString('sleep_goal', sleepGoal);
    }
  }
  
  static Future<String?> getSleepGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sleep_goal');
  }
}
