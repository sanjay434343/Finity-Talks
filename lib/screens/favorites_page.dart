import 'package:finitytalks/screens/favorite_podcast_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart'; // added for dynamic palette
import '../services/favorites_service.dart';
import '../models/favorite_item.dart';
import '../models/music_model.dart'; // Add this import
import '../screens/book_detail_page.dart';
import '../screens/space_detail_page.dart';
import '../screens/player_page.dart';
import '../screens/music_player_page.dart'; // Add this import
import '../services/wikipedia_service.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late Future<List<FavoriteBook>> _books;
  late Future<List<FavoritePodcast>> _podcasts;
  late Future<List<FavoriteSpaceImage>> _spaceImages;
  late Future<List<FavoriteMusic>> _music; // Add music future
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _books = FavoritesService.getFavoriteBooks();
    _podcasts = FavoritesService.getFavoritePodcasts();
    _spaceImages = FavoritesService.getFavoriteSpaceImages();
    _music = FavoritesService.getFavoriteMusic(); // Initialize music favorites
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                children: [
                  // Custom App Bar
                  _buildAppBar(),
                  
                  // Main Content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshData,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 12.h),
                            
                            // Welcome Section with enhanced animation
                            _buildAnimatedWelcomeSection(),
                            
                            SizedBox(height: 24.h),
                            
                            // Favorite Music Section (First)
                            _buildAnimatedSection(
                              child: _buildFavoriteMusicSection(),
                              delay: 150,
                            ),
                            
                            SizedBox(height: 24.h),
                            
                            // Favorite Podcasts Section (Second)
                            _buildAnimatedSection(
                              child: _buildFavoritePodcastsSection(),
                              delay: 300,
                            ),
                            
                            SizedBox(height: 24.h),
                            
                            // Favorite Books Section (Third)
                            _buildAnimatedSection(
                              child: _buildFavoriteBooksSection(),
                              delay: 450,
                            ),
                            
                            SizedBox(height: 5.h),
                            
                            // Favorite Space Images Section (Fourth)
                            _buildAnimatedSection(
                              child: _buildFavoriteSpaceImagesSection(),
                              delay: 600,
                            ),
                            
                            SizedBox(height: 24.h),
                          ],
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

  Future<void> _refreshData() async {
    setState(() {
      _books = FavoritesService.getFavoriteBooks();
      _podcasts = FavoritesService.getFavoritePodcasts();
      _spaceImages = FavoritesService.getFavoriteSpaceImages();
      _music = FavoritesService.getFavoriteMusic(); // Refresh music favorites
    });
    
    // Restart animations
    _fadeController.reset();
    _slideController.reset();
    await Future.delayed(const Duration(milliseconds: 100));
    _fadeController.forward();
    _slideController.forward();
  }

  Widget _buildAnimatedSection({required Widget child, required int delay}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + delay),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildAnimatedWelcomeSection() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: (0.8 + (0.2 * value)).clamp(0.1, 1.0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: _buildWelcomeSection(),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF6B6B), // Red accent
            Color(0xFFFF8E8E), // Light red
            Color(0xFFFFB3B3), // Lighter red
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(50.r),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated favorite icon
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 2000),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: (0.5 + (0.5 * value)).clamp(0.1, 1.0),
                child: Transform.rotate(
                  angle: (1 - value) * math.pi * 2,
                  child: Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30.r),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 32.w,
                      ),
                    ),
                  ),
                ),
                );
              },
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Collection',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: -0.1,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Saved Favorites',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritePodcastsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Favorite Episodes',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFFc8e3f4).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Your episodes',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF85b8d0),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        FutureBuilder<List<FavoritePodcast>>(
          future: _podcasts,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildPodcastLoadingState();
            }
            
            final podcasts = snapshot.data ?? [];
            if (podcasts.isEmpty) {
              return _buildEmptyState('No favorite episodes saved yet', Icons.podcasts_outlined);
            }
            
            return Column(
              children: podcasts.asMap().entries.map((entry) {
                final index = entry.key;
                final podcast = entry.value;
                return _buildAnimatedPodcastCard(podcast, index);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedPodcastCard(FavoritePodcast podcast, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(50 * (1 - value), 0),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: _EnhancedFavoritePodcastCard(
              podcast: podcast,
              onPlay: () => _playPodcast(podcast),
              onRead: () => _readPodcast(podcast),
            ),
          ),
        );
      },
    );
  }

  void _playPodcast(FavoritePodcast podcast) {
    final episode = WikipediaEpisode(
      title: podcast.title,
      description: 'Saved episode from your favorites',
      imageUrl: podcast.imageUrl,
      pageUrl: '',
      category: podcast.category,
      duration: '5 min',
    );
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PlayerPage(
          episode: episode,
          autoPlay: true,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOutCubic)),
            ),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _readPodcast(FavoritePodcast podcast) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FavoritePodcastDetailPage(
          podcast: podcast,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0.0, 0.3), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeInOut)),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _buildFavoriteBooksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Favorite Books',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFFd1b8f8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Your collection',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF9d7cc0),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        FutureBuilder<List<FavoriteBook>>(
          future: _books,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildBookLoadingState();
            }
            
            final books = snapshot.data ?? [];
            if (books.isEmpty) {
              return _buildEmptyState('No favorite books saved yet', Icons.book_outlined);
            }
            
            return SizedBox(
              height: 200.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return _buildAnimatedBookCard(book, index);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedBookCard(FavoriteBook book, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800 + (index * 150)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: (0.6 + (0.4 * value)).clamp(0.1, 1.0),
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: _buildBookCard(book, index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFavoriteSpaceImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Favorite Space Images',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF6366f1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'NASA collection',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366f1),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        FutureBuilder<List<FavoriteSpaceImage>>(
          future: _spaceImages,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildSpaceImagesLoadingState();
            }
            
            final images = snapshot.data ?? [];
            if (images.isEmpty) {
              return _buildEmptyState('No favorite space images saved yet', Icons.image_outlined);
            }
            
            return SizedBox(
              height: 180.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  return _buildAnimatedSpaceImageCard(image, index);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedSpaceImageCard(FavoriteSpaceImage image, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 120)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(40 * (1 - value), 0),
          child: Transform.scale(
            scale: (0.8 + (0.2 * value)).clamp(0.1, 1.0),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: _buildSpaceImageCard(image, index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookCard(FavoriteBook book, int index) {
    return GestureDetector(
      onTap: () {
        final bookSuggestion = BookSuggestion(
          title: book.title,
          author: book.author,
          coverUrl: book.imageUrl,
          key: book.key, // Use the actual key instead of 'favorite_${book.title}'
        );
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => BookDetailPage(book: bookSuggestion),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Container(
        width: 100.w,
        margin: EdgeInsets.only(right: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'book_cover_favorite_${book.title}',
              child: Container(
                width: 100.w,
                height: 140.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: CachedNetworkImage(
                    imageUrl: book.imageUrl,
                    width: 100.w,
                    height: 140.h,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
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
                          size: 32.w,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: 100.w,
              child: Text(
                book.title,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D1D1F),
                  letterSpacing: -0.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: 100.w,
              child: Text(
                book.author,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF86868B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpaceImageCard(FavoriteSpaceImage image, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SpaceDetailPage(
              imageUrl: image.imageUrl,
              title: image.title,
              description: image.content, // Use content instead of generic message
              date: image.date,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: animation.drive(
                    Tween(begin: const Offset(0.0, 0.3), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeInOut)),
                  ),
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 600),
            reverseTransitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Container(
        width: 120.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'space_favorite_${image.title}',
              child: Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: image.imageUrl,
                        width: 120.w,
                        height: 120.h,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366f1).withValues(alpha: 0.3),
                                const Color(0xFF8b5cf6).withValues(alpha: 0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_rounded,
                              color: Colors.white,
                              size: 32.w,
                            ),
                          ),
                        ),
                      ),
                      // NASA badge only
                      Positioned(
                        top: 4.w,
                        left: 4.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'NASA',
                            style: GoogleFonts.inter(
                              fontSize: 8.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: Text(
                    image.title,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D1D1F),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF6366f1),
                  size: 10.w,
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              image.date,
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF86868B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.grey[400],
              size: 32.w,
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookLoadingState() {
    return SizedBox(
      height: 200.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 100.w,
          margin: EdgeInsets.only(right: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100.w,
                height: 140.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: 80.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                width: 60.w,
                height: 10.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodcastLoadingState() {
    return Column(
      children: List.generate(3, (index) => Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50.w,
              height: 50.w,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(7.r),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    height: 11.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(5.5.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildSpaceImagesLoadingState() {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 120.w,
          margin: EdgeInsets.only(right: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 120.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: 100.w,
                height: 12.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                width: 80.w,
                height: 10.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Icon(
                Icons.arrow_back_ios_rounded,
                color: const Color(0xFF1D1D1F),
                size: 18.w,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'My Favorites',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteMusicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Favorite Music',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: const Color(0xFF95e3e0).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                'Your tracks',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5ba5a3),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        FutureBuilder<List<FavoriteMusic>>(
          future: _music,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildMusicLoadingState();
            }
            
            final music = snapshot.data ?? [];
            if (music.isEmpty) {
              return _buildEmptyState('No favorite music saved yet', Icons.music_note_outlined);
            }
            
            return SizedBox(
              height: 170.h, // Reduced height to fix overflow
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: music.length,
                itemBuilder: (context, index) {
                  final track = music[index];
                  return _buildAnimatedMusicCard(track, index);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAnimatedMusicCard(FavoriteMusic music, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 120)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuart,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(40 * (1 - value), 0),
          child: Transform.scale(
            scale: (0.8 + (0.2 * value)).clamp(0.1, 1.0),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: _buildMusicCard(music, index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMusicCard(FavoriteMusic music, int index) {
    return GestureDetector(
      onTap: () {
        // Navigate to music player with this track
        final musicTrack = MusicTrack(
          trackId: 0, // Default value for liked tracks
          trackName: music.title,
          artistName: music.artist,
          albumName: 'Liked Music', // Default album name
          artworkUrl100: music.imageUrl,
          artworkUrl600: music.imageUrl,
          previewUrl: music.musicUrl,
          trackTimeMillis: 30000, // Default 30 seconds
          genre: 'Liked', // Default genre
          releaseDate: music.createdAt, // Use savedDate directly as DateTime
          country: 'US', // Default country
          trackPrice: 0.0, // Default price
          currency: 'USD', // Default currency
        );
        
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MusicPlayerPage(
              initialTracks: [musicTrack],
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                    .chain(CurveTween(curve: Curves.easeInOutCubic)),
                ),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      },
      child: Container(
        width: 130.w, // Reduced width
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'music_favorite_${music.title}_${music.artist}',
              child: Container(
                width: 130.w, // Reduced width
                height: 130.h, // Reduced height
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: music.imageUrl,
                        width: 130.w,
                        height: 130.h,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
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
                              Icons.music_note_rounded,
                              color: Colors.white,
                              size: 32.w,
                            ),
                          ),
                        ),
                      ),
                      // Play overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Center(
                            child: Container(
                              width: 36.w,
                              height: 36.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: const Color(0xFF95e3e0),
                                size: 20.w,
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
            SizedBox(height: 8.h),
            // Minimal text content
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    music.title,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D1D1F),
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    music.artist,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF86868B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicLoadingState() {
    return SizedBox(
      height: 170.h, // Reduced height to match
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 130.w, // Reduced width to match
          margin: EdgeInsets.only(right: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 130.w,
                height: 130.h, // Reduced height
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              SizedBox(height: 8.h),
              Container(
                width: 110.w, // Reduced width
                height: 12.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(6.r),
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                width: 80.w,
                height: 10.h,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnhancedFavoritePodcastCard extends StatefulWidget {
  final FavoritePodcast podcast;
  final VoidCallback? onPlay;
  final VoidCallback? onRead;

  const _EnhancedFavoritePodcastCard({
    required this.podcast,
    this.onPlay,
    this.onRead,
  });

  @override
  State<_EnhancedFavoritePodcastCard> createState() => _EnhancedFavoritePodcastCardState();
}

class _EnhancedFavoritePodcastCardState extends State<_EnhancedFavoritePodcastCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late AnimationController _pressController;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  bool _isTapped = false;

  // add palette colors
  Color _primaryColor = Colors.white;
  Color _accentColor = Colors.blue;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat();
    _updatePalette(); // fetch image colors
  }

  Future<void> _updatePalette() async {
    final gen = await PaletteGenerator.fromImageProvider(
      NetworkImage(widget.podcast.imageUrl),
      size: const Size(200, 200),
    );
    setState(() {
      _primaryColor = gen.dominantColor?.color ?? Colors.white;
      _accentColor = gen.vibrantColor?.color ?? _primaryColor;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isTapped = true);
        _pressController.forward();
      },
      onTapUp: (_) {
        setState(() => _isTapped = false);
        _pressController.reverse();
      },
      onTapCancel: () {
        setState(() => _isTapped = false);
        _pressController.reverse();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_animation, _scaleAnimation]),
        builder: (context, child) {
          final animationValue = _isTapped ? 0.0 : _animation.value;
          final time = animationValue * 2 * math.pi;
          
          final cardColors = [
            _primaryColor,
            _accentColor,
            _primaryColor.withOpacity(0.8),
          ];
          
          // Enhanced fluid mixing with more complex patterns
          final mix1 = 0.35 + 0.2 * math.sin(time * 0.7);
          final mix2 = 0.55 + 0.15 * math.cos(time * 0.5 + math.pi / 4);
          final mix3 = 0.75 + 0.18 * math.sin(time * 0.3 + math.pi / 2);
          final mix4 = 0.25 + 0.12 * math.cos(time * 0.9 + math.pi / 3);
          final mix5 = 0.85 + 0.1 * math.sin(time * 1.1 + math.pi);
          
          final opacity1 = 0.08 + (_isTapped ? 0.0 : 0.04 * math.sin(time * 0.6));
          final opacity2 = 0.12 + (_isTapped ? 0.0 : 0.05 * math.cos(time * 0.4 + math.pi / 6));
          final opacity3 = 0.06 + (_isTapped ? 0.0 : 0.03 * math.sin(time * 0.8 + math.pi / 3));
          final opacity4 = 0.04 + (_isTapped ? 0.0 : 0.025 * math.cos(time * 1.2));
          
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isTapped ? 0.03 : 0.08),
                    blurRadius: _isTapped ? 6 : 12,
                    offset: Offset(0, _isTapped ? 2 : 4),
                  ),
                  if (!_isTapped) ...[
                    BoxShadow(
                      color: cardColors[0].withValues(alpha: 0.06 + 0.03 * math.sin(time * 0.5)),
                      blurRadius: 8 + 3 * math.sin(time * 0.3),
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: cardColors[1].withValues(alpha: 0.04 + 0.02 * math.cos(time * 0.7)),
                      blurRadius: 6 + 2 * math.cos(time * 0.4),
                      offset: const Offset(0, 6),
                    ),
                  ],
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50.r),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          cardColors[0].withValues(alpha: opacity1),
                          cardColors[1].withValues(alpha: opacity2),
                          cardColors[2].withValues(alpha: opacity3),
                          cardColors[0].withValues(alpha: opacity4),
                          cardColors[1].withValues(alpha: opacity1 * 0.4),
                          cardColors[2].withValues(alpha: opacity3 * 0.3),
                          Colors.white.withValues(alpha: 0.98),
                        ],
                        begin: const Alignment(-1.2, -1.2),
                        end: const Alignment(1.2, 1.2),
                        stops: [
                          0.0,
                          math.max(0.1, math.min(0.4, mix1)),
                          math.max(0.2, math.min(0.5, mix2)),
                          math.max(0.3, math.min(0.6, mix3)),
                          math.max(0.4, math.min(0.7, mix4)),
                          math.max(0.6, math.min(0.8, mix5)),
                          math.max(0.7, math.min(0.9, mix1 * 0.8)),
                          1.0,
                        ],
                      ),
                      border: Border.all(
                        color: cardColors[0].withValues(alpha: 0.25 + (_isTapped ? 0.0 : 0.1 * math.sin(time * 0.8))),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    child: Row(
                      children: [
                        // Enhanced animated podcast image
                        Hero(
                          tag: 'favorite_podcast_${widget.podcast.title}',
                          child: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25.r),
                              boxShadow: [
                                BoxShadow(
                                  color: cardColors[0].withValues(
                                    alpha: 0.15 + (_isTapped ? 0.0 : 0.06 * math.sin(time * 0.4))
                                  ),
                                  blurRadius: 4 + (_isTapped ? 0.0 : 2 * math.sin(time * 0.3)),
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25.r),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        cardColors[0],
                                        cardColors[1].withValues(
                                          alpha: 0.9 + (_isTapped ? 0.0 : 0.08 * math.sin(time * 0.4))
                                        ),
                                        cardColors[2].withValues(
                                          alpha: 0.95 + (_isTapped ? 0.0 : 0.04 * math.cos(time * 0.6))
                                        ),
                                      ],
                                      begin: const Alignment(-1.0, -1.0),
                                      end: const Alignment(1.0, 1.0),
                                      stops: [
                                        0.0,
                                        0.4 + (_isTapped ? 0.0 : 0.08 * math.sin(time * 0.5)),
                                        1.0,
                                      ],
                                    ),
                                  ),
                                  child: widget.podcast.imageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: widget.podcast.imageUrl,
                                          width: 50.w,
                                          height: 50.w,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) => Icon(
                                            Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 24.w,
                                          ),
                                        )
                                      : Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 24.w,
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.podcast.title,
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1D1D1F),
                                  letterSpacing: -0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                widget.podcast.category,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF86868B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        
                        // Action buttons with same size
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // play button only
                            GestureDetector(
                              onTap: widget.onPlay,
                              child: Container(
                                width: 36.w,
                                height: 36.w,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 20.w,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            );
        },
      ),
    );
  }
}
