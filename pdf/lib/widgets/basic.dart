/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

part of widget;

enum BoxFit {
  fill,
  contain,
  cover,
  fitWidth,
  fitHeight,

  none,

  scaleDown
}

class LimitedBox extends SingleChildWidget {
  LimitedBox({
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
    Widget child,
  })  : assert(maxWidth != null && maxWidth >= 0.0),
        assert(maxHeight != null && maxHeight >= 0.0),
        super(child: child);

  final double maxWidth;

  final double maxHeight;

  BoxConstraints _limitConstraints(BoxConstraints constraints) {
    return BoxConstraints(
        minWidth: constraints.minWidth,
        maxWidth: constraints.hasBoundedWidth
            ? constraints.maxWidth
            : constraints.constrainWidth(maxWidth),
        minHeight: constraints.minHeight,
        maxHeight: constraints.hasBoundedHeight
            ? constraints.maxHeight
            : constraints.constrainHeight(maxHeight));
  }

  @override
  void layout(Context context, BoxConstraints constraints,
      {parentUsesSize = false}) {
    PdfPoint size;
    if (child != null) {
      child.layout(context, _limitConstraints(constraints),
          parentUsesSize: true);
      size = constraints.constrain(child.box.size);
    } else {
      size = _limitConstraints(constraints).constrain(PdfPoint.zero);
    }
    box = PdfRect(box.x, box.y, size.x, size.y);
  }
}

class Padding extends SingleChildWidget {
  Padding({
    @required this.padding,
    Widget child,
  })  : assert(padding != null),
        super(child: child);

  final EdgeInsets padding;

  @override
  void layout(Context context, BoxConstraints constraints,
      {parentUsesSize = false}) {
    if (child != null) {
      final childConstraints = constraints.deflate(padding);
      child.layout(context, childConstraints, parentUsesSize: parentUsesSize);
      box = constraints.constrainRect(
          width: child.box.w + padding.horizontal,
          height: child.box.h + padding.vertical);
    } else {
      box = constraints.constrainRect(
          width: padding.horizontal, height: padding.vertical);
    }
  }

  @override
  void debugPaint(Context context) {
    context.canvas
      ..setFillColor(PdfColor.lime)
      ..moveTo(box.x, box.y)
      ..lineTo(box.r, box.y)
      ..lineTo(box.r, box.t)
      ..lineTo(box.x, box.t)
      ..moveTo(box.x + padding.left, box.y + padding.bottom)
      ..lineTo(box.x + padding.left, box.t - padding.top)
      ..lineTo(box.r - padding.right, box.t - padding.top)
      ..lineTo(box.r - padding.right, box.y + padding.bottom)
      ..fillPath();
  }

  @override
  void paint(Context context) {
    assert(() {
      if (Document.debug) debugPaint(context);
      return true;
    }());

    if (child != null) {
      final mat = Matrix4.identity();
      mat.translate(box.x + padding.left, box.y + padding.bottom);
      context.canvas
        ..saveContext()
        ..setTransform(mat);
      child.paint(context);
      context.canvas.restoreContext();
    }
  }
}

class Transform extends SingleChildWidget {
  Transform({
    @required this.transform,
    this.origin,
    this.alignment,
    Widget child,
  })  : assert(transform != null),
        super(child: child);

  /// Creates a widget that transforms its child using a rotation around the
  /// center.
  Transform.rotate({
    @required double angle,
    this.origin,
    this.alignment = Alignment.center,
    Widget child,
  })  : transform = Matrix4.rotationZ(angle),
        super(child: child);

  /// Creates a widget that transforms its child using a translation.
  Transform.translate({
    @required PdfPoint offset,
    Widget child,
  })  : transform = Matrix4.translationValues(offset.x, offset.y, 0.0),
        origin = null,
        alignment = null,
        super(child: child);

  /// Creates a widget that scales its child uniformly.
  Transform.scale({
    @required double scale,
    this.origin,
    this.alignment = Alignment.center,
    Widget child,
  })  : transform = Matrix4.diagonal3Values(scale, scale, 1.0),
        super(child: child);

  /// The matrix to transform the child by during painting.
  final Matrix4 transform;

  /// The origin of the coordinate system
  final PdfPoint origin;

  /// The alignment of the origin, relative to the size of the box.
  final Alignment alignment;

  Matrix4 get _effectiveTransform {
    if (origin == null && alignment == null) return transform;
    final Matrix4 result = Matrix4.identity();
    if (origin != null) result.translate(origin.x, origin.y);
    PdfPoint translation;
    if (alignment != null) {
      translation = alignment.alongSize(box.size);
      result.translate(translation.x, translation.y);
    }
    result.multiply(transform);
    if (alignment != null) result.translate(-translation.x, -translation.y);
    if (origin != null) result.translate(-origin.x, -origin.y);
    return result;
  }

  @override
  void paint(Context context) {
    assert(() {
      if (Document.debug) debugPaint(context);
      return true;
    }());

    if (child != null) {
      final mat = _effectiveTransform;
      context.canvas
        ..saveContext()
        ..setTransform(mat);
      child.paint(context);
      context.canvas.restoreContext();
    }
  }
}

/// A widget that aligns its child within itself and optionally sizes itself
/// based on the child's size.
class Align extends SingleChildWidget {
  Align(
      {this.alignment = Alignment.center,
      this.widthFactor,
      this.heightFactor,
      Widget child})
      : assert(alignment != null),
        assert(widthFactor == null || widthFactor >= 0.0),
        assert(heightFactor == null || heightFactor >= 0.0),
        super(child: child);

  /// How to align the child.
  final Alignment alignment;

  /// If non-null, sets its width to the child's width multiplied by this factor.
  final double widthFactor;

  /// If non-null, sets its height to the child's height multiplied by this factor.
  final double heightFactor;

  @override
  void layout(Context context, BoxConstraints constraints,
      {parentUsesSize = false}) {
    final bool shrinkWrapWidth =
        widthFactor != null || constraints.maxWidth == double.infinity;
    final bool shrinkWrapHeight =
        heightFactor != null || constraints.maxHeight == double.infinity;

    if (child != null) {
      child.layout(context, constraints.loosen(), parentUsesSize: true);

      box = constraints.constrainRect(
          width: shrinkWrapWidth
              ? child.box.w * (widthFactor ?? 1.0)
              : double.infinity,
          height: shrinkWrapHeight
              ? child.box.h * (heightFactor ?? 1.0)
              : double.infinity);

      child.box = alignment.inscribe(child.box.size, box);
    } else {
      box = constraints.constrainRect(
          width: shrinkWrapWidth ? 0.0 : double.infinity,
          height: shrinkWrapHeight ? 0.0 : double.infinity);
    }
  }
}

/// A widget that imposes additional constraints on its child.
class ConstrainedBox extends SingleChildWidget {
  ConstrainedBox({@required this.constraints, Widget child})
      : assert(constraints != null),
        super(child: child);

  /// The additional constraints to impose on the child.
  final BoxConstraints constraints;

  @override
  void layout(Context context, BoxConstraints constraints,
      {parentUsesSize = false}) {
    if (child != null) {
      child.layout(context, this.constraints.enforce(constraints),
          parentUsesSize: true);
      box = child.box;
    } else {
      box = PdfRect.fromPoints(PdfPoint.zero,
          this.constraints.enforce(constraints).constrain(PdfPoint.zero));
    }
  }
}

class Center extends Align {
  Center({double widthFactor, double heightFactor, Widget child})
      : super(
            widthFactor: widthFactor, heightFactor: heightFactor, child: child);
}

/// Scales and positions its child within itself according to [fit].
class FittedBox extends SingleChildWidget {
  FittedBox({
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    Widget child,
  })  : assert(fit != null),
        assert(alignment != null),
        super(child: child);

  /// How to inscribe the child into the space allocated during layout.
  final BoxFit fit;

  /// How to align the child within its parent's bounds.
  final Alignment alignment;

  @override
  void layout(Context context, BoxConstraints constraints,
      {parentUsesSize = false}) {
    PdfPoint size;
    if (child != null) {
      child.layout(context, const BoxConstraints(), parentUsesSize: true);
      size = constraints
          .constrainSizeAndAttemptToPreserveAspectRatio(child.box.size);
    } else {
      size = constraints.smallest;
    }
    box = PdfRect.fromPoints(PdfPoint.zero, size);
  }

  @override
  void paint(Context context) {
    if (child != null) {
      final PdfPoint childSize = child.box.size;
      final FittedSizes sizes = applyBoxFit(fit, childSize, box.size);
      final double scaleX = sizes.destination.x / sizes.source.x;
      final double scaleY = sizes.destination.y / sizes.source.y;
      final PdfRect sourceRect = alignment.inscribe(
          sizes.source, PdfRect.fromPoints(PdfPoint.zero, childSize));
      final PdfRect destinationRect =
          alignment.inscribe(sizes.destination, box);

      final mat =
          Matrix4.translationValues(destinationRect.x, destinationRect.y, 0.0)
            ..scale(scaleX, scaleY, 1.0)
            ..translate(-sourceRect.x, -sourceRect.y);

      context.canvas
        ..saveContext()
        ..drawRect(box.x, box.y, box.w, box.h)
        ..clipPath()
        ..setTransform(mat);
      child.paint(context);
      context.canvas.restoreContext();
    }
  }
}

typedef CustomPainter(PdfGraphics canvas, PdfPoint size);

class CustomPaint extends SingleChildWidget {
  CustomPaint(
      {this.painter,
      this.foregroundPainter,
      this.size = PdfPoint.zero,
      Widget child})
      : super(child: child);

  final CustomPainter painter;
  final CustomPainter foregroundPainter;
  final PdfPoint size;

  @override
  void paint(Context context) {
    assert(() {
      if (Document.debug) debugPaint(context);
      return true;
    }());

    if (child != null) {
      final mat = Matrix4.identity();
      mat.translate(box.x, box.y);
      context.canvas
        ..saveContext()
        ..setTransform(mat);
      painter(context.canvas, box.size);
      child.paint(context);
      foregroundPainter(context.canvas, box.size);
      context.canvas.restoreContext();
    }
  }
}

class ClipRect extends SingleChildWidget {
  ClipRect({Widget child}) : super(child: child);

  @protected
  void debugPaint(Context context) {
    context.canvas
      ..setStrokeColor(PdfColor.deepPurple)
      ..drawRect(box.x, box.y, box.w, box.h)
      ..strokePath();
  }

  @override
  void paint(Context context) {
    assert(() {
      if (Document.debug) debugPaint(context);
      return true;
    }());

    if (child != null) {
      final mat = Matrix4.identity();
      mat.translate(box.x, box.y);
      context.canvas
        ..saveContext()
        ..drawRect(box.x, box.y, box.w, box.h)
        ..clipPath()
        ..setTransform(mat);
      child.paint(context);
      context.canvas.restoreContext();
    }
  }
}

class ClipOval extends SingleChildWidget {
  ClipOval({Widget child}) : super(child: child);

  @protected
  void debugPaint(Context context) {
    final rx = box.w / 2.0;
    final ry = box.h / 2.0;

    context.canvas
      ..setStrokeColor(PdfColor.deepPurple)
      ..drawEllipse(box.x + rx, box.y + ry, rx, ry)
      ..strokePath();
  }

  @override
  void paint(Context context) {
    assert(() {
      if (Document.debug) debugPaint(context);
      return true;
    }());

    final rx = box.w / 2.0;
    final ry = box.h / 2.0;

    if (child != null) {
      final mat = Matrix4.identity();
      mat.translate(box.x, box.y);
      context.canvas
        ..saveContext()
        ..drawEllipse(box.x + rx, box.y + ry, rx, ry)
        ..clipPath()
        ..setTransform(mat);
      child.paint(context);
      context.canvas.restoreContext();
    }
  }
}
