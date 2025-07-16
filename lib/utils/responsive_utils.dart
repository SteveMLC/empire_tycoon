import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Comprehensive responsive design utility for Empire Tycoon
/// Handles device-specific adaptations for optimal gameplay across all screen sizes
class ResponsiveUtils {
  static const double _baseWidth = 375.0;  // iPhone 6/7/8 as reference
  static const double _baseHeight = 667.0; // iPhone 6/7/8 as reference
  static const double _tabletWidth = 768.0; // Tablet breakpoint
  
  /// Device screen characteristics
  final double screenWidth;
  final double screenHeight;
  final double screenDensity;
  final double textScaleFactor;
  final bool isTablet;
  final bool isCompact;
  final bool isVeryCompact;
  final DeviceType deviceType;
  
  ResponsiveUtils._({
    required this.screenWidth,
    required this.screenHeight,
    required this.screenDensity,
    required this.textScaleFactor,
    required this.isTablet,
    required this.isCompact,
    required this.isVeryCompact,
    required this.deviceType,
  });
  
  /// Factory constructor that analyzes MediaQuery data
  factory ResponsiveUtils.of(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final density = mediaQuery.devicePixelRatio;
    final textScale = mediaQuery.textScaler.scale(1.0);
    
    // Calculate device characteristics
    final isTablet = size.width >= _tabletWidth;
    final isCompact = size.height < 700 || size.width < 350;
    final isVeryCompact = size.height < 600 || size.width < 320;
    
    // Determine device type for specific optimizations
    DeviceType deviceType = DeviceType.normal;
    if (isVeryCompact) {
      deviceType = DeviceType.verySmall;
    } else if (isCompact) {
      deviceType = DeviceType.small;
    } else if (isTablet) {
      deviceType = DeviceType.tablet;
    }
    
    return ResponsiveUtils._(
      screenWidth: size.width,
      screenHeight: size.height,
      screenDensity: density,
      textScaleFactor: textScale,
      isTablet: isTablet,
      isCompact: isCompact,
      isVeryCompact: isVeryCompact,
      deviceType: deviceType,
    );
  }
  
  /// Scale factor based on screen width relative to base design
  double get widthScale => math.min(screenWidth / _baseWidth, 1.2);
  
  /// Scale factor based on screen height relative to base design
  double get heightScale => math.min(screenHeight / _baseHeight, 1.2);
  
  /// Balanced scale factor for general UI elements
  double get generalScale => math.sqrt(widthScale * heightScale);
  
  /// Safe scale factor that never goes below 0.8 for readability
  double get safeScale => math.max(generalScale, 0.8);
  
  /// Font scale factor with accessibility considerations
  double get fontScale {
    double baseScale = generalScale;
    
    // Reduce font size on very small screens to fit more content
    if (isVeryCompact) {
      baseScale *= 0.85;
    } else if (isCompact) {
      baseScale *= 0.9;
    }
    
    // Consider user's text scale preference but cap it for game UI
    double adjustedTextScale = math.min(textScaleFactor, 1.3);
    return math.max(baseScale * adjustedTextScale, 0.75);
  }
  
  /// Responsive font size calculation
  double fontSize(double baseSize) {
    return (baseSize * fontScale).roundToDouble();
  }
  
  /// Responsive icon size calculation
  double iconSize(double baseSize) {
    return (baseSize * safeScale).roundToDouble();
  }
  
  /// Responsive padding calculation
  EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    final scale = safeScale;
    
    if (all != null) {
      return EdgeInsets.all((all * scale).roundToDouble());
    }
    
    return EdgeInsets.only(
      top: (top ?? vertical ?? 0) * scale,
      bottom: (bottom ?? vertical ?? 0) * scale,
      left: (left ?? horizontal ?? 0) * scale,
      right: (right ?? horizontal ?? 0) * scale,
    );
  }
  
  /// Responsive margin calculation
  EdgeInsets margin({
    double? all,
    double? horizontal,
    double? vertical,
    double? top,
    double? bottom,
    double? left,
    double? right,
  }) {
    return padding(
      all: all,
      horizontal: horizontal,
      vertical: vertical,
      top: top,
      bottom: bottom,
      left: left,
      right: right,
    );
  }
  
  /// Responsive spacing calculation
  double spacing(double baseSpacing) {
    return (baseSpacing * safeScale).roundToDouble();
  }
  
  /// Get device-specific layout constraints
  LayoutConstraints get layoutConstraints {
    switch (deviceType) {
      case DeviceType.verySmall:
        return LayoutConstraints(
          topPanelHeight: 80,
          tabBarHeight: 48,
          cardPadding: 8,
          listItemPadding: 6,
          buttonHeight: 36,
          minimumTapTarget: 40,
        );
      case DeviceType.small:
        return LayoutConstraints(
          topPanelHeight: 90,
          tabBarHeight: 52,
          cardPadding: 10,
          listItemPadding: 8,
          buttonHeight: 40,
          minimumTapTarget: 44,
        );
      case DeviceType.normal:
        return LayoutConstraints(
          topPanelHeight: 100,
          tabBarHeight: 56,
          cardPadding: 12,
          listItemPadding: 10,
          buttonHeight: 44,
          minimumTapTarget: 48,
        );
      case DeviceType.tablet:
        return LayoutConstraints(
          topPanelHeight: 120,
          tabBarHeight: 64,
          cardPadding: 16,
          listItemPadding: 12,
          buttonHeight: 48,
          minimumTapTarget: 56,
        );
    }
  }
  
  /// Get adaptive text theme based on device characteristics
  TextTheme getAdaptiveTextTheme(TextTheme baseTheme) {
    return TextTheme(
      displayLarge: baseTheme.displayLarge?.copyWith(fontSize: fontSize(32)),
      displayMedium: baseTheme.displayMedium?.copyWith(fontSize: fontSize(24)),
      displaySmall: baseTheme.displaySmall?.copyWith(fontSize: fontSize(20)),
      headlineLarge: baseTheme.headlineLarge?.copyWith(fontSize: fontSize(28)),
      headlineMedium: baseTheme.headlineMedium?.copyWith(fontSize: fontSize(22)),
      headlineSmall: baseTheme.headlineSmall?.copyWith(fontSize: fontSize(18)),
      titleLarge: baseTheme.titleLarge?.copyWith(fontSize: fontSize(20)),
      titleMedium: baseTheme.titleMedium?.copyWith(fontSize: fontSize(16)),
      titleSmall: baseTheme.titleSmall?.copyWith(fontSize: fontSize(14)),
      bodyLarge: baseTheme.bodyLarge?.copyWith(fontSize: fontSize(16)),
      bodyMedium: baseTheme.bodyMedium?.copyWith(fontSize: fontSize(14)),
      bodySmall: baseTheme.bodySmall?.copyWith(fontSize: fontSize(12)),
      labelLarge: baseTheme.labelLarge?.copyWith(fontSize: fontSize(14)),
      labelMedium: baseTheme.labelMedium?.copyWith(fontSize: fontSize(12)),
      labelSmall: baseTheme.labelSmall?.copyWith(fontSize: fontSize(11)),
    );
  }
  
  /// Calculate safe area for critical UI elements (like tap zones)
  double get safeAreaTop => math.max(spacing(60), 60);
  double get safeAreaBottom => math.max(spacing(60), 60);
  
  /// Check if device needs aggressive space optimization
  bool get needsSpaceOptimization => isVeryCompact || screenHeight < 640;
  
  /// Get optimized flex values for layout
  FlexValues get flexValues {
    if (isVeryCompact) {
      return FlexValues(header: 2, content: 6, footer: 1);
    } else if (isCompact) {
      return FlexValues(header: 2, content: 7, footer: 1);
    } else {
      return FlexValues(header: 2, content: 8, footer: 1);
    }
  }
}

/// Device type classification for specific optimizations
enum DeviceType {
  verySmall,  // < 320px wide or < 600px high
  small,      // < 350px wide or < 700px high
  normal,     // Standard phone sizes
  tablet      // >= 768px wide
}

/// Layout constraint values for different device types
class LayoutConstraints {
  final double topPanelHeight;
  final double tabBarHeight;
  final double cardPadding;
  final double listItemPadding;
  final double buttonHeight;
  final double minimumTapTarget;
  
  const LayoutConstraints({
    required this.topPanelHeight,
    required this.tabBarHeight,
    required this.cardPadding,
    required this.listItemPadding,
    required this.buttonHeight,
    required this.minimumTapTarget,
  });
}

/// Flex values for different layout sections
class FlexValues {
  final int header;
  final int content;
  final int footer;
  
  const FlexValues({
    required this.header,
    required this.content,
    required this.footer,
  });
}

/// Extension on BuildContext for easy access to responsive utilities
extension ResponsiveContext on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils.of(this);
}

/// Helper widget for responsive sizing
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  
  const ResponsiveContainer({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Container(
      width: width != null ? responsive.spacing(width!) : null,
      height: height != null ? responsive.spacing(height!) : null,
      padding: padding != null ? responsive.padding(
        top: padding!.top,
        bottom: padding!.bottom,
        left: padding!.left,
        right: padding!.right,
      ) : null,
      margin: margin != null ? responsive.margin(
        top: margin!.top,
        bottom: margin!.bottom,
        left: margin!.left,
        right: margin!.right,
      ) : null,
      child: child,
    );
  }
}

/// Responsive text widget that automatically scales
class ResponsiveText extends StatelessWidget {
  final String text;
  final double baseFontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextStyle? style;
  
  const ResponsiveText(
    this.text, {
    Key? key,
    required this.baseFontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.style,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: responsive.fontSize(baseFontSize),
        fontWeight: fontWeight,
        color: color,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
} 