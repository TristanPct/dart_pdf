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

class Context {
  final TextStyle textStyle;
  final PdfPage page;
  final PdfGraphics canvas;

  const Context(this.page, this.textStyle, this.canvas);
}

abstract class Widget {
  PdfRect box;
  int flex = 0;
  FlexFit fit = FlexFit.loose;

  Widget();

  @protected
  void layout(Context context, BoxConstraints constraints,
      {parentUsesSize = false});

  @protected
  void paint(Context context) {
    assert(() {
      if (Document.debug) debugPaint(context);
      return true;
    }());
  }

  @protected
  void debugPaint(Context context) {
    context.canvas
      ..setColor(PdfColor.purple)
      ..drawRect(box.x, box.y, box.w, box.h)
      ..strokePath();
  }
}

abstract class StatelessWidget extends Widget {
  Widget _widget;

  Widget get child {
    if (_widget == null) _widget = build();
    return _widget;
  }

  StatelessWidget() : super();

  @override
  void layout(Context context, BoxConstraints constraints,
      {parentUsesSize = false}) {
    if (child != null) {
      child.layout(context, constraints, parentUsesSize: parentUsesSize);
      box = child.box;
    } else {
      box = PdfRect.zero;
    }
  }

  @override
  void paint(Context context) {
    super.paint(context);

    if (child != null) {
      child.paint(context);
    }
  }

  @protected
  Widget build();
}

abstract class SingleChildWidget extends Widget {
  SingleChildWidget({this.child}) : super();

  final Widget child;

  @override
  void paint(Context context) {
    super.paint(context);

    if (child != null) {
      child.paint(context);
    }
  }
}

abstract class MultiChildWidget extends Widget {
  MultiChildWidget({this.children = const <Widget>[]}) : super();

  final List<Widget> children;
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
