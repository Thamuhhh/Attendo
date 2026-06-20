import 'package:flutter/material.dart';
import 'l10n/strings.dart';

class AppTheme {
  static const Color primary = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF534BAE);
  static const Color accent = Color(0xFF00BFA5);
  static const Color surface = Color(0xFFF0F2F5);
  static const Color surfaceDark = Color(0xFF0D0D1A);
  static const Color cardBg = Colors.white;
  static const Color cardBgDark = Color(0xFF1A1A2E);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
  static Color cardColor(BuildContext context) => isDark(context) ? cardBgDark : cardBg;
  static Color scaffoldColor(BuildContext context) => isDark(context) ? surfaceDark : surface;
  static Color greyShade(BuildContext context, int shade) {
    if (!isDark(context)) {
      switch (shade) {
        case 50: return Colors.grey.shade50;
        case 100: return Colors.grey.shade100;
        case 200: return Colors.grey.shade200;
        case 300: return Colors.grey.shade300;
        case 400: return Colors.grey.shade400;
        case 500: return Colors.grey.shade500;
        case 600: return Colors.grey.shade600;
        default: return Colors.grey;
      }
    }
    switch (shade) {
      case 50: return const Color(0xFF2A2A3E);
      case 100: return const Color(0xFF2A2A3E);
      case 200: return const Color(0xFF3A3A4E);
      case 300: return const Color(0xFF4A4A5E);
      case 400: return const Color(0xFF6B6B7E);
      case 500: return const Color(0xFF8B8B9E);
      case 600: return const Color(0xFF9B9BAE);
      default: return const Color(0xFF3A3A4E);
    }
  }

  static ThemeData get lightTheme {
    return _baseTheme(
      surface,
      Colors.white,
      Colors.grey.shade50,
      Colors.grey.shade300,
    );
  }

  static ThemeData get darkTheme {
    return _baseTheme(
      surfaceDark,
      cardBgDark,
      const Color(0xFF2A2A3E),
      const Color(0xFF3A3A4E),
    );
  }

  static ThemeData _baseTheme(Color scaffoldBg, Color cardBg, Color inputFill, Color inputBorder) {
    return ThemeData(
      useMaterial3: true,
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
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardBg,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 8,
        backgroundColor: cardBg,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primary);
          }
          return TextStyle(fontSize: 12, color: Colors.grey.shade600);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primary, size: 22);
          }
          return IconThemeData(color: Colors.grey.shade400, size: 22);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      ),
    );
  }

  static PreferredSizeWidget gradientAppBar(String title, {List<Widget>? actions, Widget? leading, BuildContext? context}) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [primary, primaryLight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: context != null && isDark(context)
                  ? Colors.black.withValues(alpha: 0.4)
                  : const Color(0x29000000),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AppBar(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          centerTitle: true,
          actions: actions,
          leading: leading,
        ),
      ),
    );
  }

  static BoxDecoration statCard(BuildContext context, Color color) {
    final d = isDark(context);
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          color.withValues(alpha: d ? 0.2 : 0.12),
          color.withValues(alpha: d ? 0.08 : 0.04),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: d ? 0.3 : 0.15), width: 1.5),
    );
  }

  static Widget statusBadge(BuildContext context, String status) {
    final isPresent = status == 'present';
    final color = isPresent ? success : danger;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark(context) ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: isDark(context) ? 0.5 : 0.3)),
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
        color: color.withValues(alpha: isDark(context) ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: isDark(context) ? 0.5 : 0.3)),
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
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: isError ? danger : success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      builder: (ctx, v, _) => Transform.scale(scale: v, child: Icon(icon, color: Colors.white, size: 22)),
    );
  }

  static Future<bool> showConfirm(BuildContext context, String title, String message, {String confirmLabel = 'Delete', bool isDestructive = true}) async {
    final d = isDark(context);
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: cardColor(context),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDestructive ? danger : primary).withValues(alpha: d ? 0.3 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isDestructive ? Icons.delete_outline_rounded : Icons.info_outline_rounded,
                color: isDestructive ? danger : primary, size: 22),
          ),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: d ? Colors.white : textPrimary)),
        ]),
        content: Text(message, style: TextStyle(fontSize: 14, color: d ? Colors.grey.shade300 : textSecondary, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.get('cancel'), style: TextStyle(fontWeight: FontWeight.w600, color: d ? Colors.grey.shade400 : Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? danger : primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
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
        color: d ? const Color(0xFF3A3A4E) : Colors.grey.shade200,
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
