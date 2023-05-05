import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RotatePanZoomHandler extends StatefulWidget {
  final Widget child;
  const RotatePanZoomHandler(
      {required this.child, this.onPan, this.onRotate, this.onZoom, Key? key})
      : super(key: key);
  final VoidCallback? onZoom;
  final VoidCallback? onPan;
  final VoidCallback? onRotate;

  @override
  RotatePanZoomHandlerState createState() => RotatePanZoomHandlerState();
}

class RotatePanZoomHandlerState extends State<RotatePanZoomHandler> {
  static const minPanDelta = 50;
  static const minZoomDelta = .25;
  static const minRotateDelta = .25;

  double? xStart;
  double? yStart;
  double? scaleStart;
  double? rotateStart;

  bool panned = false, zoomed = false, rotated = false;

  @override
  Widget build(BuildContext context) {
    print("RotatePanZoomHandlerState.build");
    return RawGestureDetector(
        behavior: HitTestBehavior.translucent,
        gestures: {
          ScaleGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<ScaleGestureRecognizer>(
            () => ScaleGestureRecognizer(), //constructor
            (ScaleGestureRecognizer instance) {
              instance.onStart = _handleStart;
              instance.onUpdate = _handleUpdate;
              instance.onEnd = _handleEnd;
            },
          ),
          DoubleTapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<DoubleTapGestureRecognizer>(
            () => DoubleTapGestureRecognizer(), //constructor
            (DoubleTapGestureRecognizer instance) {
              instance.onDoubleTap = () {
                var onPan = widget.onPan;
                if (!panned && onPan != null) {
                  panned = true;
                  onPan();
                }
                var onZoom = widget.onZoom;
                if (!zoomed && onZoom != null) {
                  zoomed = true;
                  onZoom();
                }
              };
            },
          )
        },
        child: widget.child);
  }

  void _reset() {
    panned = false;
    zoomed = false;
    rotated = false;
    scaleStart = null;
    rotateStart = null;
  }

  void _handleStart(ScaleStartDetails details) {
    print('gestures start $details');
    _reset();
    xStart = details.focalPoint.dx;
    yStart = details.focalPoint.dy;
  }

  void _handleUpdate(ScaleUpdateDetails details) {
    print('gestures update $details');
    var scale = scaleStart ??= details.scale;
    var rotation = rotateStart ??= details.rotation;

    var onZoom = widget.onZoom;
    if (!zoomed &&
        onZoom != null &&
        minZoomDelta < (scale - details.scale).abs()) {
      zoomed = true;
      onZoom();
    }

    var onPan = widget.onPan, x = xStart, y = yStart;
    if (!panned &&
        onPan != null &&
        x != null &&
        y != null &&
        (minPanDelta < (x - details.focalPoint.dx).abs() ||
            minPanDelta < (y - details.focalPoint.dy).abs())) {
      panned = true;
      onPan();
    }

    var onRotate = widget.onRotate;
    if (!rotated &&
        onRotate != null &&
        minRotateDelta < (rotation - details.rotation).abs()) {
      rotated = true;
      onRotate();
    }
  }

  void _handleEnd(ScaleEndDetails details) {
    print('gestures end $details');
  }
}

/// from https://github.com/flutter/flutter/issues/18450#issuecomment-575447316, could be helpful...
// class StackWithAllChildrenReceiveEvents extends Stack {
//   StackWithAllChildrenReceiveEvents({
//     Key? key,
//     AlignmentDirectional alignment = AlignmentDirectional.topStart,
//     TextDirection textDirection = TextDirection.ltr,
//     StackFit fit = StackFit.loose,
//     clipBehavior = Clip.none,
//     List<Widget> children = const <Widget>[],
//   }) : super(
//           key: key,
//           alignment: alignment,
//           textDirection: textDirection,
//           fit: fit,
//           clipBehavior: clipBehavior,
//           children: children,
//         );
//
//   @override
//   RenderStackWithAllChildrenReceiveEvents createRenderObject(
//       BuildContext context) {
//     return RenderStackWithAllChildrenReceiveEvents(
//       alignment: alignment,
//       textDirection: textDirection ?? Directionality.of(context),
//       fit: fit,
//       clipBehavior: clipBehavior,
//     );
//   }
//
//   @override
//   void updateRenderObject(BuildContext context,
//       RenderStackWithAllChildrenReceiveEvents renderObject) {
//     renderObject
//       ..alignment = alignment
//       ..textDirection = textDirection ?? Directionality.of(context)
//       ..fit = fit
//       ..clipBehavior = clipBehavior;
//   }
//
//   @override
//   void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//     super.debugFillProperties(properties);
//     properties
//         .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
//     properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
//         defaultValue: null));
//     properties.add(EnumProperty<StackFit>('fit', fit));
//     properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior));
//   }
// }
//
// class RenderStackWithAllChildrenReceiveEvents extends RenderStack {
//   RenderStackWithAllChildrenReceiveEvents({
//     AlignmentGeometry alignment = AlignmentDirectional.topStart,
//     required TextDirection textDirection,
//     StackFit fit = StackFit.loose,
//     Clip clipBehavior = Clip.none,
//   }) : super(
//           alignment: alignment,
//           textDirection: textDirection,
//           fit: fit,
//           clipBehavior: clipBehavior,
//         );
//
//   bool allCdefaultHitTestChildren(BoxHitTestResult result,
//       {required Offset position}) {
//     // the x, y parameters have the top left of the node's box as the origin
//     RenderBox? child = lastChild;
//     while (child != null) {
//       final StackParentData childParentData =
//           (child.parentData! as StackParentData);
//       child.hitTest(result, position: position - (childParentData.offset));
//       child = childParentData.previousSibling;
//     }
//     return false;
//   }
//
//   @override
//   bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
//     return allCdefaultHitTestChildren(result, position: position);
//   }
// }

/// Invisible to hit testing, but allows subtree to receive gestures
class TransparentPointer extends SingleChildRenderObjectWidget {
  const TransparentPointer({
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderTransparentPointer createRenderObject(BuildContext context) {
    return RenderTransparentPointer();
  }
}

class RenderTransparentPointer extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // forward hits to our child:
    super.hitTest(result, position: position);
    // but report to our parent that we are not hit
    return false;
  }
}
