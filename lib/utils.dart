import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ibcore/CustomAction.dart';
import 'package:ibcore/IBKaraokeText.dart';
import 'package:ibcore/IBSound.dart';
import 'package:ibcore/IBVideo.dart';
import 'package:ibcore/PageObject.dart';
import 'package:ibcore/IBGallery.dart';
import 'package:ibcore/IBLabel.dart';
import 'package:ibcore/IBObject.dart';
import 'package:ibcore/IBPage.dart';
import 'package:ibcore/IBSprite.dart';
import 'package:ibcore/NodeBook.dart';
import 'package:flutter/painting.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spritewidget/spritewidget.dart';
import 'IBTranslation.dart';
import 'package:union/union.dart';
import 'constants.dart' as Constants;
import 'package:yaml/yaml.dart';
import 'package:ibcore/KaraokeTextObject.dart';

class Utils {
  static Map<String, YamlNode> loadMainData(YamlMap doc) {
    YamlMap backgroundProperty = doc['background'];
    YamlList appPage = doc['app-page'];

    return new Map<String, YamlNode>()
      ..addAll({'background': backgroundProperty, 'app-page': appPage});
  }

  static Future<Map<String, dynamic>> loadBackground(YamlMap doc) async {
    String imageLink = doc['image'];
    int color = doc['color'];
    if (imageLink != '') {
      ui.Image img = await decodeImage(imageLink);
      return new Map<String, dynamic>()..addAll({'image': img, 'color': color});
    }

    return new Map<String, dynamic>()..addAll({'image': '', 'color': color});
  }

  static Future<List<IBPage>> loadPage(YamlList doc) async {
    var completer = new Completer<List<IBPage>>();
    List<IBPage> pages = new List<IBPage>();
    for (var iPage in doc) {
      var page = iPage['page'];
      List<IBObject> objects = new List<IBObject>();
      if (page['objects'] != null) {
        for (var iObject in page['objects']) {
        var object = iObject['object'];
        switch (object['type']) {
          case Constants.TEXT:
            Map destructText = destructTextObject(object);
            objects.add(new IBObject(Constants.TEXT, destructText));
            break;
          case Constants.IMAGE:
            Map destructImage = await destructImageObject(object);
            objects.add(new IBObject(Constants.IMAGE, destructImage));
            break;
          case Constants.GALLERY:
            Map destructGallery = await destructGalleryObject(object);
            objects.add(new IBObject(Constants.GALLERY, destructGallery));
            break;
          case Constants.VIDEO:
            Map destructVideo = destructVideoObject(object);
            objects.add(new IBObject(Constants.VIDEO, destructVideo));
            break;
          case Constants.SOUND:
            Map destructSound = destructSoundObject(object);
            // Map destructKaraoke = destructKaraokeText(object['objectTexts']);
            objects.add(new IBObject(Constants.SOUND, destructSound));
            // objects.add(new IBObject(Constants.KARAOKE, destructKaraoke));
            break;
          default:
        }
      }
      }
      pages.add(new IBPage(page['index'], objects));
    }
    completer.complete(pages);
    return completer.future;
  }

  static Map<String, dynamic> destructTextObject(YamlMap object) {
    ui.Offset coordinates = new ui.Offset(object['coordinates']['x'].toDouble(),
        object['coordinates']['y'].toDouble());
    ui.Size size = new ui.Size(object['coordinates']['w'].toDouble(),
        object['coordinates']['h'].toDouble());
    String content = object['content'];
    TextStyle textStyle = new TextStyle(
      fontFamily: object['properties']['font'],
      height: 1,
      fontWeight: getFontWeight(object['properties']['fontWeight']),
      fontSize: object['properties']['fontSize'].toDouble() ?? 14.0,
      color: ui.Color(object['properties']['color'] ?? 0x00000000)
          .withOpacity(object['properties']['alpha']?.toDouble() ?? 1.0),
    );
    Map<String, dynamic> properties = new Map<String, dynamic>()
      ..addAll({
        'rotation': object['properties']['rotation']?.toDouble() ?? 0.0,
        'text-style': textStyle,
        'scale': object['properties']['scale']?.toDouble() ?? 1.0,
      });

    return new Map<String, dynamic>()
      ..addAll({
        'coordinates': coordinates,
        'size': size,
        'content': content,
        'properties': properties,
        'objectActions': object['objectActions'],
      });
  }

  static Future<Map<String, dynamic>> destructImageObject(
      YamlMap object) async {
    ui.Offset coordinates = new ui.Offset(object['coordinates']['x'].toDouble(),
        object['coordinates']['y'].toDouble());
    ui.Size size = new ui.Size(object['coordinates']['w'].toDouble(),
        object['coordinates']['h'].toDouble());

    Map<String, dynamic> properties = new Map<String, dynamic>()
      ..addAll({
        'rotation': object['properties']['rotation']?.toDouble() ?? 0.0,
        'scale': object['properties']['scale']?.toDouble() ?? 1.0,
        'alpha': object['properties']['alpha']?.toDouble() ?? 1.0,
      });

    ui.Image imageDecode = await decodeImage(object['originalImage']);

    Map<String, dynamic> image = new Map<String, dynamic>()
      ..addAll({'originalImage': imageDecode});

    return new Map<String, dynamic>()
      ..addAll({
        'coordinates': coordinates,
        'size': size,
        'originalImage': image['originalImage'],
        'properties': properties,
        'objectActions': object['objectActions'],
      });
  }

  static Future<Map<String, dynamic>> destructGalleryObject(
      YamlMap object) async {
    ui.Offset coordinates = new ui.Offset(object['coordinates']['x'].toDouble(),
        object['coordinates']['y'].toDouble());
    ui.Size size = new ui.Size(object['coordinates']['w'].toDouble(),
        object['coordinates']['h'].toDouble());

    var futures = List<Future<Uint8List>>();
    for (var img in object['imageList']) {
      futures.add(getUInt8Image(img['image']['originalImage']));
    }

    List<Uint8List> imageList = await Future.wait(futures);

    return new Map<String, dynamic>()
      ..addAll({
        'coordinates': coordinates,
        'size': size,
        'imageList': imageList,
      });
  }

  static Map<String, dynamic> destructVideoObject(YamlMap object) {
    ui.Offset coordinates = new ui.Offset(object['coordinates']['x'].toDouble(),
        object['coordinates']['y'].toDouble());
    ui.Size size = new ui.Size(object['coordinates']['w'].toDouble(),
        object['coordinates']['h'].toDouble());

    return new Map<String, dynamic>()
      ..addAll({
        'coordinates': coordinates,
        'size': size,
        'originalVideo': object['originalVideo'],
      });
  }

  static Map<String, dynamic> destructSoundObject(YamlMap object) {
    ui.Offset coordinatesSound = new ui.Offset(object['coordinates']['x'].toDouble(), 
        object['coordinates']['y'].toDouble());
    ui.Size sizeSound = new ui.Size(object['coordinates']['w'].toDouble(),
        object['coordinates']['h'].toDouble());

    ui.Offset coordinatesKaraoke = new ui.Offset(object['objectTexts']['coordinates']['x'].toDouble(), 
        object['objectTexts']['coordinates']['y'].toDouble());
    ui.Size sizeKaraoke = new ui.Size(object['objectTexts']['coordinates']['w'].toDouble(),
        object['objectTexts']['coordinates']['h'].toDouble());
    TextStyle textStyle = new TextStyle(
      fontFamily: object['objectTexts']['properties']['font'],
      height: 1,
      fontWeight: getFontWeight(object['objectTexts']['properties']['fontWeight']),
      fontSize: object['objectTexts']['properties']['fontSize'].toDouble() ?? 14.0,
      color: ui.Color(object['objectTexts']['properties']['color'] ?? 0x00000000)
          .withOpacity(object['objectTexts']['properties']['alpha']?.toDouble() ?? 1.0),
    );
    var listTexts = object['objectTexts']['listTexts'];
    List<String> contents = listTexts.map((text) {
      return new KaraokeText(content: text['content'], start: text['start'], end: text['end']);
    });
    
    return new Map<String, dynamic>()
      ..addAll({
        'coordinates': coordinatesSound,
        'size': sizeSound,
        'originalSound': object['originalSound'],
        'karaokeText': {
          'coordinates': coordinatesKaraoke,
          'size': sizeKaraoke,
          'colorSubtitle': object['colorSubtitle'],
          'textStyle': textStyle,
          'contents': contents
        } 
      });
  }

  static Map<String, dynamic> destructKaraokeText(YamlMap object, ) {
    ui.Offset coordinates = new ui.Offset(object['coordinates']['x'].toDouble(), 
        object['coordinates']['y'].toDouble());
    ui.Size size = new ui.Size(object['coordinates']['w'].toDouble(),
        object['coordinates']['h'].toDouble());
    TextStyle textStyle = new TextStyle(
      fontFamily: object['properties']['font'],
      height: 1,
      fontWeight: getFontWeight(object['properties']['fontWeight']),
      fontSize: object['properties']['fontSize'].toDouble() ?? 14.0,
      color: ui.Color(object['properties']['color'] ?? 0x00000000)
          .withOpacity(object['properties']['alpha']?.toDouble() ?? 1.0),
    );

    var listTexts = object['listTexts'];
    List<String> contents = listTexts.map((text) {
      return new KaraokeText(content: text['content'], start: text['start'], end: text['end']);
    });

    return new Map<String, dynamic>()
      ..addAll({
        'coordinates': coordinates,
        'size': size,
        'colorSubtitle': object['colorSubtitle'],
        'textStyle': textStyle,
        'contents': contents
      });
  }

  static List<PageObject> createObjectsInPage(IBPage page, NodeBook rootNode) {
    List<IBObject> objects = page.objects;
    List<PageObject> spriteObjects = new List<PageObject>();
    for (var iObject in objects) {
      Map object = iObject.object;
      switch (iObject.type) {
        case Constants.TEXT:
          IBLabel label = new IBLabel(
              object['content'],
              ui.TextAlign.center,
              object['properties']['text-style'],
              object['size'],
              object['coordinates'],
              object['properties']['scale'],
              object['properties']['rotation']);
          List autoActions = new List();
          if (object['objectActions'] != null) {
            for (var iObjAction in object['objectActions']) {
              var objAction = iObjAction['objectAction'];
              if (objAction['active']['type'] == 'auto') {
                autoActions.add(
                    YamlMap.wrap(Map()..addAll({'objectAction': objAction})));
              } else {
                switch (objAction['active']['type']) {
                  case 'onClick':
                    label.addActiveAction(
                        'onClick',
                        YamlMap.wrap(
                            Map()..addAll({'objectAction': objAction})));
                    break;
                  default:
                }
              }
            }
            List<CustomAction> autoActionsDestruct =
                createActions(YamlList.wrap(autoActions), label, object['size'] ,rootNode);
            for (var action in autoActionsDestruct) {
              label.motions.run(action.motion);
            }
          }
          spriteObjects.add(new PageObject('node', node: label));
          break;
        case Constants.IMAGE:
          IBSprite sprite = new IBSprite(
              object['originalImage'],
              object['size'],
              object['coordinates'],
              object['properties']['scale'],
              object['properties']['rotation'],
              object['properties']['alpha']);
          List autoActions = new List();
          if (object['objectActions'] != null) {
            for (var iObjAction in object['objectActions']) {
              var objAction = iObjAction['objectAction'];
              if (objAction['active']['type'] == 'auto') {
                autoActions.add(
                    YamlMap.wrap(Map()..addAll({'objectAction': objAction})));
              } else {
                switch (objAction['active']['type']) {
                  case 'onClick':
                    sprite.addActiveAction(
                        'onClick',
                        YamlMap.wrap(
                            Map()..addAll({'objectAction': objAction})));
                    break;
                  default:
                }
              }
            }
            List<CustomAction> autoActionsDestruct =
                createActions(YamlList.wrap(autoActions), sprite, object['size'], rootNode);
            for (var action in autoActionsDestruct) {
              sprite.motions.run(action.motion);
            }
          }
          spriteObjects.add(new PageObject('node', node: sprite));
          break;
        case Constants.GALLERY:
          Offset newCoordinates =
              rootNode.convertPointToBoxSpace(object['coordinates']);
          Offset sizeConverted = rootNode.convertPointToBoxSpace(
              Offset(object['size'].width, object['size'].height));
          Size newSize = new Size(sizeConverted.dx, sizeConverted.dy);
          IBGallery galleryWidget = new IBGallery(newSize, object['imageList']);
          Widget gallery = new Positioned(
              top: newCoordinates.dy,
              left: newCoordinates.dx,
              child: Container(
                height: newSize.height,
                width: newSize.width,
                child: galleryWidget,
              ));
          spriteObjects.add(new PageObject('widget', widget: gallery));
          break;
        case Constants.VIDEO:
          Offset newCoordinates =
              rootNode.convertPointToBoxSpace(object['coordinates']);
          Offset sizeConverted = rootNode.convertPointToBoxSpace(
              Offset(object['size'].width, object['size'].height));
          Size newSize = new Size(sizeConverted.dx, sizeConverted.dy);
          Union2<File, String> videoFile;
          if (Constants.ENV == 'DEVELOPMENT') {
            videoFile = object['originalVideo'].asSecond();
          } else {
            videoFile = File(object['originalVideo']).asFirst();
          }
          IBVideo videoWidget = new IBVideo(newSize, videoFile);
          Widget video = new Positioned(
              top: newCoordinates.dy,
              left: newCoordinates.dx,
              child: Container(
                height: newSize.height,
                width: newSize.width,
                child: videoWidget,
              ));
          spriteObjects.add(new PageObject('widget', widget: video));
          break;
        case Constants.SOUND:
          Offset newCoordinatesSound = 
              rootNode.convertPointToBoxSpace(object['coordinates']);
          Offset sizeConvertedSound = rootNode.convertPointToBoxSpace(
              Offset(object['size'].width, object['size'].height));
          Size newSizeSound = new Size(sizeConverted.dx, sizeConverted.dy);
          String soundFilePath = object['originalSound'];
          AudioPlayer _player = new AudioPlayer();
          _player.setFilePath(soundFilePath).catchError((error) {
            print(error);
          });
          Stream<Duration> myStream = _player.getPositionStream();
          IBSound soundWidget = new IBSound(newSizeSound, _player);
          Widget sound = new Positioned(
            top: newCoordinatesSound.dy,
            left: newCoordinatesSound.dx,
            child: Container(
              height: newSizeSound.height,
              width: newSizeSound.width,
              child: soundWidget,
            )
          );
          spriteObjects.add(new PageObject('widget', widget: sound));


          break;
        case Constants.KARAOKE:
          Offset newCoordinates = 
              rootNode.convertPointToBoxSpace(object['coordinates']);
          Offset sizeConverted = rootNode.convertPointToBoxSpace(
              Offset(object['size'].width, object['size'].height)
          );
          Size newSize = new Size(sizeConverted.dx, sizeConverted.dy);
          IBKaraokeText karaokeTextWidget = new IBKaraokeText(newSize);
          Widget karaokeText = new Positioned(
            top: newCoordinates.dy,
            left: newCoordinates.dx,
            child: Container(
              height: newSize.height,
              width: newSize.width,
              child: karaokeTextWidget
            )
          );
          spriteObjects.add(new PageObject('widget', widget: karaokeText));
          break;
        default:
      }
    }

    return spriteObjects;
  }

  static List<CustomAction> createActions(
      YamlList objectsAction, dynamic object, Size size, NodeBook rootNode) {
    Map<String, dynamic> oldProp = new Map<String, dynamic>()..addAll({ 
      'rotation': object.rotation,
      'opacity': object.runtimeType != IBLabel ? object.opacity: 1.0,
      'position': object.position,
      'scale': object.scale,
    });
    List<CustomAction> spriteActions = new List<CustomAction>();
    for (var iObjAction in objectsAction) {
      var objAction = iObjAction['objectAction'];
      oldProp.addAll({ 'motion': objAction['motion'], 'repeatTimes': objAction['repeatTimes'] ?? 0 });
      switch (objAction['type']) {
        case Constants.SEQUENCE_ACTION:
          List<Motion> motions = new List<Motion>();
          YamlList actions = objAction['actions'];
          for (var iAction in actions) {
            YamlMap action = iAction['action'];
            Motion motion;
            if (iAction == actions.last) {
              motion = createMotion(action, object, size, rootNode, oldProp: oldProp);
            } else {
              motion = createMotion(action, object, size, rootNode);
            }
            motions.add(motion);
          }
          Motion sequenceMotion = IBTranslation.createMotion(
              Constants.MOTION_SEQUENCE, 1.0,
              motions: motions);
          Motion finalMotion = createMotionWithBehaviour(sequenceMotion,
              objAction['motion'], objAction['repeatTimes'] ?? 0);
          spriteActions
              .add(new CustomAction(objAction['active']['type'], finalMotion));
          break;
        case Constants.SINGLE_ACTION:
          YamlMap action = objAction['actions'][0]['action'];
          Motion motion = createMotion(action, object, size, rootNode, oldProp: oldProp);
          Motion finalMotion = createMotionWithBehaviour(
              motion, objAction['motion'], objAction['repeatTimes'] ?? 0);
          spriteActions
              .add(new CustomAction(objAction['active']['type'], finalMotion));
          break;
        default:
      }
    }
    return spriteActions;
  }


  static Motion createMotion(YamlMap action, dynamic object, Size size, NodeBook rootNode, { Map<String, dynamic> oldProp }) {
    int repeatTime = 0;
    switch (action['type']) {
      case 'move':
        var parameters = action['parameters'];
        Offset startVal = Offset((parameters['startVal']['x'] + size.width / 2).toDouble(),
              (parameters['startVal']['y'] + size.height / 2).toDouble());
        Offset endVal = Offset((parameters['endVal']['x'] + size.width / 2).toDouble(),
              (parameters['endVal']['y'] + size.height / 2).toDouble());
        return IBTranslation.createMotion(
          parameters['name'],
          parameters['duration'].toDouble() ?? 1.0,
          setterFunction: (newPos) {
            object.position = newPos;
            if (oldProp != null && newPos == endVal) {
              switch (oldProp['motion']) {
                case Constants.REPEAT:
                  repeatTime++;
                  if (repeatTime == oldProp['repeatTimes']) return;
                  object.position = oldProp['position'];
                  object.rotation = oldProp['rotation'];
                  object.scale = oldProp['scale'];
                  if (object.runtimeType != IBLabel) {
                    object.opacity = oldProp['opacity'];
                  }
                  break;
                case Constants.REPEAT_FOREVER:
                  object.position = oldProp['position'];
                  object.rotation = oldProp['rotation'];
                  object.scale = oldProp['scale'];
                  if (object.runtimeType != IBLabel) {
                    object.opacity = oldProp['opacity'];
                  }
                  break;
                default:
              }
            }
          },
          startVal: startVal,
          endVal: endVal,
        );
      case 'rotate':
        var parameters = action['parameters'];
        double startVal = parameters['startVal'].toDouble();
        double endVal = parameters['endVal'].toDouble() * parameters['direction'];
        return IBTranslation.createMotion(Constants.MOTION_TWEEN_ROTATE,
            parameters['duration']?.toDouble() ?? 1.0,
            setterFunction: (angle) {
              object.rotation = angle;
              if (oldProp != null && angle == endVal) {
                switch (oldProp['motion']) {
                  case Constants.REPEAT:
                    repeatTime++;
                    if (repeatTime == oldProp['repeatTimes']) return;
                    object.position = oldProp['position'];
                    object.rotation = oldProp['rotation'];
                    object.scale = oldProp['scale'];
                    if (object.runtimeType != IBLabel) {
                      object.opacity = oldProp['opacity'];
                    }
                    break;
                  case Constants.REPEAT_FOREVER:
                    object.position = oldProp['position'];
                    object.rotation = oldProp['rotation'];
                    object.scale = oldProp['scale'];
                    if (object.runtimeType != IBLabel) {
                      object.opacity = oldProp['opacity'];
                    }
                    break;
                  default:
                }
              }
            },
            propStartVal: startVal,
            propEndVal: endVal);
      case 'scale':
        var parameters = action['parameters'];
        double startVal = parameters['startVal'].toDouble();
        double endVal = parameters['endVal'].toDouble();
        return IBTranslation.createMotion(Constants.MOTION_TWEEN_SCALE,
            parameters['duration']?.toDouble() ?? 1.0,
            setterFunction: (scale) {
              object.scale = scale;
              if (oldProp != null && scale == endVal) {
                switch (oldProp['motion']) {
                  case Constants.REPEAT:
                    repeatTime++;
                    if (repeatTime == oldProp['repeatTimes']) return;
                    object.position = oldProp['position'];
                    object.rotation = oldProp['rotation'];
                    object.scale = oldProp['scale'];
                    if (object.runtimeType != IBLabel) {
                      object.opacity = oldProp['opacity'];
                    }
                    break;
                  case Constants.REPEAT_FOREVER:
                    object.position = oldProp['position'];
                    object.rotation = oldProp['rotation'];
                    object.scale = oldProp['scale'];
                    if (object.runtimeType != IBLabel) {
                      object.opacity = oldProp['opacity'];
                    }
                    break;
                  default:
                }
              }
            },
            propStartVal: startVal,
            propEndVal: endVal);
        break;
      case 'opacity':
        var parameters = action['parameters'];
        double startVal = parameters['startVal'].toDouble();
        double endVal = parameters['endVal'].toDouble();
        return IBTranslation.createMotion(Constants.MOTION_TWEEN_OPACITY,
            parameters['duration']?.toDouble() ?? 1.0,
            setterFunction: (opacity) {
              object.opacity = opacity;
              if (oldProp != null && opacity == endVal) {
                switch (oldProp['motion']) {
                  case Constants.REPEAT:
                    repeatTime++;
                    if (repeatTime == oldProp['repeatTimes']) return;
                    object.position = oldProp['position'];
                    object.rotation = oldProp['rotation'];
                    object.scale = oldProp['scale'];
                    if (object.runtimeType != IBLabel) {
                      object.opacity = oldProp['opacity'];
                    }
                    break;
                  case Constants.REPEAT_FOREVER:
                    object.position = oldProp['position'];
                    object.rotation = oldProp['rotation'];
                    object.scale = oldProp['scale'];
                    if (object.runtimeType != IBLabel) {
                      object.opacity = oldProp['opacity'];
                    }
                    break;
                  default:
                }
              }
            },
            propStartVal: startVal,
            propEndVal: endVal);
        break;
      default:
    }

    return null;
  }

  static Motion createMotionWithBehaviour(
      Motion motion, String behaviour, int numRepeat) {
    switch (behaviour) {
      case Constants.NORMAL:
        return motion;
      case Constants.REPEAT:
        Motion repeatMotion = IBTranslation.createMotion(Constants.MOTION_TWEEN_REPEAT, 1.0,
            numRepeat: numRepeat - 1, motion: motion);
        return IBTranslation.createMotion(Constants.MOTION_SEQUENCE, 1.0, motions: List<Motion>()..add(repeatMotion)..add(motion));
      case Constants.REPEAT_FOREVER:
        return IBTranslation.createMotion(Constants.MOTION_REPEAT_FOREVER, 1.0,
            motion: motion);
      default:
    }

    return motion;
  }

  static FontWeight getFontWeight(int weight) {
    switch (weight) {
      case 400:
        return FontWeight.w400;
        break;
      default:
        return FontWeight.w400;
    }
  }

  static Future<ui.Image> decodeImage(String imgSrc) async {
    var completer = new Completer<ui.Image>();
    Uint8List data;
    if (Constants.ENV == 'DEVELOPMENT') {
      ByteData src = await rootBundle.load(imgSrc);
      data = Uint8List.view(src.buffer);
    } else {
      data = await File(imgSrc).readAsBytes();
    }
    ui.decodeImageFromList(data, (ui.Image img) {
      return completer.complete(img);
    });

    return completer.future;
  }

  static Future<Uint8List> getUInt8Image(String imgSrc) async {
    Uint8List data;
    if (Constants.ENV == 'DEVELOPMENT') {
      ByteData src = await rootBundle.load(imgSrc);
      data = Uint8List.view(src.buffer);
    } else {
      data = await File(imgSrc).readAsBytes();
    }
    return data;
  }
}
