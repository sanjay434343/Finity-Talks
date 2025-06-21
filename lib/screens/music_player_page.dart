import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:async';
import '../models/music_model.dart';
import '../models/favorite_item.dart'; // Add this import
import '../services/music_service.dart';
import '../services/favorites_service.dart'; // Add this import

class MusicPlayerPage extends StatefulWidget {
  final List<MusicTrack>? initialTracks;

  const MusicPlayerPage({Key? key, this.initialTracks}) : super(key: key);

  @override
  State<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends State<MusicPlayerPage>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late AnimationController _colorTransitionController;
  late AnimationController _buttonColorController;
  late AnimationController _slideController;
  late AnimationController _heartController;
  late PageController _pageController;
  
  // Stream subscriptions for proper disposal
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<void>? _playerCompleteSubscription;
  
  List<MusicTrack> tracks = [];
  int currentTrackIndex = 0;
  bool isPlaying = false;
  bool isLoading = true;
  bool _isDisposed = false;
  bool _isSliding = false;
  bool _isPageTransitioning = false; // Add page transition flag
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  
  // Color palette variables
  List<Color> currentPalette = [
    const Color(0xFFF8F9FA),
    const Color(0xFF95e3e0),
    const Color(0xFFd1b8f8),
    const Color(0xFF6C757D),
  ];
  List<Color> previousPalette = [
    const Color(0xFFF8F9FA),
    const Color(0xFF95e3e0),
    const Color(0xFFd1b8f8),
    const Color(0xFF6C757D),
  ];
  Map<String, List<Color>> colorCache = {};

  // New feature flags
  bool isShuffled = false;
  bool isRepeating = false;
  bool isLiked = false;
  bool showVolume = false;
  bool showLyrics = false;
  double volume = 0.7;
  List<int> originalTrackOrder = [];
  
  // Enhanced visual features
  bool isBuffering = false;
  String currentQuality = 'High';

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _initializePlayer();
    _setupAnimations();
    _loadTracks();
  }

  void _initializePlayer() {
    _audioPlayer = AudioPlayer();
    
    // Use proper stream subscriptions for better lifecycle management
    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((PlayerState state) {
      if (!_isDisposed && mounted) {
        setState(() {
          isPlaying = state == PlayerState.playing;
        });
        
        if (isPlaying) {
          _rotationController.repeat();
          _waveController.repeat();
        } else {
          _rotationController.stop();
          _waveController.stop();
        }
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((Duration position) {
      if (!_isDisposed && mounted) {
        setState(() {
          currentPosition = position;
        });
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (!_isDisposed && mounted) {
        setState(() {
          totalDuration = duration;
        });
      }
    });

    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((_) {
      if (!_isDisposed && mounted) {
        _playNext();
      }
    });
  }

  void _setupAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    );

    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _colorTransitionController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _buttonColorController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _heartController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  Future<List<Color>> _extractColorsFromImage(String imageUrl) async {
    if (_isDisposed) return currentPalette;
    
    // Check cache first
    if (colorCache.containsKey(imageUrl)) {
      return colorCache[imageUrl]!;
    }

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200 && !_isDisposed) {
        final Uint8List bytes = response.bodyBytes;
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frame = await codec.getNextFrame();
        final ui.Image image = frame.image;

        final ByteData? byteData = await image.toByteData();
        if (byteData != null && !_isDisposed) {
          final pixels = byteData.buffer.asUint8List();
          final colors = _analyzeImageColors(pixels, image.width, image.height);
          
          // Cache the result
          colorCache[imageUrl] = colors;
          return colors;
        }
      }
    } catch (e) {
      print('Error extracting colors: $e');
    }

    // Return default light palette if extraction fails
    return [
      const Color(0xFFF8F9FA),
      const Color(0xFF95e3e0),
      const Color(0xFFd1b8f8),
      const Color(0xFF6C757D),
    ];
  }

  List<Color> _analyzeImageColors(Uint8List pixels, int width, int height) {
    Map<String, int> colorCounts = {};
    
    // Sample every 8th pixel for performance
    for (int i = 0; i < pixels.length; i += 32) { // 4 bytes per pixel * 8
      if (i + 3 < pixels.length) {
        int r = pixels[i];
        int g = pixels[i + 1];
        int b = pixels[i + 2];
        int a = pixels[i + 3];
        
        if (a < 128) continue; // Skip transparent pixels
        
        // Group similar colors
        r = (r ~/ 24) * 24;
        g = (g ~/ 24) * 24;
        b = (b ~/ 24) * 24;
        
        String colorKey = '$r,$g,$b';
        colorCounts[colorKey] = (colorCounts[colorKey] ?? 0) + 1;
      }
    }

    // Sort colors by frequency
    List<MapEntry<String, int>> sortedColors = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<Color> dominantColors = [];
    for (int i = 0; i < sortedColors.length && dominantColors.length < 8; i++) {
      List<String> rgb = sortedColors[i].key.split(',');
      int r = int.parse(rgb[0]);
      int g = int.parse(rgb[1]);
      int b = int.parse(rgb[2]);
      
      // Ensure colors are suitable for light theme
      double brightness = (r * 0.299 + g * 0.587 + b * 0.114) / 255;
      if (brightness > 0.1 && brightness < 0.9) {
        dominantColors.add(Color.fromRGBO(r, g, b, 1.0));
      }
    }

    if (dominantColors.length < 4) {
      // Add default colors if not enough extracted
      dominantColors.addAll([
        const Color(0xFF95e3e0),
        const Color(0xFFd1b8f8),
        const Color(0xFFc8e3f4),
        const Color(0xFFF1C2E6),
      ]);
    }

    // Create a light theme palette
    return [
      const Color(0xFFF8F9FA), // Background
      _lightenColor(dominantColors[0], 0.3), // Primary light
      _lightenColor(dominantColors[1], 0.2), // Secondary light
      _darkenColor(dominantColors[0], 0.6), // Text/accent
    ];
  }

  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(math.min(1.0, hsl.lightness + amount)).toColor();
  }

  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(math.max(0.0, hsl.lightness - amount)).toColor();
  }

  Future<void> _updateColorsForCurrentTrack() async {
    if (tracks.isEmpty || _isDisposed) return;
    
    final newColors = await _extractColorsFromImage(tracks[currentTrackIndex].artworkUrl600);
    
    if (!_isDisposed && mounted) {
      setState(() {
        previousPalette = List.from(currentPalette);
      });
      
      _colorTransitionController.forward(from: 0.0);
      _buttonColorController.forward(from: 0.0);
      
      setState(() {
        currentPalette = newColors;
      });
    }
  }

  Future<void> _loadTracks() async {
    if (_isDisposed) return;
    
    try {
      if (mounted) {
        setState(() {
          isLoading = true;
        });
      }

      List<MusicTrack> loadedTracks;
      if (widget.initialTracks != null && widget.initialTracks!.isNotEmpty) {
        loadedTracks = widget.initialTracks!;
      } else {
        loadedTracks = await MusicService.getRecommendedTracks();
      }

      if (!_isDisposed && mounted) {
        setState(() {
          tracks = loadedTracks;
          isLoading = false;
        });

        if (tracks.isNotEmpty) {
          await _updateColorsForCurrentTrack();
          _loadCurrentTrack();
        }
      }
    } catch (e) {
      if (!_isDisposed && mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCurrentTrack() async {
    if (tracks.isEmpty || _isDisposed) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.setSourceUrl(tracks[currentTrackIndex].previewUrl);
      if (!_isDisposed) {
        await _updateColorsForCurrentTrack();
        await _checkIfLiked(); // Check if track is liked when loading
      }
    } catch (e) {
      print('Error loading track: $e');
    }
  }

  Future<void> _playPause() async {
    if (_isDisposed) return;
    
    try {
      if (isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      print('Error playing/pausing: $e');
    }
  }

  Future<void> _slideToNext() async {
    if (_isSliding || _isPageTransitioning || currentTrackIndex >= tracks.length - 1) return;
    
    setState(() {
      _isSliding = true;
      _isPageTransitioning = true;
    });
    
    // Animate to next page
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
    
    setState(() {
      _isSliding = false;
      _isPageTransitioning = false;
    });
  }

  Future<void> _slideToPrevious() async {
    if (_isSliding || _isPageTransitioning || currentTrackIndex <= 0) return;
    
    setState(() {
      _isSliding = true;
      _isPageTransitioning = true;
    });
    
    // Animate to previous page
    await _pageController.previousPage(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
    
    setState(() {
      _isSliding = false;
      _isPageTransitioning = false;
    });
  }

  void _toggleLike() async {
    if (tracks.isEmpty) return;
    final currentTrack = tracks[currentTrackIndex];

    setState(() {
      isLiked = !isLiked;
    });

    if (isLiked) {
      final favoriteMusic = FavoriteMusic(
        title: currentTrack.trackName,
        artist: currentTrack.artistName,
        composer: currentTrack.artistName,    // use artistName as composer
        musicUrl: currentTrack.previewUrl,    // store the URL
        imageUrl: currentTrack.artworkUrl600,
        createdAt: DateTime.now(),
      );
      await FavoritesService.saveFavoriteMusic(favoriteMusic);
      _heartController.forward().then((_) => _heartController.reverse());
    } else {
      await FavoritesService.removeFavoriteMusic(
        currentTrack.trackName,
        currentTrack.artistName,
      );
    }
  }

  Future<void> _checkIfLiked() async {
    if (tracks.isEmpty) return;
    
    final currentTrack = tracks[currentTrackIndex];
    final liked = await FavoritesService.isMusicFavorited(
      currentTrack.trackName,
      currentTrack.artistName,
    );
    
    if (mounted) {
      setState(() {
        isLiked = liked;
      });
    }
  }

  Future<void> _onPageChanged(int page) async {
    if (_isDisposed || page == currentTrackIndex) return;
    
    setState(() {
      currentTrackIndex = page;
    });
    
    // Load new track
    await _loadCurrentTrack();
    
    // Check if new track is liked
    await _checkIfLiked();
    
    if (!_isDisposed) {
      await _audioPlayer.resume();
    }
  }

  Future<void> _toggleShuffle() async {
    setState(() {
      isShuffled = !isShuffled;
    });
    
    if (isShuffled) {
      // Save original order
      originalTrackOrder = List.generate(tracks.length, (index) => index);
      // Shuffle tracks
      final currentTrack = tracks[currentTrackIndex];
      tracks.shuffle();
      currentTrackIndex = tracks.indexOf(currentTrack);
    } else {
      // Restore original order
      if (originalTrackOrder.isNotEmpty) {
        final currentTrack = tracks[currentTrackIndex];
        tracks = originalTrackOrder.map((index) => tracks[index]).toList();
        currentTrackIndex = tracks.indexOf(currentTrack);
      }
    }
    
    // Update page controller
    await _pageController.animateToPage(
      currentTrackIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleRepeat() {
    setState(() {
      isRepeating = !isRepeating;
    });
  }

  Future<void> _setVolume(double newVolume) async {
    setState(() {
      volume = newVolume;
    });
    await _audioPlayer.setVolume(volume);
  }

  Future<void> _playNext() async {
    if (tracks.isEmpty || _isDisposed) return;
    
    if (isRepeating && !isShuffled) {
      // Just replay current track
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.resume();
      return;
    }
    
    // Check if we're at the last track
    if (currentTrackIndex >= tracks.length - 1) {
      // All music ended, close the player and go to home
      Navigator.pop(context);
      return;
    }
    
    await _slideToNext();
  }

  Future<void> _playPrevious() async {
    if (tracks.isEmpty || _isDisposed) return;
    await _slideToPrevious();
  }

  // Enhanced swipe handling methods
  void _handleSwipeUp() async {
    if (_isSliding || _isPageTransitioning) return;
    
    if (currentTrackIndex > 0) {
      await _slideToPrevious();
    } else {
      Navigator.pop(context);
    }
  }

  void _handleSwipeDown() async {
    if (_isSliding || _isPageTransitioning) return;
    
    if (currentTrackIndex < tracks.length - 1) {
      await _slideToNext();
    } else {
      Navigator.pop(context);
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: currentPalette[1],
            strokeWidth: 3,
          ),
          SizedBox(height: 24.h),
          Text(
            'Loading your music...',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: currentPalette[3],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: currentPalette[1].withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_off_rounded,
              size: 64.w,
              color: currentPalette[3].withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No music tracks found',
            style: GoogleFonts.inter(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: currentPalette[3],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try selecting some interests in your profile',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: currentPalette[3].withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppBar([List<Color>? colors]) {
    final paletteColors = colors ?? currentPalette;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25.r),
                border: Border.all(color: paletteColors[3].withValues(alpha: 0.1)),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: paletteColors[3],
                size: 24.w,
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  'PLAYING FROM',
                  style: GoogleFonts.inter(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w500,
                    color: paletteColors[3].withValues(alpha: 0.6),
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'FinityTalks Radio',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: paletteColors[3],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 2.h),
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: paletteColors[1].withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    currentQuality,
                    style: GoogleFonts.inter(
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w600,
                      color: paletteColors[3],
                    ),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _toggleLike,
            child: AnimatedBuilder(
              animation: _heartController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_heartController.value * 0.3),
                  child: Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: isLiked 
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(25.r),
                      border: Border.all(
                        color: isLiked 
                            ? Colors.red.withValues(alpha: 0.3)
                            : paletteColors[3].withValues(alpha: 0.1),
                      ),
                    ),
                    child: Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      color: isLiked ? Colors.red : paletteColors[3],
                      size: 20.w,
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

  Widget _buildEnhancedAlbumArt(MusicTrack track, [List<Color>? colors]) {
    final paletteColors = colors ?? currentPalette;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Main album art
        Container(
          width: 280.w,
          height: 280.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: -10,
              ),
              BoxShadow(
                color: paletteColors[1].withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: track.artworkUrl600,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => _buildAlbumPlaceholder(paletteColors),
                  errorWidget: (context, url, error) => _buildAlbumPlaceholder(paletteColors),
                ),
                
                // Overlay effects
                if (isPlaying)
                  Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [
                          Colors.transparent,
                          paletteColors[1].withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                
                // Loading indicator
                if (isBuffering)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Play button overlay for paused state
        if (!isPlaying)
          GestureDetector(
            onTap: _playPause,
            child: Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40.w,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAlbumPlaceholder(List<Color> paletteColors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            paletteColors[1].withValues(alpha: 0.3),
            paletteColors[2].withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: paletteColors[3].withValues(alpha: 0.6),
          size: 80.w,
        ),
      ),
    );
  }

  Widget _buildTrackPage(MusicTrack track, List<Color> colors, bool isCurrentPage) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          
          // Enhanced Album Art
          _buildEnhancedAlbumArt(track, colors),
          
          SizedBox(height: 32.h), // Increased spacing since waveform is removed
          
          // Track Info
          _buildTrackInfo(track, colors),
          
          SizedBox(height: 24.h),
          
          // Progress Bar (only for current track)
          if (isCurrentPage) _buildProgressBar(colors),
          
          SizedBox(height: 32.h),
          
          // Enhanced Playback Controls
          _buildEnhancedControls(colors),
          
          const Spacer(flex: 1),
          
          // Enhanced Swipe indicator
          _buildEnhancedSwipeIndicator(colors),
        ],
      ),
    );
  }

  Widget _buildPlayerContentWithPages([List<Color>? animatedColors]) {
    if (_isDisposed || tracks.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final colors = animatedColors ?? currentPalette;
    
    return SafeArea(
      child: Column(
        children: [
          // Enhanced App Bar
          _buildEnhancedAppBar(colors),
          
          // Main Content with PageView - Add pull-down gesture to close
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                // Handle vertical pull-down gesture to close
                if (details.delta.dy > 3) {
                  _slideController.value = math.min(1.0, _slideController.value + 0.02);
                }
              },
              onPanEnd: (details) {
                // Close page if pulled down enough or with sufficient velocity
                if (_slideController.value > 0.3 || details.velocity.pixelsPerSecond.dy > 800) {
                  Navigator.pop(context);
                } else {
                  _slideController.reverse();
                }
              },
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                onPageChanged: _onPageChanged,
                physics: const BouncingScrollPhysics(),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final isCurrentPage = index == currentTrackIndex;
                  
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        value = _pageController.page! - index;
                        value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                      }
                      
                      return Transform.scale(
                        scale: value,
                        child: Opacity(
                          opacity: value,
                          child: _buildTrackPage(track, colors, isCurrentPage),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // Cancel all stream subscriptions
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    
    // Dispose audio player
    _audioPlayer.dispose();
    
    // Dispose animation controllers
    _rotationController.dispose();
    _waveController.dispose();
    _colorTransitionController.dispose();
    _buttonColorController.dispose();
    _slideController.dispose();
    _heartController.dispose();
    
    // Dispose page controller
    _pageController.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: AnimatedBuilder(
          animation: Listenable.merge([_colorTransitionController, _slideController]),
          builder: (context, child) {
            final t = _colorTransitionController.value;
            final slideT = _slideController.value;
            
            final animatedColors = [
              Color.lerp(previousPalette[0], currentPalette[0], t)!,
              Color.lerp(previousPalette[1], currentPalette[1], t)!,
              Color.lerp(previousPalette[2], currentPalette[2], t)!,
              Color.lerp(previousPalette[3], currentPalette[3], t)!,
            ];
            
            return Transform.translate(
              offset: Offset(0, -slideT * MediaQuery.of(context).size.height * 0.05),
              child: Transform.scale(
                scale: 1.0 - (slideT * 0.02),
                child: Opacity(
                  opacity: 1.0 - (slideT * 0.1),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          animatedColors[0],
                          animatedColors[1].withValues(alpha: 0.1),
                          animatedColors[2].withValues(alpha: 0.05),
                          animatedColors[0],
                        ],
                      ),
                    ),
                    child: isLoading
                        ? _buildLoadingState()
                        : tracks.isEmpty
                            ? _buildEmptyState()
                            : _buildPlayerContentWithPages(animatedColors),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrackInfo(MusicTrack track, [List<Color>? colors]) {
    final paletteColors = colors ?? currentPalette;
    
    return Column(
      children: [
        Text(
          track.trackName,
          style: GoogleFonts.inter(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: paletteColors[3],
            height: 1.2,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 6.h),
        Text(
          track.artistName,
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
            color: paletteColors[3].withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildProgressBar([List<Color>? colors]) {
    final paletteColors = colors ?? currentPalette;
    
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.w),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 16.w),
            activeTrackColor: paletteColors[3],
            inactiveTrackColor: paletteColors[3].withValues(alpha: 0.2),
            thumbColor: paletteColors[3],
            overlayColor: paletteColors[3].withValues(alpha: 0.1),
          ),
          child: Slider(
            value: totalDuration.inMilliseconds > 0 
                ? currentPosition.inMilliseconds.toDouble().clamp(0.0, totalDuration.inMilliseconds.toDouble())
                : 0.0,
            max: totalDuration.inMilliseconds.toDouble(),
            onChanged: (value) async {
              if (!_isDisposed) {
                final position = Duration(milliseconds: value.toInt());
                await _audioPlayer.seek(position);
              }
            },
          ),
        ),
        SizedBox(height: 8.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(currentPosition),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: paletteColors[3].withValues(alpha: 0.6),
                ),
              ),
              Text(
                _formatDuration(totalDuration),
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: paletteColors[3].withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedSwipeIndicator([List<Color>? colors]) {
    final paletteColors = colors ?? currentPalette;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        children: [
          // Page dots indicator only
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(tracks.length, (index) {
              final isActive = index == currentTrackIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 2.w),
                width: isActive ? 16.w : 6.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: isActive 
                      ? paletteColors[3]
                      : paletteColors[3].withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildEnhancedControls([List<Color>? colors]) {
    final paletteColors = colors ?? currentPalette;
    
    return Column(
      children: [
        // Main playback controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Shuffle
            GestureDetector(
              onTap: _toggleShuffle,
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isShuffled 
                      ? paletteColors[1].withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.r),
                  border: isShuffled 
                      ? Border.all(color: paletteColors[1])
                      : null,
                ),
                child: Icon(
                  Icons.shuffle_rounded,
                  color: isShuffled ? paletteColors[1] : paletteColors[3].withValues(alpha: 0.7),
                  size: 20.w,
                ),
              ),
            ),
            
            // Previous
            GestureDetector(
              onTap: _playPrevious,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: paletteColors[2].withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.skip_previous_rounded,
                  color: paletteColors[3],
                  size: 28.w,
                ),
              ),
            ),
            
            // Play/Pause
            GestureDetector(
              onTap: _playPause,
              child: AnimatedBuilder(
                animation: _buttonColorController,
                builder: (context, child) {
                  final buttonT = _buttonColorController.value;
                  final buttonColor = Color.lerp(previousPalette[3], paletteColors[3], buttonT)!;
                  final iconColor = Color.lerp(previousPalette[0], paletteColors[0], buttonT)!;
                  
                  return Container(
                    width: 70.w,
                    height: 70.w,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          buttonColor,
                          buttonColor.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: buttonColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: iconColor,
                        size: 35.w,
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Next
            GestureDetector(
              onTap: _playNext,
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: paletteColors[2].withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.skip_next_rounded,
                  color: paletteColors[3],
                  size: 28.w,
                ),
              ),
            ),
            
            // Repeat
            GestureDetector(
              onTap: _toggleRepeat,
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isRepeating 
                      ? paletteColors[1].withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(25.r),
                  border: isRepeating 
                      ? Border.all(color: paletteColors[1])
                      : null,
                ),
                child: Icon(
                  isRepeating ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  color: isRepeating ? paletteColors[1] : paletteColors[3].withValues(alpha: 0.7),
                  size: 20.w,
                ),
              ),
            ),
          ],
        ),
        
        // Volume control
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: showVolume ? 60.h : 0,
          child: showVolume ? Container(
            margin: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
            child: Row(

              children: [                Icon(
                  Icons.volume_down_rounded,
                  color: paletteColors[3].withValues(alpha: 0.7),
                  size: 20.w,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4.h,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8.w),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 16.w),
                      activeTrackColor: paletteColors[1],
                      inactiveTrackColor: paletteColors[3].withValues(alpha: 0.2),
                      thumbColor: paletteColors[1],
                    ),
                    child: Slider(
                      value: volume,
                      onChanged: _setVolume,
                    ),
                  ),
                ),
                Icon(
                  Icons.volume_up_rounded,
                  color: paletteColors[3].withValues(alpha: 0.7),
                  size: 20.w,
                ),
              ],
            ),
          ) : const SizedBox.shrink(),
        ),
      ],
    );
  }
}