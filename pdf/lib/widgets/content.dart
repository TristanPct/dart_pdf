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

class Header extends StatelessWidget {
  final String text;
  final Widget child;
  final int level;

  Header({this.level = 1, this.text, this.child})
      : assert(level >= 0 && level <= 5);

  @override
  Widget build(Context context) {
    BoxDecoration _decoration;
    EdgeInsets _margin;
    EdgeInsets _padding;
    double _textSize;
    switch (level) {
      case 0:
        _margin = EdgeInsets.only(bottom: 5.0 * PdfPageFormat.mm);
        _padding = EdgeInsets.only(bottom: 1.0 * PdfPageFormat.mm);
        _decoration =
            BoxDecoration(border: BoxBorder(bottom: true, width: 1.0));
        _textSize = 2.0;
        break;
      case 1:
        _margin = EdgeInsets.only(
            top: 3.0 * PdfPageFormat.mm, bottom: 5.0 * PdfPageFormat.mm);
        _decoration =
            BoxDecoration(border: BoxBorder(bottom: true, width: 0.2));
        _textSize = 1.5;
        break;
      case 2:
        _margin = EdgeInsets.only(
            top: 2.0 * PdfPageFormat.mm, bottom: 4.0 * PdfPageFormat.mm);
        _textSize = 1.4;
        break;
      case 3:
        _margin = EdgeInsets.only(
            top: 2.0 * PdfPageFormat.mm, bottom: 4.0 * PdfPageFormat.mm);
        _textSize = 1.3;
        break;
      case 4:
        _margin = EdgeInsets.only(
            top: 2.0 * PdfPageFormat.mm, bottom: 4.0 * PdfPageFormat.mm);
        _textSize = 1.2;
        break;
      case 5:
        _margin = EdgeInsets.only(
            top: 2.0 * PdfPageFormat.mm, bottom: 4.0 * PdfPageFormat.mm);
        _textSize = 1.1;
        break;
    }
    return Container(
      alignment: Alignment.topLeft,
      margin: _margin,
      padding: _padding,
      decoration: _decoration,
      child: child ?? Text(text, textScaleFactor: _textSize),
    );
  }
}

class Paragraph extends StatelessWidget {
  final String text;

  Paragraph({this.text});

  @override
  Widget build(Context context) {
    return Container(
      margin: EdgeInsets.only(bottom: 5.0 * PdfPageFormat.mm),
      child: Text(
        text,
        textAlign: TextAlign.justify,
        style: context.textStyle.copyWith(lineSpacing: 5.0),
      ),
    );
  }
}

class Bullet extends StatelessWidget {
  final String text;
  static final shape =
      "m 7.4368644,5.0000001 c 0,1.345843 -1.0910213,2.4368643 -2.4368644,2.4368643 -1.3458431,0 -2.4368644,-1.0910213 -2.4368644,-2.4368643 0,-1.3458431 1.0910213,-2.4368644 2.4368644,-2.4368644 1.3458431,0 2.4368644,1.0910213 2.4368644,2.4368644 z";

  Bullet({this.text});

  @override
  Widget build(Context context) {
    return Container(
        margin: EdgeInsets.only(bottom: 2.0 * PdfPageFormat.mm),
        child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(
                    left: 5.0 * PdfPageFormat.mm,
                    right: 1.0 * PdfPageFormat.mm),
                child: Shape(shape,
                    fillColor: PdfColor.black, width: 10.0, height: 10.0),
              ),
              Expanded(
                  child: Text(text,
                      style: context.textStyle.copyWith(lineSpacing: 5.0)))
            ]));
  }
}
