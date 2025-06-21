import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/onboarding_page.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/category_selection_page.dart';
import 'screens/player_page.dart';
import 'screens/profile_page.dart';
import 'screens/daily_quote_page.dart';
import 'services/auth_service.dart';
import 'services/local_database_service.dart';
import 'services/quote_service.dart';
import 'widgets/app_logo.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/home/home_bloc.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
    // Continue without Firebase for now
  }

  // Initialize local database and clear expired cache
  try {
    final localDb = LocalDatabaseService();
    await localDb.clearExpiredCache();
    if (kDebugMode) {
      final cacheInfo = await localDb.getCacheInfo();
      print('App start cache info: $cacheInfo');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing local database: $e');
    }
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'FinityTalks',
          theme: AppTheme.lightTheme,
          home: FutureBuilder<bool>(
            future: _shouldShowQuotePage(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                );
              }
              
              if (snapshot.data == true) {
                return const DailyQuotePage();
              }
              
              return const AuthWrapper();
            },
          ),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }

  Future<bool> _shouldShowQuotePage() async {
    // Don't show quote page in main.dart - it will be handled after authentication
    return false;
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(authService: AuthService())..add(AuthStarted()),
        ),
        BlocProvider<HomeBloc>(
          create: (context) => HomeBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'FinityTalks',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        locale: const Locale('en', 'US'), // Set default language to English
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/onboarding': (context) => const OnboardingPage(),
          '/categories': (context) => const CategorySelectionPage(),
          '/profile': (context) => const ProfilePage(),
          // Note: Player page uses navigation with parameters, so no static route needed
        },
        home: const SplashWrapper(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class SplashWrapper extends StatefulWidget {
  const SplashWrapper({Key? key}) : super(key: key);

  @override
  State<SplashWrapper> createState() => _SplashWrapperState();
}

class _SplashWrapperState extends State<SplashWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));
    
    _animationController.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    try {
      // Add a small delay to ensure Flutter engine is ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      bool isLoggedIn = false;
      bool hasViewedOnboarding = false;
      bool hasSelectedCategories = false;
      
      try {
        final prefs = await SharedPreferences.getInstance();
        isLoggedIn = prefs.getBool('is_logged_in') ?? false;
        hasViewedOnboarding = prefs.getBool('has_viewed_onboarding') ?? false;
        hasSelectedCategories = prefs.getBool('has_selected_categories') ?? false;
        
        if (kDebugMode) {
          print('Splash check - isLoggedIn: $isLoggedIn, hasViewedOnboarding: $hasViewedOnboarding, hasSelectedCategories: $hasSelectedCategories');
        }
      } catch (prefsError) {
        if (kDebugMode) {
          print('SharedPreferences error in splash: $prefsError');
        }
        // Continue with default values if preferences fail
      }
      
      // Check Firebase auth state as well
      bool isFirebaseSignedIn = false;
      try {
        final authService = AuthService();
        isFirebaseSignedIn = authService.isSignedIn;
        if (kDebugMode) {
          print('Firebase signed in: $isFirebaseSignedIn');
        }
      } catch (authError) {
        if (kDebugMode) {
          print('Auth service error in splash: $authError');
        }
      }
      
      Widget nextScreen;
      
      // Modified navigation flow: Onboarding -> Quote -> Home (skip login for first time)
      if (!hasViewedOnboarding) {
        nextScreen = const OnboardingPage();
      } else if (isLoggedIn || isFirebaseSignedIn) {
        // If user is logged in, check categories then show quote page
        if (!hasSelectedCategories) {
          nextScreen = const CategorySelectionPage();
        } else {
          nextScreen = const DailyQuotePage();
        }
      } else {
        // For first time after onboarding, skip login and go to quote page
        // Set default authentication state
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('is_logged_in', true);
          await prefs.setBool('has_selected_categories', true);
        } catch (e) {
          if (kDebugMode) {
            print('Error setting default prefs: $e');
          }
        }
        nextScreen = const DailyQuotePage();
      }
      
      if (kDebugMode) {
        print('Navigating to: ${nextScreen.runtimeType}');
      }
      
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    } catch (e) {
      // If there's an error checking preferences, default to onboarding page
      if (kDebugMode) {
        print('Error in splash navigation: $e');
      }
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        statusBarBrightness: Brightness.light, // For iOS
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          color: Colors.grey[300],
          child: Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Hero(
                      tag: 'app_logo',
                      child: AppLogo(
                        size: 200.w,
                      ),
                    ),
                  ),
                  );
                },
              ),
            ),
          ),
        ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
