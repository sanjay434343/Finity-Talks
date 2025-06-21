import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class SharedPreferencesHelper {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userUidKey = 'user_uid';
  static const String _hasViewedOnboardingKey = 'has_viewed_onboarding';

  static Future<bool> getIsLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting isLoggedIn: $e');
      }
      return false;
    }
  }

  static Future<void> setIsLoggedIn(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, value);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting isLoggedIn: $e');
      }
    }
  }

  static Future<String?> getUserUid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userUidKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting userUid: $e');
      }
      return null;
    }
  }

  static Future<void> setUserUid(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userUidKey, uid);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting userUid: $e');
      }
    }
  }

  static Future<bool> getHasViewedOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasViewedOnboardingKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting hasViewedOnboarding: $e');
      }
      return false;
    }
  }

  static Future<void> setHasViewedOnboarding(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasViewedOnboardingKey, value);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting hasViewedOnboarding: $e');
      }
    }
  }

  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing preferences: $e');
      }
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, false);
      await prefs.remove(_userUidKey);
      // Keep onboarding flag so user doesn't see it again
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout: $e');
      }
    }
  }

  // Add method to check if user should auto-login
  static Future<bool> shouldAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      final userUid = prefs.getString(_userUidKey);

      return isLoggedIn && userUid != null && userUid.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking shouldAutoLogin: $e');
      }
      return false;
    }
  }
}
