import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import '../models/favorite_item.dart';
import '../services/wikipedia_service.dart';
import '../screens/player_page.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:convert';

class FavoritePodcastDetailPage extends StatefulWidget {
  final FavoritePodcast podcast;

  const FavoritePodcastDetailPage({
    Key? key,
    required this.podcast,
  }) : super(key: key);

  @override
  State<FavoritePodcastDetailPage> createState() => _FavoritePodcastDetailPageState();
}

class _FavoritePodcastDetailPageState extends State<FavoritePodcastDetailPage>
    with TickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late AnimationController _colorAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _colorAnimation;
  double _scrollOffset = 0.0;
  
  String? _fullContent;
  bool _isLoadingContent = false;
  bool _isContentExpanded = false;
  
  // Color palette extracted from image
  List<Color> _extractedColors = [];
  bool _isExtractingColors = true;
  Color _dominantColor = const Color(0xFF95e3e0);
  Color _accentColor = const Color(0xFFd1b8f8);
  Color _backgroundColor = Colors.white;
  Color _textColor = const Color(0xFF1D1D1F);
  Color _subtleColor = const Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _colorAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _colorAnimationController, curve: Curves.easeInOut),
    );

    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    _animationController.forward();
    _loadDetailedContent();
    _extractImageColors();
  }

  Future<void> _extractImageColors() async {
    setState(() {
      _isExtractingColors = true;
    });

    try {
      final colors = await _getImageColorPalette(widget.podcast.imageUrl);
      if (colors.isNotEmpty) {
        setState(() {
          _extractedColors = colors;
          _dominantColor = colors[0];
          _accentColor = colors.length > 1 ? colors[1] : colors[0];
          _backgroundColor = _generateBackgroundColor(colors);
          _textColor = _generateTextColor(_backgroundColor);
          _subtleColor = _generateSubtleColor(colors);
          _isExtractingColors = false;
        });
        
        _colorAnimationController.forward();
      }
    } catch (e) {
      print('Failed to extract colors: $e');
      setState(() {
        _isExtractingColors = false;
      });
    }
  }

  Future<List<Color>> _getImageColorPalette(String imageUrl) async {
    if (imageUrl.isEmpty) {
      return [
        const Color(0xFF95e3e0),
        const Color(0xFFd1b8f8),
        const Color(0xFFc8e3f4),
      ];
    }

    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;
        final ui.Codec codec = await ui.instantiateImageCodec(bytes);
        final ui.FrameInfo frame = await codec.getNextFrame();
        final ui.Image image = frame.image;

        final ByteData? byteData = await image.toByteData();
        if (byteData != null) {
          final pixels = byteData.buffer.asUint8List();
          return _analyzeImageForPalette(pixels, image.width, image.height);
        }
      }
    } catch (e) {
      print('Error extracting colors: $e');
    }

    return [
      const Color(0xFF95e3e0),
      const Color(0xFFd1b8f8),
      const Color(0xFFc8e3f4),
    ];
  }

  List<Color> _analyzeImageForPalette(Uint8List pixels, int width, int height) {
    Map<String, ColorInfo> colorCounts = {};
    
    // Sample every 8th pixel for better performance
    for (int i = 0; i < pixels.length; i += 32) { // 4 bytes per pixel * 8
      if (i + 3 < pixels.length) {
        int r = pixels[i];
        int g = pixels[i + 1];
        int b = pixels[i + 2];
        int a = pixels[i + 3];
        
        // Skip transparent and very dark/light pixels
        if (a < 128 || (r + g + b) < 50 || (r + g + b) > 700) continue;
        
        // Group similar colors by reducing precision
        r = (r ~/ 20) * 20;
        g = (g ~/ 20) * 20;
        b = (b ~/ 20) * 20;
        
        String colorKey = '$r,$g,$b';
        if (colorCounts.containsKey(colorKey)) {
          colorCounts[colorKey]!.count++;
        } else {
          colorCounts[colorKey] = ColorInfo(
            color: Color.fromRGBO(r, g, b, 1.0),
            count: 1,
            brightness: (r + g + b) / 3,
            saturation: _calculateSaturation(r, g, b),
          );
        }
      }
    }

    // Sort by frequency and filter by quality
    List<ColorInfo> sortedColors = colorCounts.values.toList()
      ..sort((a, b) {
        // Prioritize colors with good saturation and frequency
        double scoreA = a.count * a.saturation;
        double scoreB = b.count * b.saturation;
        return scoreB.compareTo(scoreA);
      });

    List<Color> palette = [];
    Set<String> usedHues = {};
    
    for (ColorInfo colorInfo in sortedColors) {
      if (palette.length >= 10) break;
      
      // Ensure color diversity by checking hue difference
      String hueGroup = _getHueGroup(colorInfo.color);
      if (!usedHues.contains(hueGroup) || palette.length < 3) {
        palette.add(colorInfo.color);
        usedHues.add(hueGroup);
      }
    }

    // Ensure we have at least 3 colors
    while (palette.length < 3) {
      palette.add(_generateComplementaryColor(palette.isNotEmpty ? palette.first : const Color(0xFF95e3e0)));
    }

    return palette;
  }

  double _calculateSaturation(int r, int g, int b) {
    double rNorm = r / 255.0;
    double gNorm = g / 255.0;
    double bNorm = b / 255.0;
    
    double max = math.max(math.max(rNorm, gNorm), bNorm);
    double min = math.min(math.min(rNorm, gNorm), bNorm);
    
    return max == 0 ? 0 : (max - min) / max;
  }

  String _getHueGroup(Color color) {
    HSVColor hsv = HSVColor.fromColor(color);
    int hueGroup = (hsv.hue / 30).floor(); // Group into 12 hue ranges
    return hueGroup.toString();
  }

  Color _generateComplementaryColor(Color baseColor) {
    HSVColor hsv = HSVColor.fromColor(baseColor);
    return hsv.withHue((hsv.hue + 180) % 360).toColor();
  }

  Color _generateBackgroundColor(List<Color> colors) {
    if (colors.isEmpty) return Colors.white;
    
    // Use the lightest color as base and make it very subtle
    Color lightestColor = colors.reduce((a, b) => 
      a.computeLuminance() > b.computeLuminance() ? a : b);
    
    return Color.fromRGBO(
      (lightestColor.red + 240) ~/ 2,
      (lightestColor.green + 240) ~/ 2,
      (lightestColor.blue + 240) ~/ 2,
      1.0,
    );
  }

  Color _generateTextColor(Color backgroundColor) {
    return backgroundColor.computeLuminance() > 0.7 
        ? const Color(0xFF1D1D1F) 
        : Colors.white;
  }

  Color _generateSubtleColor(List<Color> colors) {
    if (colors.isEmpty) return const Color(0xFFF8F9FA);
    
    Color baseColor = colors.first;
    return Color.fromRGBO(
      (baseColor.red + 250) ~/ 2,
      (baseColor.green + 250) ~/ 2,
      (baseColor.blue + 250) ~/ 2,
      1.0,
    );
  }

  Future<void> _loadDetailedContent() async {
    setState(() {
      _isLoadingContent = true;
    });

    try {
      // Fetch real Wikipedia content
      final content = await _fetchWikipediaContent(widget.podcast.title);
      
      setState(() {
        _fullContent = content;
        _isLoadingContent = false;
      });
    } catch (e) {
      setState(() {
        _fullContent = 'Content could not be loaded at this time. Please try again later.';
        _isLoadingContent = false;
      });
    }
  }

  Future<String> _fetchWikipediaContent(String title) async {
    try {
      // Clean up the title for Wikipedia API
      String pageTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      
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
            // Format the Wikipedia content nicely
            return _formatWikipediaContent(extract, title);
          }
        }
      }
      
      // Fallback content if Wikipedia fetch fails
      return _generateFallbackContent(title);
    } catch (e) {
      print('Error fetching Wikipedia content: $e');
      return _generateFallbackContent(title);
    }
  }

  String _formatWikipediaContent(String extract, String title) {
    // Clean up the content
    String cleanContent = extract.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Split into paragraphs
    List<String> paragraphs = cleanContent.split(RegExp(r'\.(?=\s+[A-Z])'));
    
    String formattedContent = '''$title

${paragraphs.take(3).join('. ').trim()}.

🎯 Key Points:
''';
    
    // Extract key sentences for bullet points
    List<String> sentences = paragraphs.take(6).toList();
    for (int i = 3; i < math.min(sentences.length, 6); i++) {
      String sentence = sentences[i].trim();
      if (sentence.isNotEmpty && sentence.length > 10) {
        if (sentence.length > 100) {
          sentence = sentence.substring(0, 97) + '...';
        }
        formattedContent += '• $sentence\n';
      }
    }
    
    formattedContent += '''

📚 Deep Dive:
This comprehensive exploration delves into the fascinating world of $title, offering insights that span historical context, contemporary relevance, and future implications.

🌟 What You'll Discover:
• Historical background and significance
• Key concepts and principles
• Modern applications and relevance
• Critical analysis and perspectives
• Connections to broader themes

This episode provides a thorough examination that goes beyond surface-level information, offering listeners a well-rounded understanding of the subject matter.
''';
    
    return formattedContent;
  }

  String _generateFallbackContent(String title) {
    return '''$title

This is a comprehensive exploration of $title, offering deep insights and fascinating perspectives that have captivated minds across generations.

🎯 Key Areas of Focus:
• Historical context and significance
• Contemporary relevance and applications
• Future implications and emerging trends
• Cross-disciplinary connections
• Expert perspectives and analysis

📚 In-Depth Analysis:
This episode provides a thorough examination of $title, exploring multiple facets and dimensions. Our approach ensures that listeners gain a comprehensive understanding that goes far beyond surface-level information.

The content is carefully curated to provide maximum educational value while remaining engaging and accessible to audiences of all backgrounds.

🌟 What You'll Discover:
• Foundational concepts and principles
• Advanced theories and methodologies
• Real-world applications and case studies
• Critical thinking frameworks
• Discussion points for further exploration

Join us on this intellectual journey as we delve deep into the fascinating world of $title.
''';
  }

  void _playPodcast() {
    final episode = WikipediaEpisode(
      title: widget.podcast.title,
      description: _fullContent ?? widget.podcast.title,
      imageUrl: widget.podcast.imageUrl,
      pageUrl: '',
      category: widget.podcast.category,
      duration: '8-12 min',
    );
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PlayerPage(
          episode: episode,
          autoPlay: true,
          preExtractedColors: _extractedColors,
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

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    _colorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        final animatedBackgroundColor = Color.lerp(
          Colors.white,
          _backgroundColor,
          _colorAnimation.value,
        )!;
        
        final animatedDominantColor = Color.lerp(
          const Color(0xFF95e3e0),
          _dominantColor,
          _colorAnimation.value,
        )!;

        return Scaffold(
          backgroundColor: animatedBackgroundColor,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: _textColor == Colors.white 
                  ? Brightness.light 
                  : Brightness.dark,
              statusBarBrightness: _textColor == Colors.white 
                  ? Brightness.dark 
                  : Brightness.light,
              systemNavigationBarColor: animatedBackgroundColor,
              systemNavigationBarIconBrightness: _textColor == Colors.white 
                  ? Brightness.light 
                  : Brightness.dark,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: _extractedColors.isNotEmpty ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    animatedBackgroundColor,
                    Color.lerp(animatedBackgroundColor, _subtleColor, 0.3)!,
                    Color.lerp(animatedBackgroundColor, _extractedColors.last.withValues(alpha: 0.1), 0.2)!,
                  ],
                ) : null,
                color: _extractedColors.isEmpty ? animatedBackgroundColor : null,
              ),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildAppBar(animatedDominantColor),
                  _buildContent(animatedDominantColor),
                ],
              ),
            ),
          ),
          floatingActionButton: _buildFloatingActionButton(animatedDominantColor),
        );
      },
    );
  }

  Widget _buildAppBar(Color dominantColor) {
    return SliverAppBar(
      expandedHeight: 300.h,
      pinned: true,
      backgroundColor: _backgroundColor.withValues(alpha: 0.95),
      elevation: 0,
      leading: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _backgroundColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: dominantColor.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: dominantColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: _textColor,
              size: 16.w,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        // Removed the color palette count action button
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Background Image with parallax
            Transform.translate(
              offset: Offset(0, _scrollOffset * 0.2),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                child: Hero(
                  tag: 'favorite_podcast_${widget.podcast.title}',
                  child: widget.podcast.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: widget.podcast.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _extractedColors.isNotEmpty 
                                    ? [
                                        _extractedColors.first.withValues(alpha: 0.3),
                                        _extractedColors.last.withValues(alpha: 0.3),
                                      ]
                                    : [
                                        dominantColor.withValues(alpha: 0.3),
                                        _accentColor.withValues(alpha: 0.3),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: dominantColor,
                                strokeWidth: 2.w,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  dominantColor.withValues(alpha: 0.5),
                                  _accentColor.withValues(alpha: 0.5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.podcasts_rounded,
                                color: Colors.white,
                                size: 64.w,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                dominantColor.withValues(alpha: 0.5),
                                _accentColor.withValues(alpha: 0.5),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.podcasts_rounded,
                              color: Colors.white,
                              size: 64.w,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            // Enhanced gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      dominantColor.withValues(alpha: 0.1),
                      dominantColor.withValues(alpha: 0.3),
                    ],
                  ),
                ),
              ),
            ),
            // Removed color palette preview overlay
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Color dominantColor) {
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
                _buildTitleSection(dominantColor),
                SizedBox(height: 16.h),
                _buildContentSection(dominantColor),
                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection(Color dominantColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: dominantColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: dominantColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
                  gradient: LinearGradient(
                    colors: [dominantColor, _accentColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.podcasts_rounded,
                  color: Colors.white,
                  size: 20.w,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.podcast.category.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: dominantColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'PREMIUM EPISODE',
                      style: GoogleFonts.inter(
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w500,
                        color: _textColor.withValues(alpha: 0.6),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            widget.podcast.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: _textColor,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(Color dominantColor) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: _backgroundColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: dominantColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: dominantColor.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.article_outlined,
                color: dominantColor,
                size: 18.w,
              ),
              SizedBox(width: 8.w),
              Text(
                'Episode Content',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                ),
              ),
              Spacer(),
              if (!_isLoadingContent)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isContentExpanded = !_isContentExpanded;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: dominantColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isContentExpanded ? 'Show Less' : 'Read More',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: dominantColor,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          _isContentExpanded 
                              ? Icons.keyboard_arrow_up_rounded 
                              : Icons.keyboard_arrow_down_rounded,
                          color: dominantColor,
                          size: 16.w,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          if (_isLoadingContent)
            Container(
              height: 120.h,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: dominantColor,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Loading content...',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: _textColor.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _fullContent ?? 'Content not available',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: _textColor.withValues(alpha: 0.8),
                  height: 1.6,
                ),
                maxLines: _isContentExpanded ? null : 6,
                overflow: _isContentExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton(Color dominantColor) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [dominantColor, _accentColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: dominantColor.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _playPodcast,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 28.w,
          ),
          label: Text(
            'Play Episode',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class ColorInfo {
  final Color color;
  int count;
  final double brightness;
  final double saturation;

  ColorInfo({
    required this.color,
    required this.count,
    required this.brightness,
    required this.saturation,
  });
}
