import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class IBSound extends StatefulWidget {
  final AudioPlayer _player;
  final Size size;

  IBSound(this.size, this._player);

  @override
  _IBSoundState createState() => _IBSoundState(size, _player);
}

class _IBSoundState extends State<IBSound> {
  AudioPlayer _player;
  final Size size;

  _IBSoundState(this.size, this._player);

  @override
  void initState() {
    super.initState();
    AudioPlayer.setIosCategory(IosCategory.playback);
  }

  static Widget _buildSoundButton(var state, Size size, var buffering, AudioPlayer _player) {
    if (state == AudioPlaybackState.connecting || buffering == true) 
      return Container(
        margin: EdgeInsets.all(8.0),
        width: size.width,
        height: size.height,
        child: CircularProgressIndicator(),
      );
    else if (state == AudioPlaybackState.playing) 
      return Container(
        child: IconButton(
          icon: Icon(Icons.pause),
          iconSize: size.width,
          onPressed: _player.pause,
        ),
      );
    else
      return Container(
        child: IconButton(
          icon: Icon(Icons.play_arrow),
          iconSize: size.width,
          onPressed: _player.play,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.width,
      height: size.height,
      child: StreamBuilder<FullAudioPlaybackState>(
        stream: _player.fullPlaybackStateStream,
        builder: (context, snapshot) {
          final fullState = snapshot.data;
          final state = fullState?.state;
          final buffering = fullState?.buffering;
          return Container(
            child: _buildSoundButton(state, size, buffering, _player)
          );
        },
      ),
    );
  }
} 