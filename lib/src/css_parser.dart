import 'dart:ui';

import 'package:csslib/visitor.dart' as css;
import 'package:csslib/parser.dart' as cssparser;
import 'package:flutter/material.dart';
import 'package:flutter_html/style.dart';

Style declarationsToStyle(Map<String, List<css.Expression>> declarations) {
  double px(css.Expression value) {
    // needs to support other units than pixels
    return (value as css.LiteralTerm).value.toDouble();
  }

  Style style = new Style();
  declarations.forEach((property, value) {
    switch (property) {
      case 'background-color':
        style.backgroundColor = ExpressionMapping.expressionToColor(value.first);
        break;
      case 'color':
        style.color = ExpressionMapping.expressionToColor(value.first);
        break;
      case 'text-align':
        style.textAlign = ExpressionMapping.expressionToTextAlign(value.first);
        break;
      case 'margin':
        if (value.length == 0) {
          style.padding = EdgeInsets.zero;
        } else if (value.length == 1) {
          style.padding = EdgeInsets.all(px(value.single));
        } else if (value.length == 2) {
          style.padding = EdgeInsets.symmetric(
            vertical: px(value[0]),
            horizontal: px(value[1]),
          );
        } else {
          style.padding = EdgeInsets.only(
            top: px(value[0]),
            right: px(value[1]),
            bottom: px(value[2]),
            left: value.length < 4 ? 0 : px(value[3]),
          );
        }
        break;
      case 'margin-left':
        style.padding = (style.padding ?? EdgeInsets.zero).copyWith(left: px(value.single));
        break;
      case 'margin-right':
        style.padding = (style.padding ?? EdgeInsets.zero).copyWith(right: px(value.single));
        break;
      case 'margin-top':
        style.padding = (style.padding ?? EdgeInsets.zero).copyWith(top: px(value.single));
        break;
      case 'margin-bottom':
        style.padding = (style.padding ?? EdgeInsets.zero).copyWith(bottom: px(value.single));
        break;
    }
  });
  return style;
}

Style inlineCSSToStyle(String inlineStyle) {
  final sheet = cssparser.parse("*{$inlineStyle}");
  final declarations = DeclarationVisitor().getDeclarations(sheet);
  return declarationsToStyle(declarations);
}

class DeclarationVisitor extends css.Visitor {
  Map<String, List<css.Expression>> _result;
  String _currentProperty;

  Map<String, List<css.Expression>> getDeclarations(css.StyleSheet sheet) {
    _result = new Map<String, List<css.Expression>>();
    sheet.visit(this);
    return _result;
  }

  @override
  void visitDeclaration(css.Declaration node) {
    _currentProperty = node.property;
    _result[_currentProperty] = new List<css.Expression>();
    node.expression.visit(this);
  }

  @override
  void visitExpressions(css.Expressions node) {
    node.expressions.forEach((expression) {
      _result[_currentProperty].add(expression);
    });
  }
}

//Mapping functions
class ExpressionMapping {
  static Color expressionToColor(css.Expression value) {
    if (value is css.HexColorTerm) {
      return stringToColor(value.text);
    } else if (value is css.FunctionTerm) {
      if (value.text == 'rgba') {
        return rgbOrRgbaToColor(value.span.text);
      } else if (value.text == 'rgb') {
        return rgbOrRgbaToColor(value.span.text);
      }
    }
    return null;
  }

  static Color stringToColor(String _text) {
    var text = _text.replaceFirst('#', '');
    if (text.length == 3)
      text = text.replaceAllMapped(
          RegExp(r"[a-f]|\d"), (match) => '${match.group(0)}${match.group(0)}');
    int color = int.parse(text, radix: 16);

    if (color <= 0xffffff) {
      return new Color(color).withAlpha(255);
    } else {
      return new Color(color);
    }
  }

  static Color rgbOrRgbaToColor(String text) {
    final rgbaText = text.replaceAll(')', '').replaceAll(' ', '');
    try {
      final rgbaValues =
          rgbaText.split(',').map((value) => double.parse(value)).toList();
      if (rgbaValues.length == 4) {
        return Color.fromRGBO(
          rgbaValues[0].toInt(),
          rgbaValues[1].toInt(),
          rgbaValues[2].toInt(),
          rgbaValues[3],
        );
      } else if (rgbaValues.length == 3) {
        return Color.fromRGBO(
          rgbaValues[0].toInt(),
          rgbaValues[1].toInt(),
          rgbaValues[2].toInt(),
          1.0,
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static TextAlign expressionToTextAlign(css.Expression value) {
    if (value is css.LiteralTerm) {
      switch(value.text) {
        case "center":
          return TextAlign.center;
        case "left":
          return TextAlign.left;
        case "right":
          return TextAlign.right;
        case "justify":
          return TextAlign.justify;
        case "end":
          return TextAlign.end;
        case "start":
          return TextAlign.start;
      }
    }
    return TextAlign.start;
  }
}
