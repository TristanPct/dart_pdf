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

class ClipRRect extends SingleChildWidget {
  ClipRRect({
    Widget child,
    this.horizontalRadius,
    this.verticalRadius,
  }) : super(child: child);

  final double horizontalRadius;
  final double verticalRadius;

  @protected
  void debugPaint(Context context) {
    context.canvas
      ..setStrokeColor(PdfColor.deepPurple)
      ..drawRRect(box.x, box.y, box.w, box.h, horizontalRadius, verticalRadius)
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
        ..drawRRect(
            box.x, box.y, box.w, box.h, horizontalRadius, verticalRadius)
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