import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppLogo extends StatefulWidget {
  final double size;
  final Color? color;

  const AppLogo({
    Key? key,
    this.size = 100,
    this.color,
  }) : super(key: key);

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: SizedBox(
            width: widget.size.w,
            height: widget.size.w,
            child: widget.color != null
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      widget.color!,
                      BlendMode.srcIn,
                    ),
                    child: SvgPicture.asset(
                      'assets/logo/logo.svg',
                      width: widget.size.w,
                      height: widget.size.w,
                      fit: BoxFit.contain,
                    ),
                  )
                : SvgPicture.asset(
                    'assets/logo/logo.svg',
                    width: widget.size.w,
                    height: widget.size.w,
                    fit: BoxFit.contain,
                  ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
