import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'l10n/strings.dart';

class AppTheme {
  // Premium modern palette
  static const Color primary = Color(0xFF6C63FF);     // Vibrant purple-indigo
  static const Color primaryLight = Color(0xFFA5A0FF); // Light purple
  static const Color primaryDark = Color(0xFF4A42D4);  // Dark purple
  static const Color accent = Color(0xFF00C9A7);       // Mint teal
  static const Color accentLight = Color(0xFF5EFFE0);
  static const Color surface = Color(0xFFF0F2F8);
  static const Color surfaceDark = Color(0xFF080812);
  static const Color cardBg = Colors.white;
  static const Color cardBgDark = Color(0xFF13131F);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textSecondaryDark = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color cardColor(BuildContext context) => isDark(context) ? cardBgDark : cardBg;
  static Color scaffoldColor(BuildContext context) => isDark(context) ? surfaceDark : surface;
  static Color greyShade(BuildContext context, int shade) {
    if (!isDark(context)) {
      switch (shade) {
        case 50: return const Color(0xFFF0F2F5);
        case 100: return const Color(0xFFE5E7EB);
        case 200: return const Color(0xFFD1D5DB);
        case 300: return const Color(0xFF9CA3AF);
        case 400: return const Color(0xFF6B7280);
        case 500: return const Color(0xFF4B5563);
        case 600: return const Color(0xFF374151);
        default: return const Color(0xFF9CA3AF);
      }
    }
    switch (shade) {
      case 50: return const Color(0xFF191927);
      case 100: return const Color(0xFF222233);
      case 200: return const Color(0xFF2D2D42);
      case 300: return const Color(0xFF3D3D55);
      case 400: return const Color(0xFF5C5C78);
      case 500: return const Color(0xFF7C7C9A);
      case 600: return const Color(0xFFA0A0B8);
      default: return const Color(0xFF2D2D42);
    }
  }

  static ThemeData get lightTheme {
    return _baseTheme(surface, Colors.white, const Color(0xFFF0F2F5), const Color(0xFFD1D5DB), const Color(0xFFE5E7EB));
  }

  static ThemeData get darkTheme {
    return _baseTheme(surfaceDark, cardBgDark, const Color(0xFF1A1A2A), const Color(0xFF2A2A3E), const Color(0xFF2D2D42));
  }

  static TextTheme get _poppins => GoogleFonts.poppinsTextTheme(ThemeData.light().textTheme);

  static ThemeData _baseTheme(Color scaffoldBg, Color cardBg, Color inputFill, Color inputBorder, Color dividerClr) {
    return ThemeData(
      useMaterial3: true,
      textTheme: _poppins,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: scaffoldBg,
        brightness: scaffoldBg == surface ? Brightness.light : Brightness.dark,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: cardBg,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: TextStyle(fontSize: 14, color: textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: primary, letterSpacing: 0.3);
          }
          return TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade500);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 24);
          }
          return IconThemeData(color: Colors.grey.shade400, size: 22);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),
      dividerTheme: DividerThemeData(color: dividerClr, thickness: 0.5, space: 1),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static PreferredSizeWidget gradientAppBar(String title, {List<Widget>? actions, Widget? leading, BuildContext? context}) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primary, primaryDark],
            begin: Alignment(-0.2, -0.5),
            end: Alignment(0.8, 1.2),
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: context != null && isDark(context)
                  ? Colors.black.withValues(alpha: 0.5)
                  : primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5, fontSize: 18)),
          centerTitle: true,
          actions: actions,
          leading: leading,
        ),
      ),
    );
  }

  static PreferredSizeWidget whatsappAppBar(String title, {Widget? leading}) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(72),
      child: Container(
        decoration: BoxDecoration(
          color: primary,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 72,
            child: Stack(
              children: [
                if (leading != null)
                  Positioned(left: 4, top: 0, bottom: 0, child: leading),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.school_rounded, size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22, color: Colors.white, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static BoxDecoration statCard(BuildContext context, Color color) {
    final d = isDark(context);
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: d ? 0.2 : 0.1),
          color.withValues(alpha: d ? 0.05 : 0.02),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withValues(alpha: d ? 0.25 : 0.12), width: 1.5),
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: d ? 0.1 : 0.06), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    );
  }

  static BoxDecoration gradientCard(BuildContext context) {
    final d = isDark(context);
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(
        colors: [
          cardColor(context),
          cardColor(context).withValues(alpha: 0.95),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: d ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
        BoxShadow(
          color: d ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static Widget statusBadge(BuildContext context, String status) {
    final isPresent = status == 'present';
    final color = isPresent ? success : danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark(context) ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: isDark(context) ? 0.4 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            isPresent ? AppStrings.get('present') : AppStrings.get('absent'),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  static Widget percentBadge(BuildContext context, int percent) {
    final color = percent >= 75 ? success : (percent >= 50 ? warning : danger);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark(context) ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: isDark(context) ? 0.4 : 0.2)),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color),
      ),
    );
  }

  static void showSnack(BuildContext context, String message, {bool isError = false}) {
    _showToast(context, message, isError: isError);
  }

  static void showToast(BuildContext context, String message, {bool isError = false}) {
    _showToast(context, message, isError: isError);
  }

  static void _showToast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            _animatedIcon(isError ? Icons.error_rounded : Icons.check_circle_rounded, isError),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
          ],
        ),
        backgroundColor: isError ? danger : success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  static Widget _animatedIcon(IconData icon, bool isError) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (ctx, v, _) => Transform.scale(scale: v, child: Icon(icon, color: Colors.white, size: 24)),
    );
  }

  static Future<bool> showConfirm(BuildContext context, String title, String message, {String confirmLabel = 'Delete', bool isDestructive = true}) async {
    final d = isDark(context);
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: cardColor(context),
        elevation: 0,
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDestructive ? danger : primary).withValues(alpha: d ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isDestructive ? Icons.delete_outline_rounded : Icons.info_outline_rounded,
                color: isDestructive ? danger : primary, size: 24),
          ),
          const SizedBox(width: 14),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: d ? Colors.white : textPrimary)),
        ]),
        content: Text(message, style: TextStyle(fontSize: 14, color: d ? textSecondaryDark : textSecondary, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.get('cancel'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: d ? const Color(0xFF5C5C78) : Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? danger : primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 0,
            ),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    ) ?? false;
  }
}

class ShimmerCard extends StatefulWidget {
  const ShimmerCard({super.key});

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final d = AppTheme.isDark(context);
    return FadeTransition(
      opacity: _ctrl.drive(CurveTween(curve: _PulseCurve())),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: AppTheme.cardColor(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _shimmerBox(48, 24, d),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(140, 14, d),
                    const SizedBox(height: 8),
                    _shimmerBox(80, 12, d),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox(double w, double h, bool d) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        color: d ? const Color(0xFF2D2D42) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(h / 2),
      ),
    );
  }
}

class _PulseCurve extends Curve {
  @override
  double transformInternal(double t) {
    return 0.3 + 0.7 * (1 - (t * 2 - 1) * (t * 2 - 1));
  }
}
