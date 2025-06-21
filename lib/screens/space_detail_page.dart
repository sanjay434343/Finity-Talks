import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import '../services/nasa_service.dart';
import '../services/favorites_service.dart';
import 'developer_page.dart';

class SpaceDetailPage extends StatefulWidget {
  final String imageUrl;
  final String title;
  final String description;
  final String date;

  const SpaceDetailPage({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.date,
  }) : super(key: key);

  @override
  State<SpaceDetailPage> createState() => _SpaceDetailPageState();
}

class _SpaceDetailPageState extends State<SpaceDetailPage>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  double _scrollOffset = 0.0;
  bool _imageLoaded = false;
  
  // Cache for space data
  static final Map<String, NasaApod> _spaceDataCache = {};
  NasaApod? _cachedSpaceData;
  bool _isLoadingAdditionalData = false;
  bool _isLiked = false;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    _animationController.forward();
    _loadCachedSpaceData();
    _checkIfFavorited();
  }

  void _loadCachedSpaceData() async {
    // Try to get cached data first
    _cachedSpaceData = _spaceDataCache[widget.title];
    
    if (_cachedSpaceData == null) {
      setState(() {
        _isLoadingAdditionalData = true;
      });
      
      try {
        // If not cached, try to fetch from NASA API
        final recentApods = await NasaService.getRecentApods(count: 10);
        final matchingApod = recentApods.firstWhere(
          (apod) => apod.title == widget.title,
          orElse: () => NasaApod(
            title: widget.title,
            explanation: widget.description,
            url: widget.imageUrl,
            hdurl: widget.imageUrl,
            date: widget.date,
            mediaType: 'image',
          ),
        );
        
        // Cache the data
        _spaceDataCache[widget.title] = matchingApod;
        _cachedSpaceData = matchingApod;
      } catch (e) {
        // Fallback to provided data
        _cachedSpaceData = NasaApod(
          title: widget.title,
          explanation: widget.description,
          url: widget.imageUrl,
          hdurl: widget.imageUrl,
          date: widget.date,
          mediaType: 'image',
        );
      }
      
      setState(() {
        _isLoadingAdditionalData = false;
      });
    }
  }

  Future<void> _checkIfFavorited() async {
    try {
      final isFavorited = await FavoritesService.isSpaceImageFavorited(widget.title);
      if (mounted) {
        setState(() {
          _isLiked = isFavorited;
        });
      }
    } catch (e) {
      print('Error checking if space image is favorited: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;
    
    setState(() {
      _isTogglingFavorite = true;
    });

    try {
      final wasToggled = await FavoritesService.toggleSpaceImageFavorite(
        widget.title,
        widget.imageUrl,
        widget.description,
        _cachedSpaceData?.explanation ?? widget.description,
        widget.date,
        source: 'NASA',
        type: 'APOD',
        quality: _cachedSpaceData?.hdurl != null ? 'HD' : 'Standard',
      );
      
      if (mounted) {
        setState(() {
          _isLiked = wasToggled;
          _isTogglingFavorite = false;
        });
        
        // Show feedback to user with haptic feedback
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isLiked ? 'Added to favorites' : 'Removed from favorites',
            ),
            backgroundColor: _isLiked ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        setState(() {
          _isTogglingFavorite = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update favorites'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
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
        ),        child: Stack(
          children: [
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                _buildAppBar(),
                _buildContent(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 250.h,
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      elevation: 0,
      leading: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
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
      ),      actions: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.info_outline_rounded,
                color: const Color(0xFF86868B),
                size: 20.w,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DeveloperPage(),
                  ),
                );
              },
            ),
          ),
        ),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isTogglingFavorite
                ? Container(
                    width: 48.w,
                    height: 48.w,
                    child: Center(
                      child: SizedBox(
                        width: 16.w,
                        height: 16.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey[400]!,
                          ),
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        key: ValueKey(_isLiked),
                        color: _isLiked ? Colors.red : const Color(0xFF86868B),
                        size: 20.w,
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _toggleFavorite();
                    },
                  ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Hero Image - fully visible without any overlay
            Transform.translate(
              offset: Offset(0, _scrollOffset * 0.2),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Hero(
                  tag: 'space_${widget.date}',
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFF6366f1),
                          strokeWidth: 2.w,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[100],
                      child: Center(
                        child: Icon(
                          Icons.image_not_supported_rounded,
                          color: Colors.grey[400],
                          size: 32.w,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.h),
                _buildTitleSection(),
                SizedBox(height: 16.h),
                _buildDescriptionSection(),
                SizedBox(height: 16.h),
                _buildDetailsSection(),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF6366f1).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                padding: EdgeInsets.all(6.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366f1).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  color: const Color(0xFF6366f1),
                  size: 16.w,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'NASA APOD',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366f1),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            widget.title,
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.3,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    final explanation = _cachedSpaceData?.explanation ?? widget.description;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                Icons.info_outline_rounded,
                color: const Color(0xFF86868B),
                size: 16.w,
              ),
              SizedBox(width: 6.w),
              Text(
                'Description',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            explanation.isNotEmpty ? explanation : 'No description available for this space image.',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF374151),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D1D1F),
            ),
          ),
          SizedBox(height: 12.h),
          _buildDetailRow('Source', 'NASA APOD', Icons.source_rounded),
          _buildDetailRow('Date', _formatDate(widget.date), Icons.calendar_today_rounded),
          _buildDetailRow('Type', _cachedSpaceData?.mediaType ?? 'Image', Icons.image_rounded),
          _buildDetailRow('Quality', _cachedSpaceData?.hdurl != null ? 'HD Available' : 'Standard', Icons.hd_rounded),
          if (_isLoadingAdditionalData)
            Padding(
              padding: EdgeInsets.only(top: 8.h),
              child: Row(
                children: [
                  SizedBox(
                    width: 12.w,
                    height: 12.w,
                    child: CircularProgressIndicator(
                      color: const Color(0xFF6366f1),
                      strokeWidth: 1.5,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Loading details...',
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF86868B),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6366f1),
            size: 14.w,
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF86868B),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D1D1F),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return "${months[date.month - 1]} ${date.day}, ${date.year}";
    } catch (e) {
      return dateString;
    }
  }
}
