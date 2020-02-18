import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';

class IBLabel extends Label {
  
  final String _text;
  final TextAlign _textAlign;
  final TextStyle _textStyle;
  final Size _size;
  final Offset _position;
  final double _scale;
  final double _rotation;
  final double _opacity; 
  final bool _userInteractionEnabled;

  IBLabel(
    this._text, 
    this._textAlign, 
    this._textStyle,
    this._size,
    this._position, 
    this._scale, 
    this._rotation, 
    this._opacity,
    this._userInteractionEnabled) : super(_text, textAlign: _textAlign, textStyle: _textStyle) {
    position = Offset(_position.dx, _position.dy);
    scale = _scale;
    rotation = _rotation;
    userInteractionEnabled = _userInteractionEnabled;
  }

  Offset range;

  @override
  bool isPointInside(Offset point) {
    Offset checkPoint = parent.convertPointFromNode(point, this);
    if (checkPoint.dx >= position.dx && checkPoint.dx <= _size.width + position.dx && checkPoint.dy <= _size.height + position.dy && checkPoint.dy >= position.dy)
      return true;

    return false;
  }

  @override handleEvent(SpriteBoxEvent event) {
    if (event.type == PointerDownEvent) {
      Offset currentPosition = parent.convertPointToNodeSpace(event.boxPosition);
      this.range = Offset(currentPosition.dx - position.dx, currentPosition.dy - position.dy);
    }
    if (event.type == PointerMoveEvent) {
      Offset currentPosition = parent.convertPointToNodeSpace(event.boxPosition);
      Offset newPosition = Offset(currentPosition.dx - range.dx, currentPosition.dy - range.dy);
      this.position = newPosition;
    }
    return true;
  }
}