import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/github_service.dart';

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({Key? key}) : super(key: key);

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  GitHubProfile? _profile;
  List<GitHubRepo> _repos = [];
  bool _isLoadingGitHub = false;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
    _loadGitHubData();
  }

  Future<void> _loadGitHubData() async {
    setState(() {
      _isLoadingGitHub = true;
    });

    try {
      final profile = await GitHubService.getUserProfile();
      final repos = await GitHubService.getUserRepos();

      setState(() {
        _profile = profile;
        _repos = repos;
        _isLoadingGitHub = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGitHub = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }  Future<void> _launchEmail() async {
    const String email = 'sanjay13649@gmail.com';
    const String subject = 'FinityTalks App Feedback';
    
    try {
      // Try SENDTO action first (more reliable on Android)
      final Uri sendtoUri = Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}');
      
      if (await canLaunchUrl(sendtoUri)) {
        await launchUrl(sendtoUri, mode: LaunchMode.externalApplication);
        return;
      }
      
      // Try Gmail-specific intent
      final Uri gmailUri = Uri.parse('googlegmail://co?to=$email&subject=${Uri.encodeComponent(subject)}');
      
      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
        return;
      }
      
      // Try different modes and formats
      final List<Map<String, dynamic>> attempts = [
        {'uri': Uri(scheme: 'mailto', path: email, query: 'subject=$subject'), 'mode': LaunchMode.externalApplication},
        {'uri': Uri.parse('mailto:$email?subject=${Uri.encodeComponent(subject)}'), 'mode': LaunchMode.platformDefault},
        {'uri': Uri.parse('mailto:$email'), 'mode': LaunchMode.externalApplication},
      ];
      
      for (final attempt in attempts) {
        try {
          await launchUrl(attempt['uri'], mode: attempt['mode']);
          return; // Success, exit early
        } catch (e) {
          continue; // Try next approach
        }
      }
      
      // All methods failed, copy to clipboard
      await Clipboard.setData(ClipboardData(text: '$email\nSubject: $subject'));
      _showSnackBar('No email app found. Email copied to clipboard!');
      
    } catch (e) {
      // Final fallback
      await Clipboard.setData(ClipboardData(text: '$email\nSubject: $subject'));
      _showSnackBar('Email details copied to clipboard!');
    }
  }Future<void> _launchGitHub() async {
    final Uri githubUri = Uri.parse('https://github.com/sanjay434343');
    
    try {
      if (await canLaunchUrl(githubUri)) {
        await launchUrl(githubUri, mode: LaunchMode.externalApplication);
      } else {
        // Try platform default mode as fallback
        try {
          await launchUrl(githubUri, mode: LaunchMode.platformDefault);
        } catch (e) {
          // Copy URL to clipboard as final fallback
          await Clipboard.setData(ClipboardData(text: 'https://github.com/sanjay434343'));
          _showSnackBar('GitHub URL copied to clipboard');
        }
      }
    } catch (e) {
      // Copy URL to clipboard as fallback
      await Clipboard.setData(ClipboardData(text: 'https://github.com/sanjay434343'));
      _showSnackBar('GitHub URL copied to clipboard');
    }
  }
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF6366f1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(              children: [
                _buildAppBar(),
                SizedBox(height: 24.h),
                _buildProfileSection(),
                SizedBox(height: 16.h),
                _buildAboutSection(),
                SizedBox(height: 24.h),
                _buildGitHubStatsSection(),
                SizedBox(height: 24.h),
                _buildContactSection(),
                SizedBox(height: 24.h),
                _buildSkillsSection(),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.black.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: const Color(0xFF1D1D1F),
                  size: 16.w,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            SizedBox(width: 16.w),
            Text(
              'About Developer',
              style: GoogleFonts.inter(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildAboutSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366f1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: const Color(0xFF6366f1),
                    size: 20.w,
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  'About',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Text(
              _profile?.bio ?? 'Loading bio...',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildProfileSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Transform.translate(
        offset: Offset(0, _slideAnimation.value),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(28.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFFA8EDEA),
                const Color(0xFFDCEDF8),
                const Color(0xFFE0C3FC),
              ],
            ),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFA8EDEA).withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.white.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(50.r),
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(46.r),
                      child: _profile != null
                          ? Image.network(
                              _profile!.avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        const Color(0xFF6366f1),
                                        const Color(0xFF8B5CF6),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 50.w,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF6366f1),
                                    const Color(0xFF8B5CF6),
                                  ],
                                ),
                              ),
                              child: Icon(
                                Icons.person_rounded,
                                size: 50.w,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28.w,
                      height: 28.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(
                        Icons.verified_rounded,
                        size: 14.w,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),              SizedBox(height: 20.h),              Text(
                _profile?.name ?? 'Sanjay M',
                style: GoogleFonts.inter(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6.h),              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Text(
                  'Flutter Developer',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6366f1),
                  ),
                ),
              ),
              SizedBox(height: 16.h),              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatCard(
                    _profile?.createdAt != null
                        ? '${DateTime.now().year - _profile!.createdAt.year}+'
                        : '...',
                    'Years'
                  ),
                  SizedBox(width: 16.w),
                  _buildStatCard(
                    _profile?.publicRepos.toString() ?? '...',
                    'Projects'
                  ),
                  SizedBox(width: 16.w),
                  _buildStatCard(
                    _repos.isNotEmpty ? '${_getTotalStars()}+' : '...',
                    'Stars'                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildStatCard(String number, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            number,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1F2937),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );  }
  Widget _buildContactSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Get in Touch',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
              ),
            ),
            SizedBox(height: 16.h),            _buildContactItem(
              icon: Icons.email_rounded,
              title: 'Email',
              subtitle: _profile?.login != null ? 'Open in Gmail' : 'Loading...',
              onTap: _launchEmail,
            ),
            SizedBox(height: 12.h),            _buildContactItem(
              icon: Icons.code_rounded,
              title: 'GitHub',
              subtitle: _profile?.login != null ? 'Open in Web Browser' : 'Loading...',
              onTap: _launchGitHub,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF6366f1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6366f1),
                size: 18.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D1D1F),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: const Color(0xFF9CA3AF),
              size: 14.w,
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSkillsSection() {
    // Extract skills from GitHub repositories
    Set<String> dynamicSkills = {};
    
    // Add languages from repositories
    for (var repo in _repos) {
      if (repo.language.isNotEmpty && repo.language != 'Unknown') {
        dynamicSkills.add(repo.language);
      }
    }
    
    // Add common Flutter development skills
    dynamicSkills.addAll(['Flutter', 'Mobile Development', 'UI/UX Design']);
    
    // If no GitHub data, use default skills
    final skills = dynamicSkills.isNotEmpty 
        ? dynamicSkills.toList()
        : ['Flutter', 'Dart', 'Mobile Development', 'UI/UX Design'];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.code_rounded,
                  color: const Color(0xFF6366f1),
                  size: 20.w,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Skills & Technologies',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: skills.map((skill) => _buildSkillChip(skill)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillChip(String skill) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFF6366f1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFF6366f1).withOpacity(0.2),
        ),
      ),
      child: Text(
        skill,
        style: GoogleFonts.inter(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6366f1),
        ),
      ),
    );
  }
  Widget _buildGitHubStatsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _isLoadingGitHub
            ? _buildGitHubLoadingState()
            : _profile != null
                ? _buildGitHubProfileData()
                : _buildGitHubErrorState(),
      ),
    );
  }
  Widget _buildGitHubLoadingState() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF6366f1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.code_rounded,
                color: const Color(0xFF6366f1),
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'GitHub Statistics',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366f1)),
        ),
        SizedBox(height: 16.h),
        Text(
          'Loading GitHub data...',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
  Widget _buildGitHubErrorState() {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'GitHub Statistics',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        Icon(
          Icons.wifi_off_rounded,
          color: Colors.grey.withOpacity(0.5),
          size: 48.w,
        ),
        SizedBox(height: 16.h),
        Text(
          'Unable to load GitHub data',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: const Color(0xFF6B7280),
          ),
        ),
        SizedBox(height: 12.h),
        ElevatedButton(
          onPressed: _loadGitHubData,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366f1),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Text(
            'Retry',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildGitHubProfileData() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: const Color(0xFF6366f1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.code_rounded,
                color: const Color(0xFF6366f1),
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'GitHub Statistics',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
              ),
            ),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFF10B981),
                  width: 1,
                ),
              ),
              child: Text(
                'Live',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),
        
        // GitHub Stats Grid
        Row(
          children: [
            Expanded(
              child: _buildGitHubStatItem(
                icon: Icons.folder_rounded,
                value: _profile!.publicRepos.toString(),
                label: 'Repositories',
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildGitHubStatItem(
                icon: Icons.people_rounded,
                value: _profile!.followers.toString(),
                label: 'Followers',
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _buildGitHubStatItem(
                icon: Icons.star_rounded,
                value: _getTotalStars().toString(),
                label: 'Stars',
              ),
            ),
          ],
        ),
        
        if (_profile!.bio != null) ...[
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: const Color(0xFF6366f1).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: const Color(0xFF6366f1).withOpacity(0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: const Color(0xFF6366f1),
                      size: 16.w,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Bio',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6366f1),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  _profile!.bio!,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    color: const Color(0xFF374151),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        if (_repos.isNotEmpty) ...[
          SizedBox(height: 20.h),
          Text(
            'Recent Projects',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D1D1F),
            ),
          ),
          SizedBox(height: 12.h),
          ..._repos.take(3).map((repo) => _buildRepoItem(repo)).toList(),
        ],
      ],
    );
  }
  Widget _buildGitHubStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: const Color(0xFF6366f1).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF6366f1).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6366f1),
            size: 20.w,
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D1D1F),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRepoItem(GitHubRepo repo) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF6366f1).withOpacity(0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF6366f1).withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  repo.name,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D1D1F),
                  ),
                ),
                if (repo.description != null) ...[
                  SizedBox(height: 4.h),
                  Text(
                    repo.description!,
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: const Color(0xFF6B7280),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: BoxDecoration(
                        color: _getLanguageColor(repo.language),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      repo.language,
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Icon(
                      Icons.star_rounded,
                      size: 12.w,
                      color: const Color(0xFF6B7280),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      repo.stargazersCount.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );  }

  int _getTotalStars() {
    return _repos.fold(0, (sum, repo) => sum + repo.stargazersCount);
  }

  Color _getLanguageColor(String language) {
    switch (language.toLowerCase()) {
      case 'dart':
        return const Color(0xFF0175C2);
      case 'javascript':
        return const Color(0xFFF7DF1E);
      case 'python':
        return const Color(0xFF3776AB);
      case 'java':
        return const Color(0xFFED8B00);
      case 'html':
        return const Color(0xFFE34F26);
      case 'css':
        return const Color(0xFF1572B6);
      default:
        return Colors.grey;
    }
  }
}