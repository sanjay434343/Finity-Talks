import 'package:finitytalks/screens/login_page.dart';
import 'package:finitytalks/screens/player_page.dart';
import 'package:finitytalks/screens/profile_page.dart';
import 'package:finitytalks/screens/space_detail_page.dart'; // Add this import
import 'package:finitytalks/screens/favorites_page.dart'; // Add this import
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:animations/animations.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/finity_app_bar.dart';
import '../services/auth_service.dart';
import '../utils/shared_preferences_helper.dart';
import '../services/wikipedia_service.dart';
import '../services/nasa_service.dart';
import '../services/horoscope_service.dart';
import '../services/sentiment_service.dart';
import '../models/sentiment_model.dart';
import '../blocs/home/home_bloc.dart';
import '../blocs/home/home_event.dart';
import '../blocs/home/home_state.dart';
import '../screens/book_detail_page.dart';
import '../services/quote_service.dart';
import '../screens/daily_quote_page.dart';
import '../services/favorites_service.dart';
import '../services/music_service.dart';
import '../models/music_model.dart';
import '../screens/music_player_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late HomeBloc _homeBloc;
  static HomeBloc? _staticHomeBloc; // Static bloc to persist across navigations

  // NASA space pictures variables with caching
  List<NasaApod> spaceImages = [];
  bool isLoadingSpaceImages = false;
  static List<NasaApod>? _cachedSpaceImages;
  static DateTime? _lastSpaceImagesCacheTime;
  static const Duration _spaceImagesCacheValidDuration = Duration(hours: 6);

  // Horoscope variables with caching
  HoroscopeData? todayHoroscope;
  bool isLoadingHoroscope = false;
  String selectedSign = 'aries'; // Default sign
  SentimentModel? horoscopeSentiment;
  static HoroscopeData? _cachedHoroscope;
  static SentimentModel? _cachedHoroscopeSentiment;
  static DateTime? _lastHoroscopeCacheTime;
  static String? _lastCachedSign;
  static const Duration _horoscopeCacheValidDuration = Duration(hours: 12);

  // Music variables with caching
  List<MusicTrack> musicTracks = [];
  bool isLoadingMusic = false;
  static List<MusicTrack>? _cachedMusicTracks;
  static DateTime? _lastMusicCacheTime;
  static const Duration _musicCacheValidDuration = Duration(hours: 6);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Reuse existing bloc if available to maintain state
    if (_staticHomeBloc != null) {
      _homeBloc = _staticHomeBloc!;
    } else {
      _homeBloc = HomeBloc();
      _staticHomeBloc = _homeBloc;
      _homeBloc.add(HomeInitialized());
    }

    // Load cached data first, then refresh in background
    _loadCachedData();
    
    // Load user's zodiac sign and horoscope
    _loadUserZodiacSign();
    
    // Load NASA space images (cached first, then refresh)
    _loadSpaceImages();
    
    // Load music tracks
    _loadMusicTracks();
  }

  void _loadCachedData() {
    // Load cached space images if available
    if (_cachedSpaceImages != null && _isSpaceImagesCacheValid()) {
      setState(() {
        spaceImages = _cachedSpaceImages!;
      });
    }
    
    // Load cached horoscope if available
    if (_cachedHoroscope != null && _isHoroscopeCacheValid() && _lastCachedSign == selectedSign) {
      setState(() {
        todayHoroscope = _cachedHoroscope;
        horoscopeSentiment = _cachedHoroscopeSentiment;
      });
    }
    
    // Load cached music tracks if available
    if (_cachedMusicTracks != null && _isMusicCacheValid()) {
      setState(() {
        musicTracks = _cachedMusicTracks!;
      });
    }
  }

  static bool _isSpaceImagesCacheValid() {
    if (_cachedSpaceImages == null || _lastSpaceImagesCacheTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastSpaceImagesCacheTime!) < _spaceImagesCacheValidDuration;
  }

  static bool _isHoroscopeCacheValid() {
    if (_cachedHoroscope == null || _lastHoroscopeCacheTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastHoroscopeCacheTime!) < _horoscopeCacheValidDuration;
  }

  static bool _isMusicCacheValid() {
    if (_cachedMusicTracks == null || _lastMusicCacheTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastMusicCacheTime!) < _musicCacheValidDuration;
  }

  @override
  void dispose() {
    // Don't close the bloc on dispose to keep it alive
    super.dispose();
  }

  Future<void> _loadSpaceImages() async {
    // Show cached data immediately if available
    if (_cachedSpaceImages != null && _isSpaceImagesCacheValid()) {
      setState(() {
        spaceImages = _cachedSpaceImages!;
      });
      // Don't show loading if we have cached data
      return;
    }

    setState(() {
      isLoadingSpaceImages = true;
    });

    try {
      final images = await NasaService.getRecentApods(count: 3);
      
      // Cache the results
      _cachedSpaceImages = images;
      _lastSpaceImagesCacheTime = DateTime.now();
      
      setState(() {
        spaceImages = images;
        isLoadingSpaceImages = false;
      });
    } catch (e) {
      setState(() {
        isLoadingSpaceImages = false;
      });
      print('Failed to load space images: $e');
    }
  }

  Future<void> _loadUserZodiacSign() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedSign = prefs.getString('user_zodiac_sign') ?? 'aries';
      setState(() {
        selectedSign = savedSign;
      });
      
      // Load cached horoscope if it matches the current sign
      if (_cachedHoroscope != null && _isHoroscopeCacheValid() && _lastCachedSign == savedSign) {
        setState(() {
          todayHoroscope = _cachedHoroscope;
          horoscopeSentiment = _cachedHoroscopeSentiment;
        });
      }
      
      _loadTodayHoroscope();
    } catch (e) {
      print('Failed to load user zodiac sign: $e');
      _loadTodayHoroscope();
    }
  }

  Future<void> _loadTodayHoroscope() async {
    // Show cached data immediately if available and valid
    if (_cachedHoroscope != null && _isHoroscopeCacheValid() && _lastCachedSign == selectedSign) {
      setState(() {
        todayHoroscope = _cachedHoroscope;
        horoscopeSentiment = _cachedHoroscopeSentiment;
      });
      // Don't show loading if we have cached data
      return;
    }

    setState(() {
      isLoadingHoroscope = true;
    });

    try {
      final horoscope = await HoroscopeService.getTodayHoroscope(selectedSign);
      
      // Analyze sentiment
      SentimentModel? sentiment;
      if (horoscope != null && horoscope.horoscope.isNotEmpty) {
        sentiment = SentimentService.analyzeHoroscope(horoscope.horoscope);
      }
      
      // Cache the results
      _cachedHoroscope = horoscope;
      _cachedHoroscopeSentiment = sentiment;
      _lastHoroscopeCacheTime = DateTime.now();
      _lastCachedSign = selectedSign;
      
      setState(() {
        todayHoroscope = horoscope;
        horoscopeSentiment = sentiment;
        isLoadingHoroscope = false;
      });
    } catch (e) {
      setState(() {
        isLoadingHoroscope = false;
        horoscopeSentiment = null;
      });
      print('Failed to load horoscope: $e');
    }
  }

  Future<void> _saveUserZodiacSign(String sign) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_zodiac_sign', sign);
      setState(() {
        selectedSign = sign;
      });
      _loadTodayHoroscope();
    } catch (e) {
      print('Failed to save zodiac sign: $e');
    }
  }

  Future<void> _loadMusicTracks() async {
    // Show cached data immediately if available
    if (_cachedMusicTracks != null && _isMusicCacheValid()) {
      setState(() {
        musicTracks = _cachedMusicTracks!;
      });
      return;
    }

    setState(() {
      isLoadingMusic = true;
    });

    try {
      final tracks = await MusicService.getRecommendedTracks();
      
      // Ensure we have exactly 3 different tracks
      final uniqueTracks = <String, MusicTrack>{};
      for (final track in tracks) {
        final key = '${track.trackName.toLowerCase()}_${track.artistName.toLowerCase()}';
        if (!uniqueTracks.containsKey(key) && uniqueTracks.length < 3) {
          uniqueTracks[key] = track;
        }
      }
      
      final finalTracks = uniqueTracks.values.toList();
      
      // Cache the results
      _cachedMusicTracks = finalTracks;
      _lastMusicCacheTime = DateTime.now();
      
      setState(() {
        musicTracks = finalTracks;
        isLoadingMusic = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMusic = false;
      });
      print('Failed to load music tracks: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    const isDarkMode = false;
    
    return BlocProvider.value(
      value: _homeBloc, // Use .value to provide existing bloc
      child: BlocListener<HomeBloc, HomeState>(
        listener: (context, state) {
          if (state is HomeError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else if (state is HomeEpisodeAction) {
            Color backgroundColor;
            switch (state.actionType) {
              case HomeActionType.played:
                backgroundColor = AppColors.primaryBlue;
                break;
              case HomeActionType.shared:
                backgroundColor = AppColors.success;
                break;
              case HomeActionType.saved:
                backgroundColor = AppColors.success;
                break;
              case HomeActionType.removed:
                backgroundColor = AppColors.warning;
                break;
              case HomeActionType.refreshed:
                backgroundColor = AppColors.success;
                break;
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: backgroundColor,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Colors.white, // Pure white background
            body: _HomePageBody(
              spaceImages: spaceImages,
              isLoadingSpaceImages: isLoadingSpaceImages,
              onLoadSpaceImages: _loadSpaceImages,
              todayHoroscope: todayHoroscope,
              isLoadingHoroscope: isLoadingHoroscope,
              selectedSign: selectedSign,
              onSignChanged: _saveUserZodiacSign,
              horoscopeSentiment: horoscopeSentiment,
              musicTracks: musicTracks,
              isLoadingMusic: isLoadingMusic,
              onLoadMusic: _loadMusicTracks,
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePageBody extends StatelessWidget {
  final List<NasaApod> spaceImages;
  final bool isLoadingSpaceImages;
  final VoidCallback onLoadSpaceImages;
  final HoroscopeData? todayHoroscope;
  final bool isLoadingHoroscope;
  final String selectedSign;
  final Function(String) onSignChanged;
  final SentimentModel? horoscopeSentiment;
  final List<MusicTrack> musicTracks;
  final bool isLoadingMusic;
  final VoidCallback onLoadMusic;

  const _HomePageBody({
    this.spaceImages = const [],
    this.isLoadingSpaceImages = false,
    required this.onLoadSpaceImages,
    this.todayHoroscope,
    this.isLoadingHoroscope = false,
    required this.selectedSign,
    required this.onSignChanged,
    this.horoscopeSentiment,
    this.musicTracks = const [],
    this.isLoadingMusic = false,
    required this.onLoadMusic,
  });

  // Enhanced static cache variables with persistent storage simulation
  static List<WikipediaEpisode>? _cachedEpisodes;
  static DateTime? _lastCacheTime;
  static const Duration _cacheValidDuration = Duration(hours: 1);
  static Map<String, List<Color>> _episodeColorCache = {};
  static Map<String, Widget> _builtCardCache = {}; // Cache built cards
  static Map<String, bool> _cardTapStates = {}; // Track card tap states
  
  // Book suggestions cache with daily persistence
  static List<BookSuggestion>? _cachedBooks;
  static DateTime? _lastBooksFetch;
  static DateTime? _lastBookCacheTime; // Add this missing variable
  static String? _lastBookCacheDate;
  static const Duration _booksCacheDuration = Duration(hours: 1);

  // New: Episode content cache to avoid re-fetching Wikipedia content
  static Map<String, WikipediaEpisode> _episodeContentCache = {};
  static DateTime? _lastEpisodeContentCacheTime;
  static const Duration _episodeContentCacheValidDuration = Duration(hours: 2);

  @override
  Widget build(BuildContext context) {
    const isDarkMode = false;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white, // Pure white background
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            const FinityAppBar(),
            
            // Main Content with RefreshIndicator
            Expanded(
              child: BlocBuilder<HomeBloc, HomeState>(
                builder: (context, state) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 12.h),
                        
                        // Welcome Section
                        _buildWelcomeSection(isDarkMode, context),
                        
                        SizedBox(height: 20.h),
                        
                        // Today's Horoscope Section
                        _buildHoroscopeSection(isDarkMode),
                        
                        SizedBox(height: 20.h),
                        
                        // Recent Talks Section
                        _buildRecentTalks(isDarkMode, state),
                        
                        SizedBox(height: 24.h),
                        
                        // Book Suggestions Section
                        _buildBookSuggestions(isDarkMode),
                        
                        SizedBox(height: 16.h),
                        
                        // NASA Space Pictures Section
                        _buildSpaceImagesSection(context),
                        
                        SizedBox(height: 20.h),
                        
                        // Music Recommendations Section
                        _buildMusicSection(context),
                        
                        SizedBox(height: 20.h),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add cache management methods
  static void _clearCache() {
    _cachedEpisodes = null;
    _lastCacheTime = null;
  }

  static bool _isCacheValid() {
    if (_cachedEpisodes == null || _lastCacheTime == null) {
      return false;
    }
    // Check if cache is still valid and has exactly 3 episodes
    final isTimeValid = DateTime.now().difference(_lastCacheTime!) < _cacheValidDuration;
    final hasCorrectCount = _cachedEpisodes!.length == 3;
    return isTimeValid && hasCorrectCount;
  }

  static bool _isBookCacheValid() {
    if (_cachedBooks == null || _lastBooksFetch == null) {
      return false;
    }
    return DateTime.now().difference(_lastBooksFetch!) < _booksCacheDuration;
  }

  static void _clearBookCache() {
    _cachedBooks = null;
    _lastBooksFetch = null;
  }

  Widget _buildWelcomeSection(bool isDarkMode, BuildContext context) {
    final authService = AuthService();
    final displayName = authService.userDisplayName ?? 'User';
    final photoURL = authService.userPhotoURL;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF95e3e0), // Darker mint green
            Color(0xFFd1b8f8), // Darker lavender
            Color(0xFFc8e3f4), // Darker sky blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(50.r), // Pill shape
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF95e3e0).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // User Profile Section - Now clickable
          GestureDetector(
            onTap: () => _showProfileBottomSheet(context),
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                gradient: const LinearGradient(
                  colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
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
              child: photoURL != null && photoURL.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30.r),
                      child: Image.network(
                        photoURL,
                        width: 60.w,
                        height: 60.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 30.w,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 30.w,
                    ),
            ),
          ),
          SizedBox(width: 16.w),
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: -0.1,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Hello, $displayName!',
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
          SizedBox(width: 12.w),
          // Favorites Heart Button (replaces progress card)
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
              );
            },
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.r),
                gradient: const LinearGradient(
                  colors: [Color(0xFFd1b8f8), Color(0xFF95e3e0)],
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
                  size: 28.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileBottomSheet(BuildContext context) {
    final authService = AuthService();
    final displayName = authService.userDisplayName ?? 'User';
    final email = authService.userEmail ?? 'No email available';
    final photoURL = authService.userPhotoURL;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // Profile Header
            Container(
              padding: EdgeInsets.all(24.w),
              child: Column(
                children: [
                  // Profile Image
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40.r),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: photoURL != null && photoURL.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(40.r),
                            child: Image.network(
                              photoURL,
                              width: 80.w,
                              height: 80.w,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.person_rounded,
                                color: Colors.white,
                                size: 40.w,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 40.w,
                          ),
                  ),
                  SizedBox(height: 16.h),
                  
                  // User Name
                  Text(
                    displayName,
                    style: GoogleFonts.inter(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D1D1F),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  
                  // User Email
                  Text(
                    email,
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF86868B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            // Developer Contact Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF95e3e0).withValues(alpha: 0.1),
                    const Color(0xFFd1b8f8).withValues(alpha: 0.1),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Icon(
                          Icons.code_rounded,
                          color: Colors.white,
                          size: 18.w,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        'Developer Contact',
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1D1D1F),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Built with ❤️ by the FinityTalks team',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF86868B),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'For support or feedback, reach out to us!',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF86868B),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHoroscopeSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Horoscope',
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
                todayHoroscope?.formattedDate ?? 'Today',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7bb3b0),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _buildHoroscopeCard(),
      ],
    );
  }

  Widget _buildHoroscopeCard() {
    if (isLoadingHoroscope) {
      return _buildHoroscopeLoadingCard();
    }

    // Get sentiment colors
    final sentimentColors = horoscopeSentiment != null 
        ? SentimentService.getSentimentColors(horoscopeSentiment!.type)
        : SentimentService.getSentimentColors(SentimentType.moderate);

    return Builder(
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => _showHoroscopeDetail(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(50.r), // Already pill-like, keeping consistent
              border: Border.all(
                color: sentimentColors['primary'].withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: sentimentColors['primary'].withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Zodiac Sign Icon
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        sentimentColors['primary'],
                        sentimentColors['secondary'],
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Center(
                    child: Text(
                      HoroscopeService.getSignDisplayName(selectedSign).split(' ').last,
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                
                // Horoscope Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            HoroscopeService.getSignDisplayName(selectedSign),
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1D1D1F),
                              letterSpacing: -0.1,
                            ),
                          ),
                          if (horoscopeSentiment != null) ...[
                            SizedBox(width: 6.w),
                            Text(
                              horoscopeSentiment!.type.emoji,
                              style: TextStyle(fontSize: 12.sp),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Text(
                            'Today\'s Forecast',
                            style: GoogleFonts.inter(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF86868B),
                            ),
                          ),
                          if (horoscopeSentiment != null) ...[
                            SizedBox(width: 4.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                              decoration: BoxDecoration(
                                color: sentimentColors['background'],
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                horoscopeSentiment!.type.displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w600,
                                  color: sentimentColors['text'],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Expand Icon
                Icon(
                  Icons.chevron_right_rounded,
                  color: sentimentColors['primary'],
                  size: 20.w,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHoroscopeLoadingCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50.r), // Changed from 25.r to 50.r for more pill-like shape
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Loading Zodiac Sign Icon
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
          SizedBox(width: 12.w),
          
          // Loading Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100.w,
                  height: 14.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(7.r),
                  ),
                ),
                SizedBox(height: 4.h),
                Container(
                  width: 80.w,
                  height: 11.h,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(5.5.r),
                  ),
                ),
              ],
            ),
          ),
          
          // Loading Icon
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ],
      ),
    );
  }

  void _showHoroscopeDetail(BuildContext context) {
    if (todayHoroscope == null) return;
    
    final sentimentColors = horoscopeSentiment != null 
        ? SentimentService.getSentimentColors(horoscopeSentiment!.type)
        : SentimentService.getSentimentColors(SentimentType.moderate);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            
            // Header
            Container(
              padding: EdgeInsets.all(20.w),
              child: Row(
                children: [
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          sentimentColors['primary'],
                          sentimentColors['secondary'],
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                    child: Center(
                      child: Text(
                        HoroscopeService.getSignDisplayName(selectedSign).split(' ').last,
                        style: GoogleFonts.inter(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          HoroscopeService.getSignDisplayName(selectedSign),
                          style: GoogleFonts.inter(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1D1D1F),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Text(
                              todayHoroscope!.formattedDate,
                              style: GoogleFonts.inter(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF86868B),
                              ),
                            ),
                            if (horoscopeSentiment != null) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: sentimentColors['background'],
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      horoscopeSentiment!.type.emoji,
                                      style: TextStyle(fontSize: 10.sp),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      horoscopeSentiment!.type.displayName,
                                      style: GoogleFonts.inter(
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.w600,
                                        color: sentimentColors['text'],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: const Color(0xFF86868B),
                        size: 16.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Forecast',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1D1D1F),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: sentimentColors['background'],
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: sentimentColors['primary'].withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        todayHoroscope!.horoscope,
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1D1D1F),
                          height: 1.5,
                        ),
                      ),
                    ),
                    
                    if (horoscopeSentiment != null) ...[
                      SizedBox(height: 16.h),
                      Text(
                        'Sentiment Analysis',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1D1D1F),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              horoscopeSentiment!.type.emoji,
                              style: TextStyle(fontSize: 20.sp),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${horoscopeSentiment!.type.displayName} Outlook',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: sentimentColors['text'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add color extraction method
  Future<List<Color>> _extractDominantColors(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return [
        const Color(0xFF95e3e0),
        const Color(0xFFc8e3f4),
        const Color(0xFFd1b8f8),
      ];
    }

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frame = await codec.getNextFrame();
        final ui.Image image = frame.image;

        // Convert image to bytes for color extraction
        final ByteData? byteData = await image.toByteData();
        if (byteData != null) {
          final pixels = byteData.buffer.asUint8List();
          return _analyzeImageColors(pixels, image.width, image.height);
        }
      }
    } catch (e) {
      // If color extraction fails, return default colors
    }

    return [
      const Color(0xFF95e3e0),
      const Color(0xFFc8e3f4),
      const Color(0xFFd1b8f8),
    ];
  }

  List<Color> _analyzeImageColors(Uint8List pixels, int width, int height) {
    Map<String, int> colorCounts = {};
    
    // Sample every 10th pixel to improve performance
    for (int i = 0; i < pixels.length; i += 40) { // 4 bytes per pixel * 10
      if (i + 3 < pixels.length) {
        int r = pixels[i];
        int g = pixels[i + 1];
        int b = pixels[i + 2];
        int a = pixels[i + 3];
        
        // Skip transparent pixels
        if (a < 128) continue;
        
        // Group similar colors by reducing precision
        r = (r ~/ 32) * 32;
        g = (g ~/ 32) * 32;
        b = (b ~/ 32) * 32;
        
        String colorKey = '$r,$g,$b';
        colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
      }
    }

    // Sort colors by frequency and take top 10
    List<MapEntry<String, int>> sortedColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Color> dominantColors = [];
    for (int i = 0; i < sortedColors.length && i < 10; i++) {
      List<String> rgb = sortedColors[i].key.split(',');
      int r = int.parse(rgb[0]);
      int g = int.parse(rgb[1]);
      int b = int.parse(rgb[2]);
      
      // Ensure colors are not too dark or too light
      if ((r + g + b) > 100 && (r + g + b) < 600) {
        dominantColors.add(Color.fromRGBO(r, g, b, 1.0));
      }
    }

    // If no suitable colors found, return defaults
    if (dominantColors.isEmpty) {
      return [
        const Color(0xFF95e3e0),
        const Color(0xFFc8e3f4),
        const Color(0xFFd1b8f8),
      ];
    }

    // Ensure we have at least 3 colors for gradient
    while (dominantColors.length < 3) {
      dominantColors.add(dominantColors.first);
    }

    return dominantColors.take(3).toList();
  }

  Widget _buildPodcastCard(bool isDarkMode, WikipediaEpisode episode, int index, bool isSaved, bool isCurrentlyPlaying, BuildContext context) {
    // Always use cached colors if available to prevent shimmer
    final cachedColors = _episodeColorCache[episode.title];
    
    if (cachedColors != null) {
      return _PersistentAnimatedCard(
        key: ValueKey('persistent_${episode.title}_${isSaved}_${isCurrentlyPlaying}'),
        episode: episode,
        cardColors: cachedColors,
        isSaved: isSaved,
        isCurrentlyPlaying: isCurrentlyPlaying,
        onTap: () {
          // Mark card as tapped to prevent state changes
          _cardTapStates[episode.title] = true;
          
          Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => PlayerPage(
                episode: episode,
                preExtractedColors: cachedColors, // Pass the cached colors
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeInOut)),
                  ),
                  child: child,
                );
              },
              transitionDuration: const Duration(milliseconds: 300),
            ),
          ).then((_) {
            // Reset tap state when returning
            _cardTapStates[episode.title] = false;
          });
          
          context.read<HomeBloc>().add(HomeEpisodeSelected(episode));
        },
      );
    }

    // Extract colors and cache them immediately
    return FutureBuilder<List<Color>>(
      future: _extractDominantColors(episode.imageUrl),
      builder: (context, colorSnapshot) {
        List<Color> cardColors;
        
        if (colorSnapshot.hasData) {
          cardColors = colorSnapshot.data!;
          // Cache colors immediately when available
          _episodeColorCache[episode.title] = cardColors;
        } else {
          // Use default colors while loading
          cardColors = [
            const Color(0xFF95e3e0),
            const Color(0xFFc8e3f4),
            const Color(0xFFd1b8f8),
          ];
        }

        return _PersistentAnimatedCard(
          key: ValueKey('persistent_${episode.title}_${isSaved}_${isCurrentlyPlaying}'),
          episode: episode,
          cardColors: cardColors,
          isSaved: isSaved,
          isCurrentlyPlaying: isCurrentlyPlaying,
          onTap: () {
            // Mark card as tapped to prevent state changes
            _cardTapStates[episode.title] = true;
            
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => PlayerPage(
                  episode: episode,
                  preExtractedColors: cardColors, // Pass the colors even if still loading
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeInOut)),
                    ),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            ).then((_) {
              // Reset tap state when returning
              _cardTapStates[episode.title] = false;
            });
            
            context.read<HomeBloc>().add(HomeEpisodeSelected(episode));
          },
        );
      },
    );
  }

  Future<List<BookSuggestion>> _getBookSuggestions() async {
    final today = DateTime.now().toIso8601String().substring(0, 10); // YYYY-MM-DD format
    
    // Check if we have valid cached books for today
    if (_isBookCacheValid() && 
        _cachedBooks != null && 
        _lastBookCacheDate == today) {
      return _cachedBooks!;
    }

    try {
      // Get user's selected categories
      final userCategories = await _getUserSelectedCategories();
      
      if (userCategories.isEmpty) {
        // Return cached books even if no categories are selected
        return _cachedBooks ?? [];
      }
      
      // Use a combination of date and category to ensure same books for the day
      final dateBasedSeed = today.hashCode;
      final randomGenerator = math.Random(dateBasedSeed);
      final categoryIndex = randomGenerator.nextInt(userCategories.length);
      final selectedCategory = userCategories[categoryIndex];
      
      final response = await http.get(
        Uri.parse('https://openlibrary.org/search.json?q=$selectedCategory&limit=20'),
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final docs = data['docs'] as List;
        
        // Use date-based random to get consistent books for the day
        final availableBooks = docs
            .where((doc) => 
                doc['title'] != null && 
                doc['author_name'] != null && 
                doc['cover_i'] != null)
            .toList();
        
        if (availableBooks.length >= 3) {
          // Shuffle with date-based seed to get same 3 books for the day
          availableBooks.shuffle(randomGenerator);
          
          final books = availableBooks
              .take(3) // Always exactly 3 books
              .map((doc) => BookSuggestion(
                    title: doc['title'] as String,
                    author: (doc['author_name'] as List).first as String,
                    coverUrl: 'https://covers.openlibrary.org/b/id/${doc['cover_i']}-M.jpg',
                    key: doc['key'] as String,
                  ))
              .toList();

          // Cache the results with today's date
          _cachedBooks = books;
          _lastBookCacheTime = DateTime.now();
          _lastBookCacheDate = today;
          
          return books;
        }
      }
    } catch (e) {
      // Return cached books on error if available
      if (_cachedBooks != null) {
        return _cachedBooks!;
      }
    }
    
    return [];
  }

  Future<List<String>> _getUserSelectedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedCategories = prefs.getStringList('selected_categories') ?? [];
      
      // Map UI category names to search-friendly terms
      final categoryMap = {
        'Technology': 'technology',
        'Science': 'science',
        'History': 'history',
        'Philosophy': 'philosophy',
        'Art': 'art',
        'Music': 'music',
        'Literature': 'literature',
        'Psychology': 'psychology',
        'Business': 'business',
        'Health': 'health',
        'Politics': 'politics',
        'Sports': 'sports',
      };
      
      return selectedCategories
          .map((category) => categoryMap[category] ?? category.toLowerCase())
          .toList();
    } catch (e) {
      return [];
    }
  }

  Widget _buildBookCard(BookSuggestion book, int index, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => BookDetailPage(book: book),
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
        width: 100.w, // Reduced width for book-like proportions
        margin: EdgeInsets.only(right: 20.w), // Increased from 12.w to 20.w
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Book Cover with Hero animation - rectangular like a real book
            Hero(
              tag: 'book_cover_${book.key}',
              child: Container(
                width: 100.w,
                height: 140.h, // Book-like proportions (5:7 ratio)
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8.r), // Less rounded for book look
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                    // Add a subtle side shadow for book depth
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: Stack(
                    children: [
                      // Book image filling the entire container
                      SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.network(
                          book.coverUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: double.infinity,
                            height: double.infinity,
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
                      // Daily special overlay
                      if (index == 0) // First book gets special treatment
                        Positioned(
                          top: 4.w,
                          right: 4.w,
                          child: Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 12.w,
                              ),
                            ),
                          ),
                        ),
                      // Book spine effect (subtle gradient on the left)
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 3.w,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
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
            // Book Title - Single line only
            SizedBox(
              width: 100.w, // Match the book width
              child: Text(
                book.title,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1D1D1F),
                  letterSpacing: -0.1,
                ),
                maxLines: 2, // Allow 2 lines for title
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 2.h),
            // Author
            SizedBox(
              width: 100.w, // Match the book width
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

  Widget _buildBookLoadingState() {
    return SizedBox(
      height: 200.h, // Increased height to accommodate taller books
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3, // Show exactly 3 loading cards
        itemBuilder: (context, index) => Container(
          width: 100.w, // Match book width
          margin: EdgeInsets.only(right: 20.w), // Increased from 12.w to 20.w
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100.w,
                height: 140.h, // Match book height
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

  Widget _buildBookEmptyState() {
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
              Icons.book_outlined,
              color: Colors.grey[400],
              size: 32.w,
            ),
            SizedBox(height: 8.h),
            Text(
              'No books available',
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

  Widget _buildBookSuggestions(bool isDarkMode) {
    return FutureBuilder<bool>(
      future: _hasSelectedCategories(),
      builder: (context, categorySnapshot) {
        if (!categorySnapshot.hasData || categorySnapshot.data != true) {
          // Still show cached books even if no categories are selected
          if (_cachedBooks != null && _cachedBooks!.isNotEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recommended Books',
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
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        'Cached suggestions',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 200.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _cachedBooks!.length,
                    itemBuilder: (context, index) {
                      final book = _cachedBooks![index];
                      return _buildBookCard(book, index, context);
                    },
                  ),
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recommended Books',
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
                    'Based on your interests',
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
            FutureBuilder<List<BookSuggestion>>(
              future: _getBookSuggestions(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Show cached books while loading if available
                  if (_cachedBooks != null && _cachedBooks!.isNotEmpty) {
                    return SizedBox(
                      height: 200.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cachedBooks!.length,
                        itemBuilder: (context, index) {
                          final book = _cachedBooks![index];
                          return _buildBookCard(book, index, context);
                        },
                      ),
                    );
                  }
                  return _buildBookLoadingState();
                }
                
                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  // Show cached books on error if available
                  if (_cachedBooks != null && _cachedBooks!.isNotEmpty) {
                    return SizedBox(
                      height: 200.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _cachedBooks!.length,
                        itemBuilder: (context, index) {
                          final book = _cachedBooks![index];
                          return _buildBookCard(book, index, context);
                        },
                      ),
                    );
                  }
                  return _buildBookEmptyState();
                }
                
                return SizedBox(
                  height: 200.h,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final book = snapshot.data![index];
                      return _buildBookCard(book, index, context);
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48.w,
            color: Colors.grey,
          ),
          SizedBox(height: 16.h),
          Text(
            'No episodes available',
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.darkGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(bool isDarkMode) {
    return Column(
      children: List.generate(3, (index) => Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    height: 12.h,
                    width: 100.w,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(6.r),
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

  Widget _buildRecentTalks(bool isDarkMode, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Today\'s Episodes',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1D1D1F),
                letterSpacing: -0.3,
              ),
            ),
            FutureBuilder<bool>(
              future: _hasSelectedCategories(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data == true) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: const Color(0xFFc8e3f4).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      'Based on your interests',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF85b8d0),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _buildEpisodesContent(isDarkMode, state),
      ],
    );
  }

  Future<bool> _hasSelectedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('has_selected_categories') ?? false;
    } catch (e) {
      return false;
    }
  }

  Widget _buildEpisodesContent(bool isDarkMode, HomeState state) {
    return Builder(
      builder: (BuildContext context) {
        if (state is HomeLoading) {
          if (_cachedEpisodes != null && _cachedEpisodes!.isNotEmpty) {
            final limitedEpisodes = _cachedEpisodes!.take(3).toList();
            return Column(
              children: limitedEpisodes.asMap().entries.map((entry) {
                final index = entry.key;
                final episode = entry.value;
                final isSaved = false;
                final isCurrentlyPlaying = false;
                
                return _buildPodcastCard(isDarkMode, episode, index, isSaved, isCurrentlyPlaying, context);
              }).toList(),
            );
          }
          return _buildLoadingState(isDarkMode);
        } else if (state is HomeLoaded) {
          return FutureBuilder<List<WikipediaEpisode>>(
            future: _filterEpisodesByContentLength(state.episodes),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                if (_cachedEpisodes != null && _cachedEpisodes!.isNotEmpty) {
                  final limitedEpisodes = _cachedEpisodes!.take(3).toList();
                  return Column(
                    children: limitedEpisodes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final episode = entry.value;
                      final isSaved = state.savedEpisodes.any((savedEp) => savedEp.title == episode.title);
                      final isCurrentlyPlaying = state.currentlyPlaying?.title == episode.title;
                      
                      return _buildPodcastCard(isDarkMode, episode, index, isSaved, isCurrentlyPlaying, context);
                    }).toList(),
                  );
                }
                return _buildLoadingState(isDarkMode);
              }
              
              final filteredEpisodes = snapshot.data ?? [];
              final limitedEpisodes = filteredEpisodes.take(3).toList();
              
              if (limitedEpisodes.isEmpty) {
                return _buildEmptyState(isDarkMode);
              }
              
              return Column(
                children: limitedEpisodes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final episode = entry.value;
                  final isSaved = state.savedEpisodes.any((savedEp) => savedEp.title == episode.title);
                  final isCurrentlyPlaying = state.currentlyPlaying?.title == episode.title;
                  
                  return _buildPodcastCard(isDarkMode, episode, index, isSaved, isCurrentlyPlaying, context);
                }).toList(),
              );
            },
          );
        } else if (state is HomeError) {
          if (_cachedEpisodes != null && _cachedEpisodes!.isNotEmpty) {
            final limitedEpisodes = _cachedEpisodes!.take(3).toList();
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  margin: EdgeInsets.only(bottom: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.orange[200]!, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cached_rounded, color: Colors.orange[600], size: 14.w),
                      SizedBox(width: 4.w),
                      Text(
                        'Showing cached content',
                        style: GoogleFonts.inter(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                ),
                ...limitedEpisodes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final episode = entry.value;
                  final isSaved = false;
                  final isCurrentlyPlaying = false;
                  
                  return _buildPodcastCard(isDarkMode, episode, index, isSaved, isCurrentlyPlaying, context);
                }).toList(),
              ],
            );
          }
          return _buildErrorState(isDarkMode, state.message);
        } else {
          return _buildEmptyState(isDarkMode);
        }
      },
    );
  }

  Future<List<WikipediaEpisode>> _filterEpisodesByContentLength(List<WikipediaEpisode> episodes) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    
    if (_isCacheValid() && _cachedEpisodes != null && _cachedEpisodes!.length == 3) {
      return _cachedEpisodes!;
    }

    final dateBasedSeed = today.hashCode;
    final randomGenerator = math.Random(dateBasedSeed);
    
    final List<WikipediaEpisode> validEpisodes = [];
    final Set<String> usedTitles = <String>{};
    
    final shuffledEpisodes = List<WikipediaEpisode>.from(episodes);
    shuffledEpisodes.shuffle(randomGenerator);
    
    int attempts = 0;
    final maxAttempts = episodes.length * 2;
    
    for (final episode in shuffledEpisodes) {
      if (attempts >= maxAttempts) break;
      attempts++;
      
      if (usedTitles.contains(episode.title.toLowerCase())) {
        continue;
      }
      
      final cachedEpisode = _episodeContentCache[episode.title];
      if (cachedEpisode != null && _isEpisodeContentCacheValid()) {
        validEpisodes.add(cachedEpisode);
        usedTitles.add(episode.title.toLowerCase());
      } else {
        final episodeWithContent = await _checkEpisodeContentLength(episode);
        if (episodeWithContent != null) {
          _episodeContentCache[episode.title] = episodeWithContent;
          _lastEpisodeContentCacheTime = DateTime.now();
          
          validEpisodes.add(episodeWithContent);
          usedTitles.add(episode.title.toLowerCase());
        }
      }
      
      if (validEpisodes.length >= 3) {
        break;
      }
    }
    
    while (validEpisodes.length < 3 && validEpisodes.isNotEmpty) {
      final existingEpisode = validEpisodes[validEpisodes.length % validEpisodes.length];
      final fallbackEpisode = WikipediaEpisode(
        title: "${existingEpisode.title} (Extended)",
        description: existingEpisode.description,
        imageUrl: existingEpisode.imageUrl,
        pageUrl: existingEpisode.pageUrl,
        category: existingEpisode.category,
        duration: existingEpisode.duration,
      );
      validEpisodes.add(fallbackEpisode);
    }
    
    final finalEpisodes = validEpisodes.take(3).toList();
    
    if (finalEpisodes.length == 3) {
      _cachedEpisodes = finalEpisodes;
      _lastCacheTime = DateTime.now();
    }
    
    return finalEpisodes;
  }

  static bool _isEpisodeContentCacheValid() {
    if (_lastEpisodeContentCacheTime == null) {
      return false;
    }
    return DateTime.now().difference(_lastEpisodeContentCacheTime!) < _episodeContentCacheValidDuration;
  }

  Widget _buildErrorState(bool isDarkMode, String message) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48.w,
            color: AppColors.error,
          ),
          SizedBox(height: 16.h),
          Text(
            message,
            style: TextStyle(
              fontSize: 16.sp,
              color: AppColors.darkGrey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ElevatedButton(
            onPressed: () {
              // Retry logic here
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceImagesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Space Pictures of the Day',
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
                'NASA daily images',
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
        if (isLoadingSpaceImages)
          _buildSpaceImagesLoading()
        else if (spaceImages.isNotEmpty)
          _buildSpaceImagesGrid(context)
        else
          _buildSpaceImagesError(),
      ],
    );
  }

  Widget _buildSpaceImagesLoading() {
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
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6366f1).withValues(alpha: 0.1),
                      const Color(0xFF8b5cf6).withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF6366f1),
                    strokeWidth: 2,
                  ),
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

  Widget _buildSpaceImagesGrid(BuildContext context) {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: spaceImages.length,
        itemBuilder: (context, index) {
          final apod = spaceImages[index];
          return _buildSpaceImageCard(apod, index, context);
        },
      ),
    );
  }

  Widget _buildSpaceImageCard(NasaApod apod, int index, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => SpaceDetailPage(
              imageUrl: apod.hdurl ?? apod.url,
              title: apod.title,
              description: apod.explanation,
              date: apod.date,
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
              tag: 'space_${apod.date}',
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
                        imageUrl: apod.url,
                        width: 120.w,
                        height: 120.h,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
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
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6366f1).withValues(alpha: 0.3),
                                const Color(0xFF8b5cf6).withValues(alpha: 0.3),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12.r),
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
                      Positioned(
                        top: 4.w,
                        right: 4.w,
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
                      if (index == 0)
                        Positioned(
                          top: 4.w,
                          left: 4.w,
                          child: Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366f1), Color(0xFF8b5cf6)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366f1).withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.star_rounded,
                                color: Colors.white,
                                size: 12.w,
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
                    apod.title,
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
              apod.date,
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

  Widget _buildSpaceImagesError() {
    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6366f1).withValues(alpha: 0.1),
            const Color(0xFF8b5cf6).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF6366f1).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              color: const Color(0xFF6366f1),
              size: 32.w,
            ),
            SizedBox(height: 8.h),
            Text(
              'Unable to load space images',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6366f1),
              ),
            ),
            SizedBox(height: 4.h),
            GestureDetector(
              onTap: onLoadSpaceImages,
              child: Text(
                'Tap to retry',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF8b5cf6),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMusicSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Music for You',
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
                'iTunes curated',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7bb3b0),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        if (isLoadingMusic)
          _buildMusicLoadingState()
        else if (musicTracks.isNotEmpty)
          _buildMusicGrid(context)
        else
          _buildMusicEmptyState(),
      ],
    );
  }

  Widget _buildMusicLoadingState() {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (context, index) => Container(
          width: 140.w,
          margin: EdgeInsets.only(right: 12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140.w,
                height: 140.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF95e3e0).withValues(alpha: 0.1),
                      const Color(0xFFd1b8f8).withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF95e3e0),
                    strokeWidth: 2,
                  ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMusicGrid(BuildContext context) {
    return SizedBox(
      height: 180.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: musicTracks.length,
        itemBuilder: (context, index) {
          final track = musicTracks[index];
          return _buildMusicCard(track, index, context);
        },
      ),
    );
  }

  Widget _buildMusicCard(MusicTrack track, int index, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Reorder tracks to put the selected track first
        final reorderedTracks = <MusicTrack>[track];
        reorderedTracks.addAll(musicTracks.where((t) => t != track));
        
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => MusicPlayerPage(
              initialTracks: reorderedTracks,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: animation.drive(
                    Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
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
        width: 140.w,
        margin: EdgeInsets.only(right: 12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Art
            Container(
              width: 140.w,
              height: 140.h,
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
                    Image.network(
                      track.artworkUrl600,
                      width: 140.w,
                      height: 140.h,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF95e3e0).withValues(alpha: 0.3),
                              const Color(0xFFd1b8f8).withValues(alpha: 0.3),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
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
                    // Play button overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.all(12.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: const Color(0xFF1D1D1F),
                              size: 24.w,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Genre badge
                    if (index == 0)
                      Positioned(
                        top: 8.w,
                        right: 8.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF95e3e0),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Featured',
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
            SizedBox(height: 8.h),
            // Track Info
            Text(
              track.trackName,
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
              track.artistName,
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

  Widget _buildMusicEmptyState() {
    return Container(
      height: 120.h,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF95e3e0).withValues(alpha: 0.1),
            const Color(0xFFd1b8f8).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: const Color(0xFF95e3e0).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off_rounded,
              color: const Color(0xFF95e3e0),
              size: 32.w,
            ),
            SizedBox(height: 8.h),
            Text(
              'No music tracks available',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF95e3e0),
              ),
            ),
            SizedBox(height: 4.h),
            GestureDetector(
              onTap: onLoadMusic,
              child: Text(
                'Tap to retry',
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFd1b8f8),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<WikipediaEpisode?> _checkEpisodeContentLength(WikipediaEpisode episode) async {
    try {
      // Extract the Wikipedia page title from the episode
      String pageTitle = episode.title;
      
      // Clean up the title for Wikipedia API
      pageTitle = pageTitle.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      
      // Add random parameter to avoid caching
      final randomParam = DateTime.now().millisecondsSinceEpoch.toString();
      
      final response = await http.get(
        Uri.parse('https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&explaintext=true&titles=${Uri.encodeComponent(pageTitle)}&origin=*&_=$randomParam'),
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'];
        
        if (pages != null && pages.isNotEmpty) {
          final pageData = pages.values.first;
          String extract = pageData['extract'] ?? '';
          
          if (extract.isNotEmpty) {
            // Count words in the extract
            final wordCount = extract.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;
            
            // Only include episodes with 150+ words
            if (wordCount >= 150) {
              // Format content into 2-line lyrics style
              final formattedContent = _formatContentAsLyrics(extract);
              
              // Create a new episode with the formatted content
              return WikipediaEpisode(
                title: episode.title,
                description: formattedContent,
                imageUrl: episode.imageUrl,
                pageUrl: episode.pageUrl,
                category: episode.category,
                duration: episode.duration,
              );
            }
          }
        }
      }
    } catch (e) {
      // If there's an error checking content, exclude this episode
      return null;
    }
    
    return null;
  }

  String _formatContentAsLyrics(String content) {
    // Clean up the content
    String cleanContent = content.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Split into sentences
    List<String> sentences = cleanContent.split(RegExp(r'[.!?]+'));
    
    // Take different sentences each time by using a random starting point
    final randomStart = DateTime.now().millisecond % 3;
    
    // Take the first few sentences and format as 2 lines
    List<String> validSentences = sentences
        .skip(randomStart)
        .where((s) => s.trim().isNotEmpty && s.trim().length > 10)
        .take(4)
        .map((s) => s.trim())
        .toList();
    
    if (validSentences.length >= 2) {
      // Combine sentences to create 2 balanced lines
      String line1 = validSentences[0];
      String line2 = validSentences.length > 1 ? validSentences[1] : '';
      
      // Limit line length for better display
      if (line1.length > 80) {
        line1 = line1.substring(0, 77) + '...';
      }
      if (line2.length > 80) {
        line2 = line2.substring(0, 77) + '...';
      }
      
      return '$line1\n$line2';
    } else if (validSentences.isNotEmpty) {
      // If only one sentence, split it roughly in half
      String sentence = validSentences[0];
      if (sentence.length > 80) {
        int midPoint = sentence.length ~/ 2;
        int spaceIndex = sentence.indexOf(' ', midPoint);
        if (spaceIndex != -1) {
          String line1 = sentence.substring(0, spaceIndex);
          String line2 = sentence.substring(spaceIndex + 1);
          return '$line1\n$line2';
        }
      }
      return sentence;
    }
    
    return 'Discover fascinating insights about this topic';
  }
}

class _PersistentAnimatedCard extends StatefulWidget {
  final WikipediaEpisode episode;
  final List<Color> cardColors;
  final bool isSaved;
  final bool isCurrentlyPlaying;
  final VoidCallback onTap;

  const _PersistentAnimatedCard({
    Key? key,
    required this.episode,
    required this.cardColors,
    required this.isSaved,
    required this.isCurrentlyPlaying,
    required this.onTap,
  }) : super(key: key);

  @override
  State<_PersistentAnimatedCard> createState() => _PersistentAnimatedCardState();
}

class _PersistentAnimatedCardState extends State<_PersistentAnimatedCard>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isTapped = false;
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    if (_isDisposed) return;
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    if (!_isDisposed) {
      _animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ));
      
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(_PersistentAnimatedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.episode.title != widget.episode.title && !_isDisposed) {
      _animationController.dispose();
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return GestureDetector(
      onTapDown: (_) {
        if (!_isDisposed) {
          setState(() {
            _isTapped = true;
          });
        }
      },
      onTapUp: (_) {
        if (!_isDisposed) {
          setState(() {
            _isTapped = false;
          });
          widget.onTap();
        }
      },
      onTapCancel: () {
        if (!_isDisposed) {
          setState(() {
            _isTapped = false;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        transform: Matrix4.identity()..scale(_isTapped ? 0.98 : 1.0),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            if (_isDisposed) {
              return const SizedBox.shrink();
            }
            
            final animationValue = _isTapped ? 0.0 : _animation.value;
            final time = animationValue * 2 * math.pi;
            
            final mix1 = 0.3 + 0.15 * math.sin(time * 0.7);
            final mix2 = 0.5 + 0.1 * math.cos(time * 0.5 + math.pi / 4);
            final mix3 = 0.7 + 0.12 * math.sin(time * 0.3 + math.pi / 2);
            final mix4 = 0.2 + 0.08 * math.cos(time * 0.9 + math.pi / 3);
            final mix5 = 0.8 + 0.06 * math.sin(time * 1.1 + math.pi);
            
            final opacity1 = 0.06 + (_isTapped ? 0.0 : 0.025 * math.sin(time * 0.6));
            final opacity2 = 0.08 + (_isTapped ? 0.0 : 0.035 * math.cos(time * 0.4 + math.pi / 6));
            final opacity3 = 0.04 + (_isTapped ? 0.0 : 0.02 * math.sin(time * 0.8 + math.pi / 3));
            final opacity4 = 0.03 + (_isTapped ? 0.0 : 0.015 * math.cos(time * 1.2));
            
            return Container(
              margin: EdgeInsets.only(bottom: 12.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: _isTapped ? 0.02 : 0.05),
                    blurRadius: _isTapped ? 4 : 8,
                    offset: Offset(0, _isTapped ? 1 : 2),
                  ),
                  if (!_isTapped) ...[
                    BoxShadow(
                      color: widget.cardColors[0].withValues(alpha: 0.04 + 0.015 * math.sin(time * 0.5)),
                      blurRadius: 6 + 2 * math.sin(time * 0.3),
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: widget.cardColors[1].withValues(alpha: 0.03 + 0.01 * math.cos(time * 0.7)),
                      blurRadius: 4 + 1.5 * math.cos(time * 0.4),
                      offset: const Offset(0, 4),
                    ),
                  ],
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50.r),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
                  child: Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          widget.cardColors[0].withValues(alpha: opacity1),
                          widget.cardColors[1].withValues(alpha: opacity2),
                          widget.cardColors[2].withValues(alpha: opacity3),
                          widget.cardColors[0].withValues(alpha: opacity4),
                          widget.cardColors[1].withValues(alpha: opacity1 * 0.3),
                          Colors.white.withValues(alpha: 0.98),
                        ],
                        begin: const Alignment(-1.0, -1.0),
                        end: const Alignment(1.0, 1.0),
                        stops: [
                          0.0,
                          math.max(0.1, math.min(0.5, mix1)),
                          math.max(0.2, math.min(0.6, mix2)),
                          math.max(0.4, math.min(0.8, mix3)),
                          math.max(0.3, math.min(0.7, mix4)),
                          math.max(0.6, math.min(0.9, mix5)),
                          1.0,
                        ],
                      ),
                      border: Border.all(
                        color: widget.isCurrentlyPlaying 
                          ? widget.cardColors[0].withValues(
                              alpha: 0.5 + (_isTapped ? 0.0 : 0.08 * (math.sin(time * 0.8) + 1) / 2)
                            )
                          : widget.cardColors[0].withValues(alpha: 0.2),
                        width: widget.isCurrentlyPlaying ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'episode_${widget.episode.title}',
                          child: Container(
                            width: 50.w,
                            height: 50.w,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25.r),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.cardColors[0].withValues(
                                    alpha: 0.12 + (_isTapped ? 0.0 : 0.04 * math.sin(time * 0.4))
                                  ),
                                  blurRadius: 3 + (_isTapped ? 0.0 : 1.5 * math.sin(time * 0.3)),
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25.r),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(sigmaX: 0.3, sigmaY: 0.3),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        widget.cardColors[0],
                                        widget.cardColors[1].withValues(
                                          alpha: 0.9 + (_isTapped ? 0.0 : 0.06 * math.sin(time * 0.4))
                                        ),
                                        widget.cardColors[2].withValues(
                                          alpha: 0.95 + (_isTapped ? 0.0 : 0.03 * math.cos(time * 0.6))
                                        ),
                                        widget.cardColors[0].withValues(
                                          alpha: 0.85 + (_isTapped ? 0.0 : 0.05 * math.sin(time * 0.8))
                                        ),
                                      ],
                                      begin: const Alignment(-1.0, -1.0),
                                      end: const Alignment(1.0, 1.0),
                                      stops: [
                                        0.0,
                                        0.35 + (_isTapped ? 0.0 : 0.06 * math.sin(time * 0.5)),
                                        0.65 + (_isTapped ? 0.0 : 0.05 * math.cos(time * 0.7)),
                                        1.0,
                                      ],
                                    ),
                                  ),
                                  child: widget.episode.imageUrl != null
                                      ? Image.network(
                                          widget.episode.imageUrl!,
                                          width: 50.w,
                                          height: 50.w,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Icon(
                                            widget.isCurrentlyPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                            color: Colors.white,
                                            size: 24.w,
                                          ),
                                        )
                                      : Icon(
                                          widget.isCurrentlyPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
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
                                widget.episode.title,
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
                                widget.episode.description,
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF86868B),
                                  height: 1.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
    );
  }
    }