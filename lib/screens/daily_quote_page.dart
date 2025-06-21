import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/quote_model.dart';
import '../services/quote_service.dart';
import '../widgets/app_logo.dart';
import 'home_page.dart';

class DailyQuotePage extends StatefulWidget {
  const DailyQuotePage({Key? key}) : super(key: key);

  @override
  State<DailyQuotePage> createState() => _DailyQuotePageState();
}

class _DailyQuotePageState extends State<DailyQuotePage>
    with TickerProviderStateMixin {
  QuoteModel? todayQuote;
  bool isLoading = true;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _exitController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _exitFadeAnimation;
  late Animation<Offset> _exitSlideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadQuoteAndNavigate();
  }

  void _setupAnimations() {
    // Entry animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Exit animations
    _exitController = AnimationController(
      duration: const Duration(milliseconds: 800),
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
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _exitFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
    ));

    _exitSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.5),
    ).animate(CurvedAnimation(
      parent: _exitController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeInCubic),
    ));
  }

  Future<void> _loadQuoteAndNavigate() async {
    try {
      final quote = await QuoteService.getTodayQuote();
      
      if (mounted) {
        setState(() {
          todayQuote = quote;
          isLoading = false;
        });
        
        // Start entry animations
        _fadeController.forward();
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          _slideController.forward();
        }
        
        // Wait for 8 seconds then start exit animation
        await Future.delayed(const Duration(seconds: 8));
        
        if (mounted) {
          // Start smooth exit animation
          await _exitController.forward();
          
          if (mounted) {
            await QuoteService.markQuoteAsViewed();
            
            // Navigate with coordinated transition
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const HomePage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        // Navigate to home even on error after a delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _exitController.dispose();
    super.dispose();
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
        body: SafeArea(
          child: AnimatedBuilder(
            animation: Listenable.merge([_exitController, _fadeController, _slideController]),
            builder: (context, child) {
              // Use exit animations when exiting, entry animations when entering
              final fadeValue = _exitController.isAnimating || _exitController.isCompleted
                  ? _exitFadeAnimation.value
                  : _fadeAnimation.value;
              
              final slideValue = _exitController.isAnimating || _exitController.isCompleted
                  ? _exitSlideAnimation.value
                  : _slideAnimation.value;

              return FadeTransition(
                opacity: AlwaysStoppedAnimation(fadeValue),
                child: SlideTransition(
                  position: AlwaysStoppedAnimation(slideValue),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Logo at the top
                          Hero(
                            tag: 'app_logo',
                            child: AppLogo(size: 60.w),
                          ),
                          
                          SizedBox(height: 20.h),
                          
                          // Quote Content
                          isLoading
                              ? _buildLoadingState()
                              : _buildQuoteContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24.w,
          height: 24.w,
          child: const CircularProgressIndicator(
            color: Colors.black,
            strokeWidth: 2,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          'Loading daily quote...',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteContent() {
    if (todayQuote == null) {
      return Text(
        'No quote available today',
        style: GoogleFonts.inter(
          fontSize: 16.sp,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
        textAlign: TextAlign.center,
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Quote text
        Text(
          '"${todayQuote!.text}"',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(height: 32.h),
        
        // Author
        Text(
          '— ${todayQuote!.author}',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
