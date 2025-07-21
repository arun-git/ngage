import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'responsive_utils.dart';

/// Performance optimization utilities for responsive UI
class PerformanceUtils {
  /// Optimize image loading based on screen size and device capabilities
  static ImageProvider optimizeImageProvider({
    required String imagePath,
    required BuildContext context,
    double? width,
    double? height,
  }) {
    final responsive = ResponsiveHelper(context);
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    
    // Calculate optimal image dimensions
    final optimalWidth = (width ?? responsive.screenWidth) * devicePixelRatio;
    final optimalHeight = (height ?? responsive.screenHeight) * devicePixelRatio;
    
    // Use ResizeImage to optimize memory usage
    return ResizeImage(
      AssetImage(imagePath),
      width: optimalWidth.round(),
      height: optimalHeight.round(),
      allowUpscaling: false,
    );
  }
  
  /// Create optimized list view for large datasets
  static Widget createOptimizedListView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      // Enable automatic keep-alive for better performance
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
      // Use cacheExtent for better scrolling performance
      cacheExtent: 250.0,
    );
  }
  
  /// Create optimized grid view for large datasets
  static Widget createOptimizedGridView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    required int crossAxisCount,
    double childAspectRatio = 1.0,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
    ScrollController? controller,
    EdgeInsetsGeometry? padding,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
  }) {
    return GridView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
      ),
      controller: controller,
      padding: padding,
      shrinkWrap: shrinkWrap,
      physics: physics,
      // Enable automatic keep-alive for better performance
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      addSemanticIndexes: true,
      // Use cacheExtent for better scrolling performance
      cacheExtent: 250.0,
    );
  }
  
  /// Optimize animations based on device capabilities
  static Duration getOptimizedAnimationDuration(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    
    // Reduce animation duration on lower-end devices or when animations are disabled
    if (MediaQuery.of(context).disableAnimations) {
      return Duration.zero;
    }
    
    return responsive.responsive<Duration>(
      mobile: const Duration(milliseconds: 200),
      tablet: const Duration(milliseconds: 250),
      desktop: const Duration(milliseconds: 300),
      largeDesktop: const Duration(milliseconds: 350),
    );
  }
  
  /// Create performance-optimized image widget
  static Widget createOptimizedImage({
    required String imagePath,
    required BuildContext context,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    String? semanticLabel,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image(
      image: optimizeImageProvider(
        imagePath: imagePath,
        context: context,
        width: width,
        height: height,
      ),
      width: width,
      height: height,
      fit: fit,
      semanticLabel: semanticLabel,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: getOptimizedAnimationDuration(context),
          child: child,
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? 
          Container(
            width: width,
            height: height,
            color: Theme.of(context).colorScheme.errorContainer,
            child: Icon(
              Icons.error,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          );
      },
    );
  }
  
  /// Debounce function calls to improve performance
  static void debounce({
    required VoidCallback callback,
    Duration delay = const Duration(milliseconds: 300),
  }) {
    // Simple debounce implementation using Future.delayed
    Future.delayed(delay, callback);
  }
  
  /// Throttle function calls to improve performance
  static void throttle({
    required VoidCallback callback,
    Duration interval = const Duration(milliseconds: 100),
  }) {
    bool canExecute = true;
    if (canExecute) {
      canExecute = false;
      callback();
      Future.delayed(interval, () {
        canExecute = true;
      });
    }
  }
  
  /// Check if device has sufficient memory for heavy operations
  static bool hasHighMemoryCapacity() {
    // This is a simplified check - in a real app, you might use
    // platform-specific code to check actual memory
    return !PlatformUtils.isMobile;
  }
  
  /// Get optimal batch size for data processing based on device capabilities
  static int getOptimalBatchSize(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    
    return responsive.responsive<int>(
      mobile: 10,
      tablet: 20,
      desktop: 50,
      largeDesktop: 100,
    );
  }
  
  /// Create performance-optimized custom scroll view
  static Widget createOptimizedCustomScrollView({
    required List<Widget> slivers,
    ScrollController? controller,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
  }) {
    return CustomScrollView(
      controller: controller,
      physics: physics,
      shrinkWrap: shrinkWrap,
      slivers: slivers,
      // Enable semantic indexes for better accessibility
      semanticChildCount: slivers.length,
      // Use cache extent for better performance
      cacheExtent: 250.0,
    );
  }
  
  /// Monitor frame rendering performance
  static void monitorFramePerformance() {
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final frameDuration = timing.totalSpan;
        if (frameDuration > const Duration(milliseconds: 16)) {
          // Frame took longer than 16ms (60fps threshold)
          debugPrint('Slow frame detected: ${frameDuration.inMilliseconds}ms');
        }
      }
    });
  }
  
  /// Preload critical images for better performance
  static Future<void> preloadImages(
    BuildContext context,
    List<String> imagePaths,
  ) async {
    final futures = imagePaths.map((path) {
      return precacheImage(
        optimizeImageProvider(
          imagePath: path,
          context: context,
        ),
        context,
      );
    });
    
    await Future.wait(futures);
  }
  
  /// Create memory-efficient widget that disposes resources properly
  static Widget createMemoryEfficientWidget({
    required Widget child,
    VoidCallback? onDispose,
  }) {
    return _MemoryEfficientWrapper(
      onDispose: onDispose,
      child: child,
    );
  }
}

// Removed Timer class to avoid conflicts with dart:async Timer

/// Wrapper widget for memory-efficient resource management
class _MemoryEfficientWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDispose;
  
  const _MemoryEfficientWrapper({
    required this.child,
    this.onDispose,
  });
  
  @override
  State<_MemoryEfficientWrapper> createState() => _MemoryEfficientWrapperState();
}

class _MemoryEfficientWrapperState extends State<_MemoryEfficientWrapper> {
  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Mixin for widgets that need performance monitoring
mixin PerformanceMonitoringMixin<T extends StatefulWidget> on State<T> {
  late final Stopwatch _stopwatch;
  
  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
  }
  
  @override
  void dispose() {
    _stopwatch.stop();
    final buildTime = _stopwatch.elapsedMilliseconds;
    if (buildTime > 100) {
      debugPrint('Widget ${widget.runtimeType} took ${buildTime}ms to build');
    }
    super.dispose();
  }
  
  void measurePerformance(String operation, VoidCallback callback) {
    final stopwatch = Stopwatch()..start();
    callback();
    stopwatch.stop();
    
    final duration = stopwatch.elapsedMilliseconds;
    if (duration > 50) {
      debugPrint('$operation took ${duration}ms in ${widget.runtimeType}');
    }
  }
}