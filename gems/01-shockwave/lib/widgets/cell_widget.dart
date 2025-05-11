import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shockwave_demo/widgets/consts.dart';

enum CellAnimationPhase {
  identity,
  compress,
  expand;

  double get scaleAdjustment => switch (this) {
        CellAnimationPhase.identity => 0,
        CellAnimationPhase.compress => -0.25,
        CellAnimationPhase.expand => 0.2,
      };

  double get brightnessAdjustment => switch (this) {
        CellAnimationPhase.identity => 0,
        CellAnimationPhase.compress => 0,
        CellAnimationPhase.expand => -0.2,
      };
}

/// Determine the Euclidean distance between two points.
double calculateDistance(
  Offset point1,
  Offset point2,
) {
  return math.sqrt(
    math.pow(point2.dx - point1.dx, 2) + math.pow(point2.dy - point1.dy, 2),
  );
}

class CellWidget extends StatefulWidget {
  const CellWidget({
    required this.columnIndex,
    required this.rowIndex,
    required this.waveOrigin,
    required this.trigger,
    required this.onTap,
    required this.onAnimationComplete,
    super.key,
  });

  final int columnIndex;
  final int rowIndex;
  final Offset waveOrigin;
  final int trigger;
  final void Function(Offset) onTap;
  final VoidCallback onAnimationComplete;

  @override
  State<CellWidget> createState() => _CellWidgetState();
}

class _CellWidgetState extends State<CellWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  late Offset _cellCoords;
  double _originDistance = 0;
  double _waveImpact = 0;
  Duration _delayDuration = Duration.zero;

  static const int _compressDurationMs = 200;
  static const int _expandDurationMs = 100;
  static const int _settleDurationMs = 400;

  final double maxGridDistance = calculateDistance(
    Offset.zero,
    Offset((kColumnCount - 1).toDouble(), (kRowCount - 1).toDouble()),
  );

  Color adjustBrightness(
    Color color,
    double adjustment,
  ) {
    final hslColor = HSLColor.fromColor(color);

    /// Adjust lightness: positive makes it lighter, negative makes it darker.
    /// Clamp between 0.0 (black) and 1.0 (white).
    final newLightness = (hslColor.lightness + adjustment).clamp(0.0, 1.0);

    return hslColor.withLightness(newLightness).toColor();
  }

  @override
  void initState() {
    super.initState();

    _cellCoords = Offset(
      widget.columnIndex.toDouble(),
      widget.rowIndex.toDouble(),
    );

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds:
            _compressDurationMs + _expandDurationMs + _settleDurationMs,
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });

    // Initialize with default animations (identity state)
    _calculateAnimationParameters();
    _setupAnimations();
  }

  /// Called when the widget configuration changes.
  ///
  /// This method is overridden to respond to changes in `widget.trigger` or
  /// `widget.waveOrigin`. If either of these properties changes, it indicates
  /// that the shockwave animation needs to be re-triggered or its origin updated.
  ///
  /// When a change is detected:
  /// 1. `_calculateAnimationParameters()` is called to re-compute parameters
  ///    like the delay and duration, potentially based on the new `waveOrigin`.
  /// 2. `_setupAnimations()` is called to re-configure the animation tweens,
  ///    as parameters like `waveImpact` (which affects the animation's intensity)
  ///    might have changed as a result of `_calculateAnimationParameters()`.
  /// 3. The `_controller` (AnimationController) is reset to its initial state.
  /// 4. If the widget is still `mounted` (i.e., part of the widget tree),
  ///    a delayed future is scheduled. After `_delayDuration`, if the widget
  ///    is still `mounted`, `_controller.forward()` is called to start the
  ///    animation. This delay allows the shockwave effect to propagate from cell
  ///    to cell based on their distance from the `waveOrigin`.
  @override
  void didUpdateWidget(CellWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger ||
        widget.waveOrigin != oldWidget.waveOrigin) {
      _calculateAnimationParameters();
      // Re-configure tweens because waveImpact might have changed
      _setupAnimations();
      _controller.reset();
      if (mounted) {
        Future.delayed(_delayDuration, () {
          if (mounted) {
            _controller.forward();
          }
        });
      }
    }
  }

  /// Calculates animation parameters based on the cell's position relative to the wave origin.
  ///
  /// This method determines:
  /// - `_originDistance`: The Euclidean distance from the `widget.waveOrigin` to the
  ///   center of this cell (`_cellCoords`).
  /// - `normalizedDistance`: The `_originDistance` normalized with respect to
  ///   `maxGridDistance`. If `maxGridDistance` is very small (close to zero),
  ///   this is treated as 0.0 to prevent division by zero or excessively large values.
  /// - `_waveImpact`: A value between 0.0 and 1.0 representing the intensity of the
  ///   wave's effect on this cell. It's calculated as `(1.0 - normalizedDistance)`,
  ///   meaning cells closer to the origin experience a stronger impact (closer to 1.0),
  ///   and cells further away experience a weaker impact (closer to 0.0). The result
  ///   is clamped to ensure it stays within the [0.0, 1.0] range.
  /// - `_delayDuration`: The animation delay for this cell. It's calculated by
  ///   multiplying the `_originDistance` by 70 milliseconds. This creates a ripple
  ///   effect where cells further from the origin start their animation later.
  void _calculateAnimationParameters() {
    _originDistance = calculateDistance(widget.waveOrigin, _cellCoords);
    final normalizedDistance =
        (maxGridDistance > 0.001) ? (_originDistance / maxGridDistance) : 0.0;

    // Subtracting the normalized distance from one for fading effect
    _waveImpact = (1.0 - normalizedDistance).clamp(0.0, 1.0);

    // More efficient delay calculation
    _delayDuration = Duration(
      milliseconds: (_originDistance * 70).round(), // 0.07 * 1000
    );
  }

  /// Sets up the scale and color animations for the cell.
  ///
  /// This method configures the animation controller's duration and defines
  /// two `TweenSequence` animations: `_scaleAnimation` and `_colorAnimation`.
  ///
  /// The total animation duration is calculated based on `_compressDurationMs`,
  /// `_expandDurationMs`, and `_settleDurationMs`, with the settle duration
  /// being slightly adjusted by `_waveImpact` to shorten it as the impact increases.
  ///
  /// **Scale Animation (`_scaleAnimation`):**
  /// This animation controls the scaling of the cell through three phases:
  /// 1. **Identity to Compress**: Scales from an initial size (adjusted by `_waveImpact`)
  ///    to a compressed size. Uses `Curves.easeInOut`.
  /// 2. **Compress to Expand**: Scales from the compressed size to an expanded size.
  ///    Uses `Curves.easeInOut`.
  /// 3. **Expand to Identity**: Scales from the expanded size back to the initial size.
  ///    Uses `Curves.easeOutBack` for a slight overshoot and settle effect.
  /// The target scales for each phase are determined by `CellAnimationPhase.scaleAdjustment`
  /// and modulated by `_waveImpact`.
  ///
  /// **Color Animation (`_colorAnimation`):**
  /// This animation controls the color of the cell, synchronized with the scale animation:
  /// 1. **Identity to Compress**: Transitions from an initial color (base color adjusted
  ///    for brightness by `_waveImpact`) to a "compress" color.
  /// 2. **Compress to Expand**: Transitions from the "compress" color to an "expand" color.
  /// 3. **Expand to Identity**: Transitions from the "expand" color back to the initial color.
  /// The target colors for each phase are derived by adjusting the brightness of `kBaseColor`
  /// based on `CellAnimationPhase.brightnessAdjustment` and `_waveImpact`.
  ///
  /// Both animations use the same `_controller` and their phase durations are weighted by
  /// `_compressDurationMs`, `_expandDurationMs`, and `_settleDurationMs`.
  void _setupAnimations() {
    // Update controller duration just in case
    _controller.duration = Duration(
      milliseconds: (_compressDurationMs +
              _expandDurationMs +
              _settleDurationMs * (1.0 - _waveImpact * 0.5))
          .round(),
    );

    final identityScale = 1.0 +
        CellAnimationPhase.identity.scaleAdjustment *
            _waveImpact; // Should be 1.0
    final compressScaleTarget =
        1.0 + CellAnimationPhase.compress.scaleAdjustment * _waveImpact;
    final expandScaleTarget =
        1.0 + CellAnimationPhase.expand.scaleAdjustment * _waveImpact;

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: identityScale,
          end: compressScaleTarget,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: _compressDurationMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: compressScaleTarget,
          end: expandScaleTarget,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: _expandDurationMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: expandScaleTarget,
          end: identityScale,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: _settleDurationMs.toDouble(),
      ),
    ]).animate(_controller);

    final identityColor = adjustBrightness(
      kBaseColor,
      CellAnimationPhase.identity.brightnessAdjustment * _waveImpact,
    );
    final compressColorTarget = adjustBrightness(
      kBaseColor,
      CellAnimationPhase.compress.brightnessAdjustment * _waveImpact,
    );
    final expandColorTarget = adjustBrightness(
      kBaseColor,
      CellAnimationPhase.expand.brightnessAdjustment * _waveImpact,
    );

    _colorAnimation = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: identityColor, end: compressColorTarget),
        weight: _compressDurationMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: compressColorTarget, end: expandColorTarget),
        weight: _expandDurationMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: expandColorTarget, end: identityColor),
        weight: _settleDurationMs.toDouble(),
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _controller.isAnimating ? null : () => widget.onTap(_cellCoords),
      child: AnimatedBuilder(
        animation: _controller,
        child: const SizedBox(
          width: kCellSize,
          height: kCellSize,
        ),
        builder: (context, staticChild) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            // The DecoratedBox applies the changing decoration
            // to the staticChild.
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: _colorAnimation.value ?? kBaseColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: staticChild, // The SizedBox
            ),
          );
        },
      ),
    );
  }
}
