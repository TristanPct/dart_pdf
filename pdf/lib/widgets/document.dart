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

class Document {
  static var debug = false;

  final PdfDocument document;

  TextStyle _defaultTextStyle;

  TextStyle get defaultTextStyle {
    if (_defaultTextStyle == null) {
      _defaultTextStyle =
          TextStyle(color: PdfColor.black, font: PdfFont.helvetica(document));
    }
    return _defaultTextStyle;
  }

  Document({PdfPageMode pageMode = PdfPageMode.none, DeflateCallback deflate})
      : document = PdfDocument(pageMode: pageMode, deflate: deflate);

  void addPage(Page page) {
    final pdfPage = PdfPage(document, pageFormat: page.pageFormat);
    final canvas = pdfPage.getGraphics();
    final constraints = BoxConstraints(
        maxWidth: page.pageFormat.width, maxHeight: page.pageFormat.height);
    page.layout(constraints);
    final context = Context(pdfPage, canvas);
    page.paint(context);
  }
}

class Page extends StatelessWidget {
  final PdfPageFormat pageFormat;
  final Widget child;
  final EdgeInsets margin;

  Page(
      {this.pageFormat = PdfPageFormat.a4,
      this.child,
      this.margin = const EdgeInsets.all(10.0 * PdfPageFormat.mm)})
      : super();

  @override
  void debugPaint(Context context) {
    context.canvas
      ..setColor(PdfColor.lightGreen)
      ..moveTo(box.x, box.y)
      ..lineTo(box.r, box.y)
      ..lineTo(box.r, box.t)
      ..lineTo(box.x, box.t)
      ..moveTo(box.x + margin.left, box.y + margin.bottom)
      ..lineTo(box.x + margin.left, box.t - margin.top)
      ..lineTo(box.r - margin.right, box.t - margin.top)
      ..lineTo(box.r - margin.right, box.y + margin.bottom)
      ..fillPath();
  }

  @override
  void layout(BoxConstraints constraints, {parentUsesSize = false}) {
    box = PdfRect(0.0, 0.0, pageFormat.dimension.x, pageFormat.dimension.y);
    if (child != null) {
      final childConstraints = BoxConstraints(
          minWidth: constraints.minWidth,
          minHeight: constraints.minHeight,
          maxWidth: constraints.hasBoundedWidth
              ? constraints.maxWidth - margin.horizontal
              : margin.horizontal,
          maxHeight: constraints.hasBoundedHeight
              ? constraints.maxHeight - margin.vertical
              : margin.vertical);
      child.layout(childConstraints, parentUsesSize: parentUsesSize);
      child.box = PdfRect(margin.left, margin.top, child.box.w, child.box.h);
      // Move the child to the top left of the page
      child.box = PdfRect(box.x + child.box.x,
          box.y - child.box.y + box.h - child.box.h, child.box.w, child.box.h);
    }
  }

  @override
  Widget build() {
    return child;
  }
}