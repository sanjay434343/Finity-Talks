import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/wikipedia_service.dart';
import '../services/favorites_service.dart';
import '../theme.dart';

class PlayerPage extends StatefulWidget {
  final WikipediaEpisode episode;
  final List<Color>? preExtractedColors; // New parameter for pre-extracted colors
  final bool autoPlay; // New parameter for auto-play

  const PlayerPage({
    Key? key, 
    required this.episode,
    this.preExtractedColors, // Add this parameter
    this.autoPlay = false, // Default to false
  }) : super(key: key);

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with TickerProviderStateMixin {
  late FlutterTts flutterTts;
  late AudioPlayer audioPlayer;
  late AnimationController _animationController;
  late AnimationController _colorAnimationController;
  late ScrollController _scrollController;
  
  bool isPlaying = false;
  bool isLoading = false;
  bool isTtsReady = false; // New: Track TTS readiness
  Duration duration = Duration.zero;
  Duration position = Duration.zero;
  String fullContent = '';
  List<String> formattedLyrics = [];
  List<List<String>> wordsByLine = [];
  int currentLyricIndex = 0;
  Timer? _lineTimer;
  Timer? _positionTimer;
  Timer? _speedBoostTimer; // New: For speed boost effect
  bool isSpeedBoosted = false; // New: Track speed boost state
  
  // Color palette variables
  Color dominantColor = const Color(0xFF6366F1);
  Color accentColor = const Color(0xFF8B5CF6);
  List<Color> gradientColors = [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
  bool colorsExtracted = false;

  bool _isLiked = false;
  bool _isTogglingFavorite = false;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _initializeAnimations();
    _loadEpisodeContent();
    
    // Use pre-extracted colors immediately if available
    if (widget.preExtractedColors != null && widget.preExtractedColors!.isNotEmpty) {
      _applyPreExtractedColors(widget.preExtractedColors!);
    } else {
      _extractColorsFromImage();
    }
    
    _scrollController = ScrollController();
    _checkIfFavorited();
    
    // Auto-play if requested
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _togglePlayPause();
      });
    }
  }

  Future<void> _checkIfFavorited() async {
    try {
      final isFavorited = await FavoritesService.isPodcastFavorited(widget.episode.title);
      if (mounted) {
        setState(() {
          _isLiked = isFavorited;
        });
      }
    } catch (e) {
      print('Error checking if podcast is favorited: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;
    
    setState(() {
      _isTogglingFavorite = true;
    });

    try {
      final wasToggled = await FavoritesService.togglePodcastFavorite(widget.episode);
      
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

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    );
    
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _applyPreExtractedColors(List<Color> colors) {
    setState(() {
      if (colors.isNotEmpty) {
        dominantColor = colors[0];
        accentColor = colors.length > 1 ? colors[1] : colors[0];
        gradientColors = colors.length >= 3 ? colors : [
          colors[0],
          colors.length > 1 ? colors[1] : colors[0].withOpacity(0.8),
          colors[0].withOpacity(0.6),
        ];
      }
      colorsExtracted = true;
    });
    
    // Start color animation immediately
    _colorAnimationController.forward();
  }

  Future<void> _extractColorsFromImage() async {
    // Skip extraction if we already have pre-extracted colors
    if (widget.preExtractedColors != null && widget.preExtractedColors!.isNotEmpty) {
      return;
    }
    
    if (widget.episode.imageUrl != null) {
      try {
        final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
          CachedNetworkImageProvider(widget.episode.imageUrl!),
          maximumColorCount: 20,
        );
        
        setState(() {
          // Extract multiple colors for better gradient
          dominantColor = palette.dominantColor?.color ?? const Color(0xFF6366F1);
          accentColor = palette.vibrantColor?.color ?? 
                      palette.lightVibrantColor?.color ?? 
                      palette.darkVibrantColor?.color ??
                      palette.mutedColor?.color ??
                      const Color(0xFF8B5CF6);
          
          // Create a richer color palette
          List<Color> extractedColors = [];
          if (palette.dominantColor != null) extractedColors.add(palette.dominantColor!.color);
          if (palette.vibrantColor != null) extractedColors.add(palette.vibrantColor!.color);
          if (palette.lightVibrantColor != null) extractedColors.add(palette.lightVibrantColor!.color);
          if (palette.darkVibrantColor != null) extractedColors.add(palette.darkVibrantColor!.color);
          if (palette.mutedColor != null) extractedColors.add(palette.mutedColor!.color);
          
          if (extractedColors.isNotEmpty) {
            gradientColors = [
              extractedColors[0],
              extractedColors.length > 1 ? extractedColors[1] : extractedColors[0].withOpacity(0.8),
              extractedColors.length > 2 ? extractedColors[2] : extractedColors[0].withOpacity(0.6),
              extractedColors[0].withOpacity(0.4),
            ];
          } else {
            gradientColors = [dominantColor, accentColor, dominantColor.withOpacity(0.8)];
          }
          
          colorsExtracted = true;
        });
        
        _colorAnimationController.forward();
      } catch (e) {
        print('Error extracting colors: $e');
      }
    }
  }

  void _initializePlayer() {
    flutterTts = FlutterTts();
    audioPlayer = AudioPlayer();
    
    // Initialize TTS with proper error handling
    _initializeTts();
    
    flutterTts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          isPlaying = false;
          position = Duration.zero;
          currentLyricIndex = 0;
        });
        _animationController.reset();
        _lineTimer?.cancel();
        _positionTimer?.cancel();
      }
    });
    
    // Add error handler
    flutterTts.setErrorHandler((msg) {
      print('TTS Error: $msg');
      if (mounted) {
        setState(() {
          isPlaying = false;
          isLoading = false;
        });
      }
    });
  }

  Future<void> _initializeTts() async {
    try {
      await flutterTts.setLanguage("en-US");
      await flutterTts.setSpeechRate(0.40); // Reduced from 0.50 to 0.40 for slower speech
      await flutterTts.setPitch(1.0);
      await flutterTts.setVolume(1.0);
      
      setState(() {
        isTtsReady = true;
      });
    } catch (e) {
      print('Error initializing TTS: $e');
      setState(() {
        isTtsReady = false;
      });
    }
  }

  Future<void> _loadEpisodeContent() async {
    setState(() => isLoading = true);
    
    try {
      String pageTitle = widget.episode.title;
      pageTitle = pageTitle.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      
      final response = await http.get(
        Uri.parse('https://en.wikipedia.org/w/api.php?action=query&format=json&prop=extracts&explaintext=true&titles=${Uri.encodeComponent(pageTitle)}&origin=*'),
        headers: {
          'User-Agent': 'FinityTalks/1.0 (https://finitytalks.app)',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final pages = data['query']?['pages'];
        
        if (pages != null && pages.isNotEmpty) {
          final pageData = pages.values.first;
          String extract = pageData['extract'] ?? '';
          
          if (extract.isNotEmpty) {
            String cleanedContent = _cleanContent(extract);
            fullContent = _addPausesToContent(cleanedContent);
            formattedLyrics = _formatLyricsWithTwentyToThirtyWords(cleanedContent);
            
            await flutterTts.setLanguage("en-US");
            await flutterTts.setSpeechRate(0.40);
            await flutterTts.setPitch(1.0);
            await flutterTts.setVolume(1.0);
            
            // Adjusted duration calculation for simpler timing
            int wordCount = cleanedContent.split(' ').length;
            int estimatedDuration = (wordCount / 1.6).round(); // 1.6 words per second for 0.40 speed
            duration = Duration(seconds: estimatedDuration + (formattedLyrics.length * 1)); // Reduced pause addition
          }
        }
      }
    } catch (e) {
      print('Error loading content: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  String _addPausesToContent(String content) {
    List<String> words = content.split(' ').where((word) => word.isNotEmpty).toList();
    String contentWithPauses = '';
    
    for (int i = 0; i < words.length; i += 20) {
      int endIndex = (i + 20 < words.length) ? i + 20 : words.length;
      List<String> lineWords = words.sublist(i, endIndex);
      String line = lineWords.join(' ');
      
      contentWithPauses += line;
      
      // Add simple pause between paragraphs (remove SSML markup)
      if (endIndex < words.length) {
        contentWithPauses += '. '; // Simple period and space for natural pause
      }
    }
    
    return contentWithPauses;
  }

  String _cleanContent(String content) {
    return content
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'[^\w\s.,!?-]'), '')
        .trim();
  }

  List<String> _formatLyricsWithTwentyToThirtyWords(String content) {
    List<String> words = content.split(' ').where((word) => word.isNotEmpty).toList();
    List<String> lyrics = [];
    wordsByLine = [];
    
    for (int i = 0; i < words.length; i += 20) {
      int endIndex = (i + 20 < words.length) ? i + 20 : words.length;
      List<String> lineWords = words.sublist(i, endIndex);
      String line = lineWords.join(' ');
      
      lyrics.add(line);
      wordsByLine.add(lineWords);
    }
    
    return lyrics;
  }

  Future<void> _togglePlayPause() async {
    if (isLoading || !isTtsReady || fullContent.isEmpty) return;
    
    HapticFeedback.lightImpact();
    
    try {
      if (isPlaying) {
        await flutterTts.pause();
        _animationController.stop();
        _lineTimer?.cancel();
        _positionTimer?.cancel();
        setState(() {
          isPlaying = false;
        });
      } else {
        setState(() {
          isLoading = true;
        });
        
        // Reset if at the end
        if (currentLyricIndex >= formattedLyrics.length) {
          currentLyricIndex = 0;
          position = Duration.zero;
        }
        
        await flutterTts.speak(fullContent);
        _startLyricSync();
        _animationController.repeat();
        
        setState(() {
          isPlaying = true;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error in toggle play/pause: $e');
      setState(() {
        isPlaying = false;
        isLoading = false;
      });
    }
  }

  void _startLyricSync() {
    if (formattedLyrics.isEmpty || wordsByLine.isEmpty) return;
    
    double wordsPerSecond = 1.6; // Base speed for 0.40 TTS speed
    double wordsPerLine = 20.0;
    double secondsPerLine = wordsPerLine / wordsPerSecond; // 12.5 seconds per line
    double pauseTime = 0.8; // Reduced pause time since we removed SSML
    double speedBoostDuration = 0.5; // Reduced boost duration
    double totalTimePerLine = secondsPerLine + pauseTime + speedBoostDuration;
    
    _lineTimer?.cancel();
    _positionTimer?.cancel();
    _speedBoostTimer?.cancel();
    
    // Start line-by-line timer with better sync
    _lineTimer = Timer.periodic(
      Duration(milliseconds: (totalTimePerLine * 600).round()), // Adjusted timing for no SSML
      (timer) {
        if (!isPlaying || !mounted) {
          timer.cancel();
          return;
        }
        
        setState(() {
          currentLyricIndex++;
          
          // Trigger speed boost effect after each paragraph
          if (currentLyricIndex < formattedLyrics.length) {
            _triggerSpeedBoost();
          }
          
          // Auto-scroll when moving to next line
          _scrollToCurrentLine();
          
          // Check if we've reached the end
          if (currentLyricIndex >= formattedLyrics.length) {
            timer.cancel();
            _handlePlaybackEnd();
            return;
          }
        });
      },
    );
    
    // Start position timer for progress bar
    _positionTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {
        if (!isPlaying || !mounted) {
          timer.cancel();
          return;
        }
        
        setState(() {
          double elapsedLines = currentLyricIndex.toDouble();
          position = Duration(seconds: (elapsedLines * totalTimePerLine * 0.6).round()); // Adjusted for new timing
        });
      },
    );
  }

  void _triggerSpeedBoost() {
    setState(() {
      isSpeedBoosted = true;
    });
    
    // Reset speed boost after shorter duration
    _speedBoostTimer?.cancel();
    _speedBoostTimer = Timer(const Duration(milliseconds: 500), () { // Reduced from 1000ms
      if (mounted) {
        setState(() {
          isSpeedBoosted = false;
        });
      }
    });
  }

  void _handlePlaybackEnd() {
    if (mounted) {
      setState(() {
        isPlaying = false;
        currentLyricIndex = 0;
        position = Duration.zero;
        isSpeedBoosted = false;
      });
      _animationController.reset();
      _lineTimer?.cancel();
      _positionTimer?.cancel();
      _speedBoostTimer?.cancel();
    }
  }

  void _scrollToCurrentLine() {
    if (_scrollController.hasClients && formattedLyrics.isNotEmpty) {
      final itemHeight = 100.h; // Increased height for bigger cards
      
      // Calculate target offset to keep current line at top
      final targetOffset = currentLyricIndex * itemHeight;
      
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _colorAnimationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.3, 0.7, 1.0],
                colors: colorsExtracted ? [
                  gradientColors[0].withOpacity(0.95),
                  gradientColors[1].withOpacity(0.85),
                  gradientColors.length > 2 ? gradientColors[2].withOpacity(0.75) : gradientColors[1].withOpacity(0.75),
                  gradientColors.length > 3 ? gradientColors[3].withOpacity(0.6) : gradientColors[0].withOpacity(0.6),
                ] : [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                  const Color(0xFF6366F1).withOpacity(0.8),
                  const Color(0xFF8B5CF6).withOpacity(0.6),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBarWithImage(),
                  SizedBox(height: 30.h), // Increased spacing
                  Expanded(
                    child: _buildCenteredLyrics(),
                  ),
                  SizedBox(height: 20.h),
                  _buildProgressBar(),
                  SizedBox(height: 20.h),
                  _buildControls(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBarWithImage() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white,
                size: 20.w,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          // Album art on the left
          Hero(
            tag: 'episode_${widget.episode.title}',
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * 2 * 3.14159,
                  child: Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25.r),
                      child: widget.episode.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: widget.episode.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => _buildDefaultAlbumArt(),
                              errorWidget: (context, url, error) => _buildDefaultAlbumArt(),
                            )
                          : _buildDefaultAlbumArt(),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(width: 12.w),
          // Title and info on the right
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.episode.title,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  'FinityTalks Podcast',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Heart button
          GestureDetector(
            onTap: _isTogglingFavorite ? null : () {
              HapticFeedback.lightImpact();
              _toggleFavorite();
            },
            child: Container(
              width: 36.w,
              height: 36.w,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: _isTogglingFavorite
                  ? SizedBox(
                      width: 16.w,
                      height: 16.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.7),
                        ),
                      ),
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        key: ValueKey(_isLiked),
                        color: _isLiked ? Colors.red : Colors.white,
                        size: 20.w,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colorsExtracted ? [
            gradientColors[0],
            gradientColors[1],
          ] : [
            const Color(0xFF6366F1),
            const Color(0xFF8B5CF6),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.podcasts_rounded,
          color: Colors.white,
          size: 20.w,
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          Container(
            height: 3.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1.5.r),
              color: Colors.white.withOpacity(0.3),
            ),
            child: LinearProgressIndicator(
              value: duration.inSeconds > 0 ? position.inSeconds / duration.inSeconds : 0.0,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 3.h,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
              Text(
                _formatDuration(duration),
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: Icons.skip_previous_rounded,
            size: 28.w,
            onTap: () {
              HapticFeedback.lightImpact();
              _resetToBeginning();
            },
          ),
          _buildControlButton(
            icon: Icons.replay_10_rounded,
            size: 24.w,
            onTap: () {
              HapticFeedback.lightImpact();
              _rewind10Seconds();
            },
          ),
          GestureDetector(
            onTap: (isLoading || !isTtsReady) ? null : _togglePlayPause,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                color: (isLoading || !isTtsReady) ? Colors.white.withOpacity(0.5) : Colors.white,
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: colorsExtracted ? dominantColor.withOpacity(0.4) : Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                isLoading 
                    ? Icons.hourglass_empty_rounded
                    : !isTtsReady
                        ? Icons.error_outline_rounded
                        : isPlaying 
                            ? Icons.pause_rounded 
                            : Icons.play_arrow_rounded,
                color: (isLoading || !isTtsReady) 
                    ? Colors.grey 
                    : colorsExtracted 
                        ? dominantColor 
                        : const Color(0xFF6366F1),
                size: 30.w,
              ),
            ),
          ),
          _buildControlButton(
            icon: Icons.forward_10_rounded,
            size: 24.w,
            onTap: () {
              HapticFeedback.lightImpact();
              _forward10Seconds();
            },
          ),
          _buildControlButton(
            icon: Icons.skip_next_rounded,
            size: 28.w,
            onTap: () {
              HapticFeedback.lightImpact();
              // Next functionality
            },
          ),
        ],
      ),
    );
  }

  void _resetToBeginning() {
    setState(() {
      currentLyricIndex = 0;
      position = Duration.zero;
    });
    // Scroll to the very beginning
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300), 
      curve: Curves.easeOut
    );
  }

  void _rewind10Seconds() {
    if (position.inSeconds > 10) {
      int newSeconds = position.inSeconds - 10;
      _jumpToPosition(Duration(seconds: newSeconds));
    } else {
      _resetToBeginning();
    }
  }

  void _forward10Seconds() {
    int newSeconds = (position.inSeconds + 10).clamp(0, duration.inSeconds);
    _jumpToPosition(Duration(seconds: newSeconds));
  }

  void _jumpToPosition(Duration newPosition) {
    double wordsPerSecond = 1.6;
    double wordsPerLine = 20.0;
    double secondsPerLine = wordsPerLine / wordsPerSecond;
    double pauseTime = 0.8; // Match the reduced pause time
    double speedBoostDuration = 0.5; // Match the reduced boost duration
    double totalTimePerLine = (secondsPerLine + pauseTime + speedBoostDuration) * 0.6; // Match the 60% timing
    
    int targetLineIndex = (newPosition.inSeconds / totalTimePerLine).round();
    
    setState(() {
      currentLyricIndex = targetLineIndex.clamp(0, formattedLyrics.length - 1);
      position = newPosition;
      isSpeedBoosted = false; // Reset speed boost on manual jump
    });
    
    _scrollToCurrentLine();
  }

  Widget _buildControlButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.w,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size,
        ),
      ),
    );
  }

  @override
  Widget _buildCenteredLyrics() {
    if (formattedLyrics.isEmpty) {
      return Center(
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: colorsExtracted ? accentColor.withOpacity(0.3) : Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            'Loading lyrics...',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.only(
        top: 20.h,
        bottom: MediaQuery.of(context).size.height * 0.8,
        left: 24.w,
        right: 24.w,
      ),
      physics: const BouncingScrollPhysics(),
      itemCount: formattedLyrics.length,
      itemBuilder: (context, index) {
        bool isActive = index == currentLyricIndex;
        bool isPast = index < currentLyricIndex;
        bool isNext = index == currentLyricIndex + 1;
        
        return Container(
          margin: EdgeInsets.symmetric(vertical: 8.h),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: isActive 
                ? Colors.white.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: _buildWordByWordText(index, isActive, isPast, isNext),
        );
      },
    );
  }

  Widget _buildWordByWordText(int lineIndex, bool isActive, bool isPast, bool isNext) {
    Color textColor;
    FontWeight textWeight;
    double textSize;
    
    if (isActive) {
      textColor = Colors.white;
      textWeight = FontWeight.w700;
      textSize = 16.sp;
    } else if (isPast) {
      textColor = Colors.white.withOpacity(0.4);
      textWeight = FontWeight.w500;
      textSize = 14.sp;
    } else if (isNext) {
      textColor = Colors.white.withOpacity(0.7);
      textWeight = FontWeight.w500;
      textSize = 14.sp;
    } else {
      textColor = Colors.white.withOpacity(0.5);
      textWeight = FontWeight.w400;
      textSize = 13.sp;
    }
    
    return Text(
      formattedLyrics[lineIndex],
      style: GoogleFonts.inter(
        fontSize: textSize,
        fontWeight: textWeight,
        color: textColor,
        height: 1.5,
      ),
      textAlign: TextAlign.left, // Changed to left alignment
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _animationController.dispose();
    _colorAnimationController.dispose();
    _scrollController.dispose();
    _lineTimer?.cancel();
    _positionTimer?.cancel();
    _speedBoostTimer?.cancel();
    flutterTts.stop();
    audioPlayer.dispose();
    super.dispose();
  }
}
