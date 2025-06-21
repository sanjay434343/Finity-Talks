import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/favorites_service.dart';

class BookSuggestion {
  final String title;
  final String author;
  final String coverUrl;
  final String key;

  BookSuggestion({
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.key,
  });
}

class BookDetailPage extends StatefulWidget {
  final BookSuggestion book;

  const BookDetailPage({Key? key, required this.book}) : super(key: key);

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;
  late AnimationController _shimmerController;
  late Animation<double> _floatingAnimation;
  late Animation<double> _shimmerAnimation;
  bool _isLiked = false;
  bool _isTogglingFavorite = false;
  
  // API data with caching
  Map<String, dynamic>? bookDetails;
  bool isLoading = true;
  String? errorMessage;
  static final Map<String, Map<String, dynamic>> _cache = {};
  static const String _cachePrefix = 'book_details_';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadBookDetails();
    _checkIfFavorited();
  }

  void _setupAnimations() {
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _floatingAnimation = Tween<double>(
      begin: -8.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _floatingController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));
  }

  Future<void> _loadBookDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Check memory cache first
      if (_cache.containsKey(widget.book.key)) {
        setState(() {
          bookDetails = _cache[widget.book.key];
          isLoading = false;
        });
        return;
      }

      // Check SharedPreferences cache
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix${widget.book.key}';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        try {
          final data = json.decode(cachedData);
          // Check if cache is still valid (24 hours)
          final cacheTime = data['_cache_time'] as int?;
          final now = DateTime.now().millisecondsSinceEpoch;
          
          if (cacheTime != null && (now - cacheTime) < 24 * 60 * 60 * 1000) {
            // Cache is valid, use it
            data.remove('_cache_time'); // Remove cache metadata
            setState(() {
              bookDetails = data;
              isLoading = false;
            });
            _cache[widget.book.key] = data; // Store in memory cache
            return;
          }
        } catch (e) {
          // Invalid cache data, continue to fetch
        }
      }

      // Fetch from API
      await _fetchBookDetails();
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load book details';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchBookDetails() async {
    try {
      final response = await http.get(
        Uri.parse('https://openlibrary.org${widget.book.key}.json'),
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Cache the data
        await _cacheBookDetails(data);
        
        setState(() {
          bookDetails = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load book details');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load book details';
        isLoading = false;
      });
    }
  }

  Future<void> _cacheBookDetails(Map<String, dynamic> data) async {
    try {
      // Store in memory cache
      _cache[widget.book.key] = data;
      
      // Store in SharedPreferences with timestamp
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cachePrefix${widget.book.key}';
      final dataWithTimestamp = Map<String, dynamic>.from(data);
      dataWithTimestamp['_cache_time'] = DateTime.now().millisecondsSinceEpoch;
      
      await prefs.setString(cacheKey, json.encode(dataWithTimestamp));
    } catch (e) {
      // Cache failed, but don't throw error
      print('Failed to cache book details: $e');
    }
  }

  String _getDescription() {
    if (bookDetails == null) return '';
    
    final description = bookDetails!['description'];
    if (description is String) {
      return description;
    } else if (description is Map && description['value'] is String) {
      return description['value'];
    }
    return '';
  }

  String _getFirstPublishDate() {
    if (bookDetails == null) return '';
    
    final firstPublishDate = bookDetails!['first_publish_date'];
    if (firstPublishDate is String) {
      return firstPublishDate;
    }
    return '';
  }

  List<String> _getSubjects() {
    if (bookDetails == null) return [];
    
    final subjects = bookDetails!['subjects'];
    if (subjects is List) {
      return subjects.cast<String>().take(3).toList();
    }
    return [];
  }

  int? _getNumberOfPages() {
    if (bookDetails == null) return null;
    
    final numberOfPages = bookDetails!['number_of_pages'];
    if (numberOfPages is int) {
      return numberOfPages;
    }
    return null;
  }

  Future<void> _checkIfFavorited() async {
    try {
      final isFavorited = await FavoritesService.isBookFavorited(widget.book.title);
      if (mounted) {
        setState(() {
          _isLiked = isFavorited;
        });
      }
    } catch (e) {
      print('Error checking if book is favorited: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;
    
    setState(() {
      _isTogglingFavorite = true;
    });

    try {
      final description = _getDescription();
      final subjects = _getSubjects();
      
      final wasToggled = await FavoritesService.toggleBookFavorite(
        widget.book,
        description,
        subjects,
      );
      
      if (mounted) {
        setState(() {
          _isLiked = wasToggled;
          _isTogglingFavorite = false;
        });
        
        // Show feedback to user
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
    _floatingController.dispose();
    _shimmerController.dispose();
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
        ),
        child: isLoading 
          ? _buildLoadingState()
          : errorMessage != null
            ? _buildErrorState()
            : CustomScrollView(
                slivers: [
                  _buildAppBar(),
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        _buildHeroSection(),
                        _buildBookInfo(),
                        _buildDescription(),
                        if (_getSubjects().isNotEmpty) _buildSubjects(),
                        _buildPurchaseSection(),
                        SizedBox(height: 50.h), // Reduced spacing since no floating button
                      ],
                    ),
                  ),
                ],
              ),
      ),
      // Removed floatingActionButton
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(40.r),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Loading book details...',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF86868B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 80.w,
            color: const Color(0xFF86868B),
          ),
          SizedBox(height: 24.h),
          Text(
            errorMessage ?? 'Something went wrong',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D1D1F),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          ElevatedButton(
            onPressed: _fetchBookDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFd1b8f8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 80.h,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      elevation: 0,
      leading: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: const Color(0xFF1D1D1F),
            size: 20.w,
          ),
        ),
      ),
      actions: [
        GestureDetector(
          onTap: _isTogglingFavorite ? null : () {
            HapticFeedback.lightImpact();
            _toggleFavorite();
          },
          child: Container(
            margin: EdgeInsets.all(8.w),
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isTogglingFavorite
                ? SizedBox(
                    width: 20.w,
                    height: 20.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey[400]!,
                      ),
                    ),
                  )
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      key: ValueKey(_isLiked),
                      color: _isLiked ? Colors.red : const Color(0xFF86868B),
                      size: 20.w,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    final firstPublishDate = _getFirstPublishDate();
    
    return Container(
      height: 400.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF95e3e0).withValues(alpha: 0.1),
            const Color(0xFFd1b8f8).withValues(alpha: 0.1),
            const Color(0xFFc8e3f4).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Floating particles
          ...List.generate(6, (index) => _buildFloatingParticle(index)),
          
          // Main book cover with Hero animation matching home page tag
          Center(
            child: AnimatedBuilder(
              animation: _floatingAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _floatingAnimation.value),
                  child: Hero(
                    tag: 'book_cover_${widget.book.key}', // Match exactly with home page
                    child: Container(
                      width: 200.w,
                      height: 280.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: const Color(0xFF95e3e0).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(-10, -10),
                          ),
                          BoxShadow(
                            color: const Color(0xFFd1b8f8).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(10, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Stack(
                          children: [
                            CachedNetworkImage(
                              imageUrl: widget.book.coverUrl,
                              key: ValueKey(widget.book.coverUrl),
                              width: 200.w,
                              height: 280.h,
                              fit: BoxFit.cover,
                              memCacheWidth: (200 * MediaQuery.of(context).devicePixelRatio).round(),
                              memCacheHeight: (280 * MediaQuery.of(context).devicePixelRatio).round(),
                              placeholder: (context, url) => Container(
                                width: 200.w,
                                height: 280.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF95e3e0).withValues(alpha: 0.3),
                                      const Color(0xFFd1b8f8).withValues(alpha: 0.3),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: AnimatedBuilder(
                                    animation: _shimmerController,
                                    builder: (context, child) {
                                      return Container(
                                        width: 40.w,
                                        height: 40.w,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: SweepGradient(
                                            colors: [
                                              Colors.white.withValues(alpha: 0.1),
                                              Colors.white.withValues(alpha: 0.8),
                                              Colors.white.withValues(alpha: 0.1),
                                            ],
                                            transform: GradientRotation(_shimmerController.value * 2 * math.pi),
                                          ),
                                        ),
                                        child: const CircularProgressIndicator(
                                          strokeWidth: 3,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => _buildFallbackCover(),
                              fadeInDuration: const Duration(milliseconds: 300),
                              fadeOutDuration: const Duration(milliseconds: 300),
                            ),
                            // Shimmer overlay for loaded image
                            AnimatedBuilder(
                              animation: _shimmerAnimation,
                              builder: (context, child) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.white.withValues(alpha: 0.2),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      transform: GradientRotation(_shimmerAnimation.value * math.pi),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  );
              },
            ),
          ),
          
          // Show publish date if available
          if (firstPublishDate.isNotEmpty)
            Positioned(
              top: 20.h,
              right: 20.w,
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                        ),
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF95e3e0).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        firstPublishDate,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = math.Random(index);
    final size = 4.0 + random.nextDouble() * 8.0;
    final left = random.nextDouble() * 300.w;
    final top = random.nextDouble() * 300.h;
    
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _floatingController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              math.sin(_floatingController.value * 2 * math.pi + index) * 10,
              math.cos(_floatingController.value * 2 * math.pi + index) * 15,
            ),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF95e3e0).withValues(alpha: 0.6),
                    const Color(0xFFd1b8f8).withValues(alpha: 0.4),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF95e3e0).withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFallbackCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF95e3e0).withValues(alpha: 0.3),
            const Color(0xFFd1b8f8).withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.book_rounded,
          color: const Color(0xFF86868B),
          size: 64.w,
        ),
      ),
    );
  }

  Widget _buildBookInfo() {
    final numberOfPages = _getNumberOfPages();
    final firstPublishDate = _getFirstPublishDate();
    
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.book.title,
            style: GoogleFonts.inter(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          
          // Author
          Text(
            'by ${widget.book.author}',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF86868B),
            ),
          ),
          SizedBox(height: 16.h),
          
          // Stats row - only show available data
          Row(
            children: [
              if (firstPublishDate.isNotEmpty) ...[
                _buildStatChip(Icons.calendar_today_rounded, firstPublishDate, const Color(0xFF95e3e0)),
                SizedBox(width: 12.w),
              ],
              if (numberOfPages != null) ...[
                _buildStatChip(Icons.book_rounded, '$numberOfPages pages', const Color(0xFFd1b8f8)),
                SizedBox(width: 12.w),
              ],
              _buildStatChip(Icons.language_rounded, 'Available', const Color(0xFFc8e3f4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14.w,
          ),
          SizedBox(width: 4.w),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final description = _getDescription();
    
    // Only show description section if we have description data
    if (description.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this book',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  const Color(0xFF95e3e0).withValues(alpha: 0.02),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: const Color(0xFF95e3e0).withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF444444),
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildSubjects() {
    final subjects = _getSubjects();
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4.w,
                height: 24.h,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Subjects',
                style: GoogleFonts.inter(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1D1D1F),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 8.w,
              runSpacing: 8.h,
              children: subjects.asMap().entries.map((entry) {
                final index = entry.key;
                final subject = entry.value;
                return TweenAnimationBuilder<double>(
                  duration:  Duration(milliseconds: 300 + (index * 100)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: Opacity(
                          opacity: math.max(0.0, math.min(1.0, value)), // Clamp opacity between 0.0 and 1.0
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFc8e3f4).withValues(alpha: 0.2),
                                  const Color(0xFFd1b8f8).withValues(alpha: 0.15),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24.r),
                              border: Border.all(
                                color: const Color(0xFFc8e3f4).withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFc8e3f4).withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6.w,
                                  height: 6.w,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF85b8d0),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Flexible(
                                  child: Text(
                                    subject,
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF85b8d0),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 24.h),
        ],
      ),
    );
  }

  Widget _buildPurchaseSection() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get this book',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _buildPurchaseOption(
                  'Amazon',
                  'Buy on Amazon',
                  Icons.shopping_cart_rounded,
                  const Color(0xFF95e3e0),
                  () => _launchPurchaseUrl('amazon_india'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildPurchaseOption(
                  'Flipkart',
                  'Buy on Flipkart',
                  Icons.shopping_bag_rounded,
                  const Color(0xFFd1b8f8),
                  () => _launchPurchaseUrl('flipkart'),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: _buildPurchaseOption(
                  'Google Play',
                  'Digital edition',
                  Icons.play_arrow_rounded,
                  const Color(0xFFc8e3f4),
                  () => _launchPurchaseUrl('google'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildPurchaseOption(
                  'Web Search',
                  'Find anywhere',
                  Icons.search_rounded,
                  const Color(0xFF86868B),
                  () => _launchPurchaseUrl('web_search'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseOption(
    String platform,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isWide = false,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              color.withValues(alpha: 0.05),
              Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(50.r), // Pill shape
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16.w,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              platform,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1D1D1F),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _launchPurchaseUrl(String platform) async {
    final bookTitle = Uri.encodeComponent(widget.book.title);
    final author = Uri.encodeComponent(widget.book.author);
    
    final urls = {
      'amazon_india': 'https://www.amazon.in/s?k=$bookTitle+$author&i=stripbooks',
      'flipkart': 'https://www.flipkart.com/search?q=$bookTitle+$author',
      'google': 'https://play.google.com/store/search?q=$bookTitle+$author&c=books',
      'web_search': 'https://www.google.com/search?q=$bookTitle+$author+book+buy',
    };

    final url = urls[platform];
    if (url != null) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback: try opening in browser mode
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        print('Error launching URL: $e');
        // Show user-friendly error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Unable to open $platform. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
