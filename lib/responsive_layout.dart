import 'package:flutter/material.dart';

/// ============================================================
///  responsive_layout.dart
///  A single file containing all responsive layout utilities.
///
///  USAGE:
///   1. Import this file wherever needed:
///        import 'responsive_layout.dart';
///
///   2. Use ResponsiveLayout widget to build different UIs:
///        ResponsiveLayout(
///          mobile:  MobileWidget(),
///          tablet:  TabletWidget(),
///          desktop: DesktopWidget(),
///        )
///
///   3. Use Responsive helper for values/sizes:
///        Responsive.isMobile(context)
///        Responsive.fontSize(context, mobile: 14, tablet: 16, desktop: 18)
///        Responsive.value(context, mobile: 8.0, tablet: 16.0, desktop: 24.0)
///
///   4. Use ResponsiveScaffold for auto side-nav on tablet/desktop.
///
///   5. Use ScreenUtils extension for quick screen size access:
///        context.screenWidth
///        context.isMobile
/// ============================================================

// ─────────────────────────────────────────────────────────────
// BREAKPOINTS
// ─────────────────────────────────────────────────────────────

class AppBreakpoints {
  AppBreakpoints._();

  /// Phone / small screen: width < 600
  static const double mobile = 600;

  /// Tablet / medium screen: 600 <= width < 1024
  static const double tablet = 1024;

  /// Desktop / large screen: width >= 1024
  static const double desktop = 1024;
}

// ─────────────────────────────────────────────────────────────
// RESPONSIVE HELPER CLASS
// ─────────────────────────────────────────────────────────────

class Responsive {
  Responsive._();

  // ── Screen type checks ────────────────────────────────────

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppBreakpoints.mobile;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.mobile &&
          MediaQuery.of(context).size.width < AppBreakpoints.tablet;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.desktop;

  static bool isTabletOrDesktop(BuildContext context) =>
      !isMobile(context);

  // ── Screen dimensions ─────────────────────────────────────

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static Size screenSize(BuildContext context) =>
      MediaQuery.of(context).size;

  // ── Responsive value selector ─────────────────────────────

  /// Returns one of three values depending on current screen size.
  static T value<T>(
      BuildContext context, {
        required T mobile,
        required T tablet,
        required T desktop,
      }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }

  /// Same as [value] but tablet falls back to desktop if not given.
  static T valueOrFallback<T>(
      BuildContext context, {
        required T mobile,
        T? tablet,
        required T desktop,
      }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet ?? desktop;
    return mobile;
  }

  // ── Font sizes ────────────────────────────────────────────

  static double fontSize(
      BuildContext context, {
        required double mobile,
        required double tablet,
        required double desktop,
      }) =>
      value(context, mobile: mobile, tablet: tablet, desktop: desktop);

  // ── Padding / spacing ─────────────────────────────────────

  /// Returns a symmetric horizontal padding based on screen size.
  static EdgeInsets horizontalPadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: value(context, mobile: 16, tablet: 32, desktop: 48),
  );

  /// Returns a screen-aware padding for page content.
  static EdgeInsets pagePadding(BuildContext context) => EdgeInsets.symmetric(
    horizontal: value(context, mobile: 16, tablet: 28, desktop: 40),
    vertical: value(context, mobile: 16, tablet: 20, desktop: 28),
  );

  /// Returns a uniform padding value.
  static double paddingValue(
      BuildContext context, {
        double mobile = 16,
        double tablet = 24,
        double desktop = 32,
      }) =>
      value(context, mobile: mobile, tablet: tablet, desktop: desktop);

  // ── Max content width ─────────────────────────────────────

  /// Caps content width on wide screens so it doesn't stretch too far.
  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1000;
    if (isTablet(context)) return 720;
    return double.infinity;
  }

  // ── Icon sizes ────────────────────────────────────────────

  static double iconSize(
      BuildContext context, {
        double mobile = 22,
        double tablet = 26,
        double desktop = 28,
      }) =>
      value(context, mobile: mobile, tablet: tablet, desktop: desktop);

  // ── Column count (for grids) ──────────────────────────────

  /// Returns a suitable column count for a grid.
  static int gridColumnCount(BuildContext context) =>
      value(context, mobile: 1, tablet: 2, desktop: 3);

  // ── Screen type label (for debugging) ────────────────────

  static String screenType(BuildContext context) {
    if (isDesktop(context)) return "Desktop";
    if (isTablet(context)) return "Tablet";
    return "Mobile";
  }
}

// ─────────────────────────────────────────────────────────────
// RESPONSIVE LAYOUT WIDGET
// ─────────────────────────────────────────────────────────────

/// Renders a different widget depending on screen size.
/// [tablet] is optional — falls back to [mobile] if not provided.
/// [desktop] is optional — falls back to [tablet] (or [mobile]) if not provided.
///
/// Example:
/// ```dart
/// ResponsiveLayout(
///   mobile: MobileHomeScreen(),
///   tablet: TabletHomeScreen(),
///   desktop: DesktopHomeScreen(),
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    }
    if (Responsive.isTablet(context)) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}

// ─────────────────────────────────────────────────────────────
// RESPONSIVE BUILDER
// ─────────────────────────────────────────────────────────────

/// Like [ResponsiveLayout] but passes [BuildContext] + [BoxConstraints]
/// to each builder, giving full flexibility.
///
/// Example:
/// ```dart
/// ResponsiveBuilder(
///   mobile: (context, constraints) => Text("Mobile: ${constraints.maxWidth}"),
///   desktop: (context, constraints) => Text("Desktop"),
/// )
/// ```
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
  mobile;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  tablet;
  final Widget Function(BuildContext context, BoxConstraints constraints)?
  desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (Responsive.isDesktop(context)) {
          return (desktop ?? tablet ?? mobile)(context, constraints);
        }
        if (Responsive.isTablet(context)) {
          return (tablet ?? mobile)(context, constraints);
        }
        return mobile(context, constraints);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RESPONSIVE SCAFFOLD
// ─────────────────────────────────────────────────────────────

/// A Scaffold that automatically switches between:
/// - Bottom navigation bar  → mobile
/// - Icon-only side rail    → tablet
/// - Full labeled side rail → desktop
///
/// Example:
/// ```dart
/// ResponsiveScaffold(
///   selectedIndex: _selectedIndex,
///   onDestinationSelected: (i) => setState(() => _selectedIndex = i),
///   destinations: [
///     NavDestination(icon: Icons.home_rounded, label: "Home"),
///     NavDestination(icon: Icons.person_rounded, label: "Profile"),
///   ],
///   body: _pages[_selectedIndex],
///   appBarTitle: "My App",
/// )
/// ```
class NavDestination {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;

  const NavDestination({
    required this.icon,
    this.selectedIcon,
    required this.label,
  });
}

class ResponsiveScaffold extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavDestination> destinations;
  final Widget body;
  final String? appBarTitle;
  final Widget? appBarLogo;
  final List<Widget>? appBarActions;
  final Widget? floatingActionButton;
  final Color? primaryColor;
  final Widget? sideRailHeader;
  final Widget? sideRailFooter;

  const ResponsiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.body,
    this.appBarTitle,
    this.appBarLogo,
    this.appBarActions,
    this.floatingActionButton,
    this.primaryColor,
    this.sideRailHeader,
    this.sideRailFooter,
  });

  static const Color _defaultPrimary = Color(0xFF149D0F);

  Color get _primary => primaryColor ?? _defaultPrimary;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobileScaffold(context),
      tablet: _buildTabletScaffold(context),
      desktop: _buildDesktopScaffold(context),
    );
  }

  // ── Mobile: bottom nav ──────────────────────────────────

  Widget _buildMobileScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: appBarTitle != null || appBarLogo != null
          ? _buildAppBar(context, showActions: true)
          : null,
      body: body,
      bottomNavigationBar: _buildBottomNav(context),
      floatingActionButton: floatingActionButton,
    );
  }

  // ── Tablet: icon rail on left ───────────────────────────

  Widget _buildTabletScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Row(
        children: [
          _buildIconRail(context),
          Expanded(
            child: Column(
              children: [
                if (appBarTitle != null || appBarLogo != null)
                  _buildInlineTopBar(context),
                Expanded(child: _centeredBody(context)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  // ── Desktop: labeled side nav ───────────────────────────

  Widget _buildDesktopScaffold(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Row(
        children: [
          _buildLabeledRail(context),
          Expanded(child: _centeredBody(context)),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  // ── Centered body with max width ────────────────────────

  Widget _centeredBody(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: Responsive.maxContentWidth(context),
        ),
        child: body,
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context,
      {bool showActions = false}) {
    return AppBar(
      backgroundColor: _primary,
      elevation: 0,
      centerTitle: true,
      title: appBarLogo ??
          Text(
            appBarTitle ?? "",
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
      actions: showActions ? appBarActions : null,
    );
  }

  // ── Inline top bar for tablet ───────────────────────────

  Widget _buildInlineTopBar(BuildContext context) {
    return Container(
      height: 56,
      color: _primary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (appBarLogo != null) appBarLogo!,
          if (appBarTitle != null)
            Text(
              appBarTitle!,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          const Spacer(),
          if (appBarActions != null) ...appBarActions!,
        ],
      ),
    );
  }

  // ── Bottom nav (mobile) ─────────────────────────────────

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(destinations.length, (i) {
              final bool selected = selectedIndex == i;
              return GestureDetector(
                onTap: () => onDestinationSelected(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 14 : 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? _primary.withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected
                            ? (destinations[i].selectedIcon ??
                            destinations[i].icon)
                            : destinations[i].icon,
                        color:
                        selected ? _primary : Colors.grey.shade400,
                        size: 22,
                      ),
                      if (selected) ...[
                        const SizedBox(width: 6),
                        Text(
                          destinations[i].label,
                          style: TextStyle(
                            color: _primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // ── Icon-only rail (tablet) ─────────────────────────────

  Widget _buildIconRail(BuildContext context) {
    return Container(
      width: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (sideRailHeader != null) ...[
              sideRailHeader!,
              const Divider(height: 1),
            ] else
              const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: destinations.length,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                itemBuilder: (context, i) {
                  final bool selected = selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Tooltip(
                      message: destinations[i].label,
                      preferBelow: false,
                      child: GestureDetector(
                        onTap: () => onDestinationSelected(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: selected
                                ? _primary.withOpacity(0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              selected
                                  ? (destinations[i].selectedIcon ??
                                  destinations[i].icon)
                                  : destinations[i].icon,
                              color: selected
                                  ? _primary
                                  : Colors.grey.shade400,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (sideRailFooter != null) ...[
              const Divider(height: 1),
              sideRailFooter!,
            ],
          ],
        ),
      ),
    );
  }

  // ── Labeled side rail (desktop) ─────────────────────────

  Widget _buildLabeledRail(BuildContext context) {
    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header / logo area
            if (sideRailHeader != null) ...[
              sideRailHeader!,
              const Divider(height: 1),
            ] else if (appBarLogo != null || appBarTitle != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 20),
                child: appBarLogo ??
                    Text(
                      appBarTitle ?? "",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _primary,
                      ),
                    ),
              ),
              const Divider(height: 1),
            ] else
              const SizedBox(height: 16),

            // Nav items
            Expanded(
              child: ListView.builder(
                itemCount: destinations.length,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                itemBuilder: (context, i) {
                  final bool selected = selectedIndex == i;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: GestureDetector(
                      onTap: () => onDestinationSelected(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected
                              ? _primary.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              selected
                                  ? (destinations[i].selectedIcon ??
                                  destinations[i].icon)
                                  : destinations[i].icon,
                              color: selected
                                  ? _primary
                                  : Colors.grey.shade500,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              destinations[i].label,
                              style: TextStyle(
                                color: selected
                                    ? _primary
                                    : Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
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

            // Footer
            if (sideRailFooter != null) ...[
              const Divider(height: 1),
              sideRailFooter!,
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RESPONSIVE PADDING WIDGET
// ─────────────────────────────────────────────────────────────

/// Wraps child with responsive padding that scales with screen size.
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobilePadding;
  final EdgeInsets? tabletPadding;
  final EdgeInsets? desktopPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobilePadding,
    this.tabletPadding,
    this.desktopPadding,
  });

  @override
  Widget build(BuildContext context) {
    final EdgeInsets padding = Responsive.value(
      context,
      mobile: mobilePadding ?? const EdgeInsets.all(16),
      tablet: tabletPadding ?? const EdgeInsets.all(24),
      desktop: desktopPadding ?? const EdgeInsets.all(32),
    );
    return Padding(padding: padding, child: child);
  }
}

// ─────────────────────────────────────────────────────────────
// RESPONSIVE GRID
// ─────────────────────────────────────────────────────────────

/// A responsive grid that automatically adjusts column count
/// based on screen size.
///
/// Example:
/// ```dart
/// ResponsiveGrid(
///   mobileColumns: 1,
///   tabletColumns: 2,
///   desktopColumns: 3,
///   spacing: 16,
///   children: items.map((e) => ItemCard(e)).toList(),
/// )
/// ```
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  final double runSpacing;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
    this.runSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final int columns = Responsive.value(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );

    return LayoutBuilder(builder: (context, constraints) {
      final double itemWidth =
          (constraints.maxWidth - (spacing * (columns - 1))) / columns;

      return Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: children
            .map((child) => SizedBox(width: itemWidth, child: child))
            .toList(),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────
// RESPONSIVE TEXT
// ─────────────────────────────────────────────────────────────

/// A Text widget that automatically scales font size across breakpoints.
///
/// Example:
/// ```dart
/// ResponsiveText(
///   "Hello World",
///   mobileFontSize: 16,
///   tabletFontSize: 20,
///   desktopFontSize: 24,
///   fontWeight: FontWeight.bold,
/// )
/// ```
class ResponsiveText extends StatelessWidget {
  final String text;
  final double mobileFontSize;
  final double tabletFontSize;
  final double desktopFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;

  const ResponsiveText(
      this.text, {
        super.key,
        required this.mobileFontSize,
        required this.tabletFontSize,
        required this.desktopFontSize,
        this.fontWeight,
        this.color,
        this.textAlign,
        this.maxLines,
        this.overflow,
        this.style,
      });

  @override
  Widget build(BuildContext context) {
    final double fontSize = Responsive.fontSize(
      context,
      mobile: mobileFontSize,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
    );
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SAFE SCROLLABLE COLUMN
// ─────────────────────────────────────────────────────────────

/// A Column wrapped in SingleChildScrollView with SafeArea.
/// Fixes the common "RenderFlex overflowed" error on smaller screens
/// or when the keyboard is shown.
///
/// Example:
/// ```dart
/// SafeScrollColumn(
///   padding: EdgeInsets.all(20),
///   children: [ ... ],
/// )
/// ```
class SafeScrollColumn extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final bool centerContent;

  const SafeScrollColumn({
    super.key,
    required this.children,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget column = Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisAlignment:
      centerContent ? MainAxisAlignment.center : mainAxisAlignment,
      mainAxisSize: centerContent ? MainAxisSize.max : MainAxisSize.min,
      children: children,
    );

    if (centerContent) {
      column = ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: column,
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: padding,
        child: column,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// RESPONSIVE CONTAINER (max-width centered)
// ─────────────────────────────────────────────────────────────

/// Centers content and constrains it to a max width on wide screens.
/// Prevents content from stretching too wide on desktop.
///
/// Example:
/// ```dart
/// MaxWidthContainer(
///   child: MyContent(),
/// )
/// ```
class MaxWidthContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;

  const MaxWidthContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? Responsive.maxContentWidth(context),
        ),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BUILDCONTEXT EXTENSIONS
// ─────────────────────────────────────────────────────────────

extension ScreenUtils on BuildContext {
  // Screen type
  bool get isMobile => Responsive.isMobile(this);
  bool get isTablet => Responsive.isTablet(this);
  bool get isDesktop => Responsive.isDesktop(this);
  bool get isWide => Responsive.isTabletOrDesktop(this);
  String get screenType => Responsive.screenType(this);

  // Dimensions
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  Size get screenSize => MediaQuery.of(this).size;
  double get topPadding => MediaQuery.of(this).padding.top;
  double get bottomPadding => MediaQuery.of(this).padding.bottom;

  // Responsive value shortcuts
  T rv<T>({required T mobile, required T tablet, required T desktop}) =>
      Responsive.value(this, mobile: mobile, tablet: tablet, desktop: desktop);

  double fontSize({
    required double mobile,
    required double tablet,
    required double desktop,
  }) =>
      Responsive.fontSize(this, mobile: mobile, tablet: tablet, desktop: desktop);

  // Padding
  EdgeInsets get pagePadding => Responsive.pagePadding(this);
  double get maxContentWidth => Responsive.maxContentWidth(this);
}