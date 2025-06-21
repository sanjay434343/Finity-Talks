import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../services/horoscope_service.dart';
import 'home_page.dart';

class CategorySelectionPage extends StatefulWidget {
  const CategorySelectionPage({Key? key}) : super(key: key);

  @override
  State<CategorySelectionPage> createState() => _CategorySelectionPageState();
}

class _CategorySelectionPageState extends State<CategorySelectionPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Category selection state
  final Set<String> _selectedCategories = {};
  
  // Horoscope selection state
  String _selectedSign = 'aries';
  
  // Currency selection state
  String _selectedCurrency = 'USD';
  
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Technology', 'icon': Icons.computer, 'color': const Color(0xFF6366f1)},
    {'name': 'Science', 'icon': Icons.science, 'color': const Color(0xFF10b981)},
    {'name': 'History', 'icon': Icons.history_edu, 'color': const Color(0xFFf59e0b)},
    {'name': 'Philosophy', 'icon': Icons.psychology, 'color': const Color(0xFF8b5cf6)},
    {'name': 'Art', 'icon': Icons.palette, 'color': const Color(0xFFec4899)},
    {'name': 'Music', 'icon': Icons.music_note, 'color': const Color(0xFF06b6d4)},
    {'name': 'Literature', 'icon': Icons.book, 'color': const Color(0xFFef4444)},
    {'name': 'Psychology', 'icon': Icons.psychology_alt, 'color': const Color(0xFF84cc16)},
    {'name': 'Business', 'icon': Icons.business, 'color': const Color(0xFF6366f1)},
    {'name': 'Health', 'icon': Icons.favorite, 'color': const Color(0xFFf97316)},
    {'name': 'Politics', 'icon': Icons.how_to_vote, 'color': const Color(0xFF64748b)},
    {'name': 'Sports', 'icon': Icons.sports, 'color': const Color(0xFF22c55e)},
  ];
  // Currency list with display names
  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'C\$'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹'},
    {'code': 'KRW', 'name': 'South Korean Won', 'symbol': '₩'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'S\$'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar', 'symbol': 'HK\$'},
    {'code': 'SEK', 'name': 'Swedish Krona', 'symbol': 'kr'},
    {'code': 'NOK', 'name': 'Norwegian Krone', 'symbol': 'kr'},
    {'code': 'DKK', 'name': 'Danish Krone', 'symbol': 'kr'},
    {'code': 'PLN', 'name': 'Polish Zloty', 'symbol': 'zł'},
    {'code': 'CZK', 'name': 'Czech Koruna', 'symbol': 'Kč'},
    {'code': 'HUF', 'name': 'Hungarian Forint', 'symbol': 'Ft'},
    {'code': 'RON', 'name': 'Romanian Leu', 'symbol': 'lei'},
    {'code': 'BGN', 'name': 'Bulgarian Lev', 'symbol': 'лв'},
    {'code': 'HRK', 'name': 'Croatian Kuna', 'symbol': 'kn'},
    {'code': 'RUB', 'name': 'Russian Ruble', 'symbol': '₽'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'symbol': '₺'},
    {'code': 'ILS', 'name': 'Israeli Shekel', 'symbol': '₪'},
    {'code': 'ZAR', 'name': 'South African Rand', 'symbol': 'R'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'symbol': 'R\$'},
    {'code': 'MXN', 'name': 'Mexican Peso', 'symbol': '\$'},
    {'code': 'ARS', 'name': 'Argentine Peso', 'symbol': '\$'},
    {'code': 'COP', 'name': 'Colombian Peso', 'symbol': '\$'},
    {'code': 'CLP', 'name': 'Chilean Peso', 'symbol': '\$'},
    {'code': 'PEN', 'name': 'Peruvian Sol', 'symbol': 'S/'},
    {'code': 'UYU', 'name': 'Uruguayan Peso', 'symbol': '\$U'},
    {'code': 'THB', 'name': 'Thai Baht', 'symbol': '฿'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'RM'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'symbol': 'Rp'},
    {'code': 'PHP', 'name': 'Philippine Peso', 'symbol': '₱'},
    {'code': 'VND', 'name': 'Vietnamese Dong', 'symbol': '₫'},
    {'code': 'TWD', 'name': 'Taiwan Dollar', 'symbol': 'NT\$'},
    {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'د.إ'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': 'ر.س'},
    {'code': 'QAR', 'name': 'Qatari Riyal', 'symbol': 'ر.ق'},
    {'code': 'KWD', 'name': 'Kuwaiti Dinar', 'symbol': 'د.ك'},
    {'code': 'BHD', 'name': 'Bahraini Dinar', 'symbol': 'ب.د'},
    {'code': 'OMR', 'name': 'Omani Rial', 'symbol': 'ر.ع.'},
    {'code': 'JOD', 'name': 'Jordanian Dinar', 'symbol': 'د.ا'},
    {'code': 'LBP', 'name': 'Lebanese Pound', 'symbol': 'ل.ل'},
    {'code': 'EGP', 'name': 'Egyptian Pound', 'symbol': 'ج.م'},
    {'code': 'MAD', 'name': 'Moroccan Dirham', 'symbol': 'د.م.'},
    {'code': 'TND', 'name': 'Tunisian Dinar', 'symbol': 'د.ت'},
    {'code': 'DZD', 'name': 'Algerian Dinar', 'symbol': 'د.ج'},
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'symbol': '₨'},
    {'code': 'BDT', 'name': 'Bangladeshi Taka', 'symbol': '৳'},
    {'code': 'LKR', 'name': 'Sri Lankan Rupee', 'symbol': '₨'},
    {'code': 'NPR', 'name': 'Nepalese Rupee', 'symbol': '₨'},
    {'code': 'AFN', 'name': 'Afghan Afghani', 'symbol': '؋'},
    {'code': 'IRR', 'name': 'Iranian Rial', 'symbol': '﷼'},
    {'code': 'IQD', 'name': 'Iraqi Dinar', 'symbol': 'ع.د'},
    {'code': 'KES', 'name': 'Kenyan Shilling', 'symbol': 'KSh'},
    {'code': 'UGX', 'name': 'Ugandan Shilling', 'symbol': 'USh'},
    {'code': 'TZS', 'name': 'Tanzanian Shilling', 'symbol': 'TSh'},
    {'code': 'ETB', 'name': 'Ethiopian Birr', 'symbol': 'Br'},
    {'code': 'GHS', 'name': 'Ghanaian Cedi', 'symbol': '₵'},
    {'code': 'NGN', 'name': 'Nigerian Naira', 'symbol': '₦'},
    {'code': 'XAF', 'name': 'Central African Franc', 'symbol': 'Fr'},
    {'code': 'XOF', 'name': 'West African Franc', 'symbol': 'Fr'},
    {'code': 'NZD', 'name': 'New Zealand Dollar', 'symbol': 'NZ\$'},
    {'code': 'FJD', 'name': 'Fijian Dollar', 'symbol': 'FJ\$'},
    {'code': 'TOP', 'name': 'Tongan Paʻanga', 'symbol': 'T\$'},
    {'code': 'WST', 'name': 'Samoan Tala', 'symbol': 'T'},
    {'code': 'VUV', 'name': 'Vanuatu Vatu', 'symbol': 'Vt'},
    {'code': 'PGK', 'name': 'Papua New Guinea Kina', 'symbol': 'K'},
    {'code': 'SBD', 'name': 'Solomon Islands Dollar', 'symbol': 'SI\$'},
  ];
  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select at least one category'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('selected_categories', _selectedCategories.toList());
      await prefs.setBool('has_selected_categories', true);
      await prefs.setString('user_zodiac_sign', _selectedSign);
      await prefs.setString('selected_currency', _selectedCurrency);
      await prefs.setBool('onboarding_completed', true);

      print('Saved currency to preferences: $_selectedCurrency'); // Debug log

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to save preferences. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFFAFAFA),
                Color(0xFFFFFFFF),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(),
                
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildCategorySelectionPage(),
                      _buildHoroscopeSelectionPage(),
                      _buildCurrencySelectionPage(),
                    ],
                  ),
                ),
                
                // Navigation buttons
                _buildNavigationButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 3.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                ),
                borderRadius: BorderRadius.circular(1.5.r),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Container(
              height: 3.h,
              decoration: BoxDecoration(
                gradient: _currentPage >= 1 
                    ? const LinearGradient(
                        colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                      )
                    : null,
                color: _currentPage < 1 ? Colors.grey[300] : null,
                borderRadius: BorderRadius.circular(1.5.r),
              ),
            ),
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Container(
              height: 3.h,
              decoration: BoxDecoration(
                gradient: _currentPage >= 2 
                    ? const LinearGradient(
                        colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                      )
                    : null,
                color: _currentPage < 2 ? Colors.grey[300] : null,
                borderRadius: BorderRadius.circular(1.5.r),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySelectionPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          
          // Logo and title
          Hero(
            tag: 'app_logo',
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF95e3e0).withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: AppLogo(size: 28.w),
              ),
            ),
          ),
          
          SizedBox(height: 20.h),
          
          Text(
            'Choose Your Interests',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 8.h),
          
          Text(
            'Select topics to get personalized episodes',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF86868B),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 28.h),
            // Categories list - minimal cards with scrolling
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategories.contains(category['name']);
                
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(category['name']);
                      } else {
                        _selectedCategories.add(category['name']);
                      }
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 10.h),
                    height: 54.h,
                    decoration: BoxDecoration(
                      gradient: isSelected ? LinearGradient(
                        colors: [category['color'], category['color'].withValues(alpha: 0.9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ) : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? category['color'].withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.03),
                          blurRadius: isSelected ? 8 : 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        children: [
                          Container(
                            width: 36.w,
                            height: 36.w,
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.white.withValues(alpha: 0.2) 
                                  : category['color'].withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              category['icon'],
                              size: 18.w,
                              color: isSelected ? Colors.white : category['color'],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              category['name'],
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
                              ),
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: Icon(
                                Icons.check,
                                size: 14.w,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildHoroscopeSelectionPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 24.h),
          
          // Horoscope icon
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF95e3e0).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: 28.w,
            ),
          ),
          
          SizedBox(height: 20.h),
          
          Text(
            'What\'s Your Sign?',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 8.h),
          
          Text(
            'Get personalized daily horoscopes',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF86868B),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 28.h),
          
          // Horoscope signs grid
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10.w,
                mainAxisSpacing: 10.h,
                childAspectRatio: 2.1,
              ),
              itemCount: HoroscopeService.availableSigns.length,
              itemBuilder: (context, index) {
                final sign = HoroscopeService.availableSigns[index];
                final isSelected = sign == _selectedSign;
                final displayName = HoroscopeService.getSignDisplayName(sign);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSign = sign;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      gradient: isSelected ? const LinearGradient(
                        colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ) : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.grey[300]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? const Color(0xFF95e3e0).withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: isSelected ? 6 : 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        displayName,
                        style: GoogleFonts.inter(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildCurrencySelectionPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 24.h),
          
          // Currency icon
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF95e3e0).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.attach_money_rounded,
              color: Colors.white,
              size: 28.w,
            ),
          ),
          
          SizedBox(height: 20.h),
          
          Text(
            'Choose Your Currency',
            style: GoogleFonts.inter(
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D1D1F),
              letterSpacing: -0.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 8.h),
          
          Text(
            'Select your preferred currency for exchange rates',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF86868B),
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 28.h),
          
          // Currency list
          Expanded(
            child: ListView.builder(
              itemCount: _currencies.length,
              itemBuilder: (context, index) {
                final currency = _currencies[index];
                final isSelected = currency['code'] == _selectedCurrency;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCurrency = currency['code']!;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 8.h),
                    decoration: BoxDecoration(
                      gradient: isSelected ? const LinearGradient(
                        colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ) : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.grey[300]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? const Color(0xFF95e3e0).withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.04),
                          blurRadius: isSelected ? 6 : 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      child: Row(
                        children: [
                          Container(
                            width: 40.w,
                            height: 40.w,
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Center(
                              child: Text(
                                currency['symbol']!,
                                style: GoogleFonts.inter(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.grey[600],
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
                                  currency['name']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
                                  ),
                                ),
                                Text(
                                  currency['code']!,
                                  style: GoogleFonts.inter(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF86868B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 20.w,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          SizedBox(height: 16.h),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Row(
        children: [
          // Back button
          if (_currentPage > 0)
            Expanded(
              child: Container(
                height: 48.h,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24.r),
                ),
                child: TextButton(
                  onPressed: _previousPage,
                  style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.r),
                    ),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF86868B),
                    ),
                  ),
                ),
              ),
            ),
          
          if (_currentPage > 0) SizedBox(width: 12.w),
          
          // Next/Finish button
          Expanded(
            flex: _currentPage == 0 ? 1 : 2,
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                gradient: (_currentPage == 0 && _selectedCategories.isNotEmpty) || _currentPage == 1 || _currentPage == 2
                    ? const LinearGradient(
                        colors: [Color(0xFF95e3e0), Color(0xFFd1b8f8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(colors: [Colors.grey[300]!, Colors.grey[300]!]),
                borderRadius: BorderRadius.circular(24.r),
                boxShadow: (_currentPage == 0 && _selectedCategories.isNotEmpty) || _currentPage == 1 || _currentPage == 2
                    ? [
                        BoxShadow(
                          color: const Color(0xFF95e3e0).withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: TextButton(
                onPressed: _isLoading ? null : () {
                  if (_currentPage == 0 && _selectedCategories.isEmpty) return;
                  _nextPage();
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24.r),
                  ),
                ),
                child: _isLoading && _currentPage == 2
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _currentPage == 0 
                            ? 'Next (${_selectedCategories.length})' 
                            : _currentPage == 1 ? 'Next' : 'Get Started',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
