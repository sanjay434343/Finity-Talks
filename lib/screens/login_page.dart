import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_logo.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../utils/navigation_helper.dart';
import '../screens/category_selection_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        statusBarBrightness: Brightness.light, // For iOS
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          if (state is AuthAuthenticated) {
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_logged_in', true);
              await prefs.setString('user_uid', state.userId);
              
              final hasSelectedCategories = prefs.getBool('has_selected_categories') ?? false;
              
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  if (hasSelectedCategories) {
                    Navigator.pushReplacementNamed(context, '/home');
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const CategorySelectionPage()),
                    );
                  }
                }
              });
            } catch (e) {
              // If SharedPreferences fails, still proceed with navigation
              if (kDebugMode) {
                print('SharedPreferences error: $e');
              }
              
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  // Default to category selection if preferences fail
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const CategorySelectionPage()),
                  );
                }
              });
            }
          } else if (state is AuthError) {
            // Remove the snackbar - user can just try again
            if (kDebugMode) {
              print('Sign in failed: ${state.message}');
            }
          }
        },
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            
            return Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: Column(
                  children: [
                    // Large logo centered in the available space
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Hero(
                              tag: 'app_logo',
                              child: AppLogo(size: 200.w),
                            ),
                            SizedBox(height: 8.h),
                            AutoSizeText(
                              'Thoughts on air',
                              style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w300,
                                color: Colors.black54,
                                letterSpacing: 1.2,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Google Sign In Button at bottom
                    Padding(
                      padding: EdgeInsets.all(30.w),
                      child: _buildGoogleSignInButton(isLoading),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    // Use BLoC instead of direct service call
    context.read<AuthBloc>().add(AuthSignInRequested());
  }

  Widget _buildGoogleSignInButton(bool isLoading) {
    return Container(
      width: double.infinity,
      height: 55.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.purple, Colors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(27.5.r),
      ),
      child: Container(
        margin: EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26.r),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : _signInWithGoogle,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
            elevation: 0,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26.r),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  width: 20.w,
                  height: 20.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.network(
                      'https://developers.google.com/identity/images/g-logo.png',
                      height: 24.w,
                      width: 24.w,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.account_circle,
                          size: 24.w,
                          color: Colors.grey,
                        );
                      },
                    ),
                    SizedBox(width: 12.w),
                    AutoSizeText(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
