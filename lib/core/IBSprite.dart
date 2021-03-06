import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:spritewidget/spritewidget.dart';
import 'package:yaml/yaml.dart';
import 'package:ibcore/interfaces/CustomAction.dart';
import 'package:ibcore/interfaces/ActiveAction.dart';
import 'package:ibcore/utils.dart';

class IBSprite extends Sprite {
  final ui.Image _image;
  final Size _size;
  final Size _rawSize;
  final Offset _position;
  final double _scale;
  final double _rotation;
  final double _alpha;

  bool firstPaint = false;

  IBSprite(this._image, this._size, this._rawSize, this._position, this._scale,
      this._rotation, this._alpha)
      : super.fromImage(_image) {
    size = _rawSize;
    scale = _scale;
    rotation = _rotation;
    position =
        Offset(_position.dx + _size.width / 2, _position.dy + _size.height / 2);
    opacity = _alpha;
    userInteractionEnabled = true;
  }

  // Offset range;
  List<ActiveAction> onClickActions = new List<ActiveAction>();

  void addActiveAction(String event, YamlMap motion) {
    Type type;
    switch (event) {
      case 'onClick':
        type = PointerDownEvent;
        onClickActions.add(new ActiveAction(type, motion));
        break;
      default:
    }
  }

  @override
  bool isPointInside(Offset point) {
    Offset checkPoint = parent.convertPointFromNode(point, this);
    if (checkPoint.dx >= position.dx - size.width / 2 &&
        checkPoint.dx <= size.width + position.dx - size.width / 2 &&
        checkPoint.dy <= size.height + position.dy - size.height / 2 &&
        checkPoint.dy >= position.dy - size.height / 2) return true;

    return false;
  }

  @override
  handleEvent(SpriteBoxEvent event) {
    if (event.type == PointerDownEvent) {
      // Offset currentPosition = parent.convertPointToNodeSpace(event.boxPosition);
      // this.range = Offset(currentPosition.dx - position.dx, currentPosition.dy - position.dy);
      for (var action in onClickActions) {
        List<CustomAction> motionDestruct = Utils.createActions(
            YamlList.wrap(List()..add(action.motion)), this, size, parent);
        motions.run(motionDestruct[0].motion);
      }
    }
    // if (event.type == PointerMoveEvent) {
    //   Offset currentPosition = parent.convertPointToNodeSpace(event.boxPosition);
    //   Offset newPosition = Offset(currentPosition.dx - range.dx, currentPosition.dy - range.dy);
    //   // if (newPosition.dx < 0 || newPosition.dx > 1024.0 - _size.width || newPosition.dy < 0 || newPosition.dy > 768.0 - _size.height)
    //   //   return false;
    //   this.position = newPosition;
    // }
    return true;
  }
}
