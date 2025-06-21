import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../screens/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  Future<void> _completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_viewed_onboarding', true);
      
      if (kDebugMode) {
        print('Onboarding completed - flag set to true');
      }
    } catch (e) {
      // Fallback: Continue without saving preference
      if (kDebugMode) {
        print('Failed to save onboarding preference: $e');
      }
    }
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = false; // Always use light theme
    
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        statusBarBrightness: Brightness.light, // For iOS
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: AppColors.subtleGradient, // Always use light gradient
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),              child: Column(
                children: [
                  // Main content centered
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo
                        Hero(
                          tag: 'app_logo',
                          child: AppLogo(size: 150.w),
                        ),
                        
                        SizedBox(height: 40.h),
                        
                        // Welcome text
                        AutoSizeText(
                          'Welcome to FinityTalks',
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGrey,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                        
                        SizedBox(height: 20.h),
                        
                        // Subtitle
                        AutoSizeText(
                          'Share your thoughts and connect with people around the world',
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                        ),
                        
                        SizedBox(height: 50.h),
                        
                        // Feature icons row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildFeatureIcon(Icons.mic, 'Share', isDarkMode),
                            _buildFeatureIcon(Icons.people, 'Connect', isDarkMode),
                            _buildFeatureIcon(Icons.explore, 'Discover', isDarkMode),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Get Started button
                  Padding(
                    padding: EdgeInsets.only(bottom: 30.h),
                    child: Container(
                      width: double.infinity,
                      height: 55.h,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(27.5.r),
                      ),
                      child: ElevatedButton(
                        onPressed: _completeOnboarding,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27.5.r),
                          ),
                        ),
                        child: AutoSizeText(
                          'Get Started',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      );
  }
  Widget _buildFeatureIcon(IconData icon, String label, bool isDarkMode) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(
            icon,
            size: 32.w,
            color: const Color(0xFF1D1D1F), // Changed to dark color for visibility
          ),
        ),
        SizedBox(height: 8.h),
        AutoSizeText(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
