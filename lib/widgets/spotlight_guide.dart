import 'package:flutter/material.dart';

class SpotlightGuideStep {
  const SpotlightGuideStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.padding = 8,
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final double padding;
}

class SpotlightGuide {
  static OverlayEntry? _entry;
  static bool _isShowing = false;

  static void _dismissEntry() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    if (entry.mounted) {
      entry.remove();
    }
  }

  static Future<void> show(
    BuildContext context, {
    required List<SpotlightGuideStep> steps,
    required VoidCallback onFinished,
    required String skipLabel,
    required String nextLabel,
    required String doneLabel,
  }) async {
    if (steps.isEmpty) return;

    _dismissEntry();
    _isShowing = true;

    final overlay = Overlay.of(context);
    var stepIndex = 0;

    void close() {
      if (!_isShowing) return;
      _isShowing = false;
      _dismissEntry();
      onFinished();
    }

    void showStep() {
      if (!_isShowing) return;

      _dismissEntry();

      final step = steps[stepIndex];
      final targetContext = step.targetKey.currentContext;
      if (targetContext == null) {
        if (stepIndex < steps.length - 1) {
          stepIndex++;
          WidgetsBinding.instance.addPostFrameCallback((_) => showStep());
        } else {
          close();
        }
        return;
      }

      final box = targetContext.findRenderObject() as RenderBox;
      final offset = box.localToGlobal(Offset.zero);
      final targetRect = Rect.fromLTWH(
        offset.dx - step.padding,
        offset.dy - step.padding,
        box.size.width + step.padding * 2,
        box.size.height + step.padding * 2,
      );

      _entry = OverlayEntry(
        builder: (context) => _SpotlightGuideOverlay(
          targetRect: targetRect,
          title: step.title,
          description: step.description,
          stepIndex: stepIndex,
          totalSteps: steps.length,
          skipLabel: skipLabel,
          nextLabel: nextLabel,
          doneLabel: doneLabel,
          onSkip: close,
          onNext: () {
            if (stepIndex < steps.length - 1) {
              stepIndex++;
              showStep();
            } else {
              close();
            }
          },
        ),
      );

      if (!_isShowing) return;
      overlay.insert(_entry!);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => showStep());
  }
}

class _SpotlightGuideOverlay extends StatelessWidget {
  const _SpotlightGuideOverlay({
    required this.targetRect,
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.totalSteps,
    required this.skipLabel,
    required this.nextLabel,
    required this.doneLabel,
    required this.onSkip,
    required this.onNext,
  });

  final Rect targetRect;
  final String title;
  final String description;
  final int stepIndex;
  final int totalSteps;
  final String skipLabel;
  final String nextLabel;
  final String doneLabel;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  static const _green = Color(0xFF2E7D32);

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final showBelow = targetRect.center.dy < screen.height * 0.45;
    final cardTop = showBelow ? targetRect.bottom + 16 : null;
    final cardBottom = showBelow ? null : screen.height - targetRect.top + 16;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SpotlightPainter(targetRect: targetRect),
            ),
          ),
          Positioned(
            left: targetRect.left,
            top: targetRect.top,
            width: targetRect.width,
            height: targetRect.height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _green, width: 2),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: cardTop,
            bottom: cardBottom,
            child: Align(
              alignment: showBelow ? Alignment.topCenter : Alignment.bottomCenter,
              child: _GuideCard(
                title: title,
                description: description,
                stepIndex: stepIndex,
                totalSteps: totalSteps,
                skipLabel: skipLabel,
                nextLabel: nextLabel,
                doneLabel: doneLabel,
                onSkip: onSkip,
                onNext: onNext,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.title,
    required this.description,
    required this.stepIndex,
    required this.totalSteps,
    required this.skipLabel,
    required this.nextLabel,
    required this.doneLabel,
    required this.onSkip,
    required this.onNext,
  });

  final String title;
  final String description;
  final int stepIndex;
  final int totalSteps;
  final String skipLabel;
  final String nextLabel;
  final String doneLabel;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = stepIndex == totalSteps - 1;

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${stepIndex + 1}/$totalSteps',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: onSkip, child: Text(skipLabel)),
                const Spacer(),
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isLast ? doneLabel : nextLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.targetRect});

  final Rect targetRect;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path()
      ..addRRect(
        RRect.fromRectAndRadius(targetRect, const Radius.circular(12)),
      );

    final paint = Paint()..color = Colors.black.withValues(alpha: 0.72);
    canvas.drawPath(
      Path.combine(PathOperation.difference, overlay, hole),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
