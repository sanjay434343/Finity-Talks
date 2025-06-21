import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../utils/shared_preferences_helper.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      await SharedPreferencesHelper.logout();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.subtleGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // App Bar
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: AppColors.darkGrey,
                          size: 24.w,
                        ),
                      ),
                      SizedBox(width: 16.w),
                      AutoSizeText(
                        'Profile',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Profile Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 30.h),
                        
                        // Profile Picture
                        Container(
                          width: 120.w,
                          height: 120.w,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(60.r),
                            gradient: AppColors.primaryGradient,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryBlue.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: _authService.userPhotoURL != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(60.r),
                                  child: Image.network(
                                    _authService.userPhotoURL!,
                                    width: 120.w,
                                    height: 120.w,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.person,
                                      size: 60.w,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 60.w,
                                  color: Colors.white,
                                ),
                        ),
                        
                        SizedBox(height: 24.h),
                        
                        // User Info
                        AutoSizeText(
                          _authService.userDisplayName ?? 'User',
                          style: TextStyle(
                            fontSize: 28.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkGrey,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                        
                        SizedBox(height: 8.h),
                        
                        if (_authService.userEmail != null)
                          AutoSizeText(
                            _authService.userEmail!,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        
                        SizedBox(height: 40.h),
                        
                        // Profile Options
                        _buildProfileOption(
                          icon: Icons.category,
                          title: 'Interests',
                          subtitle: 'Manage your content preferences',
                          onTap: () {
                            // Navigate to category selection
                          },
                        ),
                        
                        _buildProfileOption(
                          icon: Icons.bookmark,
                          title: 'Saved Episodes',
                          subtitle: 'View your saved content',
                          onTap: () {
                            // Navigate to saved episodes
                          },
                        ),
                        
                        _buildProfileOption(
                          icon: Icons.settings,
                          title: 'Settings',
                          subtitle: 'App preferences and privacy',
                          onTap: () {
                            // Navigate to settings
                          },
                        ),
                        
                        _buildProfileOption(
                          icon: Icons.help,
                          title: 'Help & Support',
                          subtitle: 'Get help and contact support',
                          onTap: () {
                            // Navigate to help
                          },
                        ),
                        
                        SizedBox(height: 40.h),
                        
                        // Sign Out Button
                        Container(
                          width: double.infinity,
                          height: 55.h,
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.error, width: 2),
                            borderRadius: BorderRadius.circular(27.5.r),
                          ),
                          child: ElevatedButton(
                            onPressed: _signOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: AppColors.error,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27.5.r),
                              ),
                            ),
                            child: AutoSizeText(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    icon,
                    size: 24.w,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkGrey,
                        ),
                        maxLines: 1,
                      ),
                      SizedBox(height: 4.h),
                      AutoSizeText(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16.w,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
