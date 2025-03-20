import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:classic_sound/data/local_database.dart';
import 'package:classic_sound/data/music.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class PlayerWidget extends StatefulWidget {
  final AudioPlayer player;
  final Music music;
  final Database database;
  final Function(Music) callback;

  const PlayerWidget({
    required this.player,
    Key? key,
    required this.music,
    required this.database,
    required this.callback,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  PlayerState? _playerState;
  Duration? _duration;
  Duration? _position;
  late Music _currentMusic;

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;

  bool get _isPlaying => _playerState == PlayerState.playing;

  bool get _isPaused => _playerState == PlayerState.paused;

  String get _durationText => _duration?.toString().split('.').first ?? '';

  String get _positionText => _position?.toString().split('.').first ?? '';

  AudioPlayer get _player => widget.player;
  bool _repeatCheck = false;
  bool _shuffleCheck = false;

  @override
  void initState() {
    super.initState();
    _currentMusic = widget.music;
    _playerState = _player.state;
    _initStreams();
    _player.getDuration().then((value) => setState(() => _duration = value));
    _player.getCurrentPosition().then(
      (value) => setState(() => _position = value),
    );
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerStateChangeSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Slider(
          onChanged: (v) {
            final position = v * (_duration?.inMilliseconds ?? 0);
            _player.seek(Duration(milliseconds: position.round()));
          },
          value:
              (_position != null &&
                      _duration != null &&
                      _position!.inMilliseconds > 0 &&
                      _position!.inMilliseconds < _duration!.inMilliseconds)
                  ? _position!.inMilliseconds / _duration!.inMilliseconds
                  : 0.0,
        ),
        Text(
          _position != null
              ? '$_positionText / $_durationText'
              : _duration != null
              ? _durationText
              : '',
          style: const TextStyle(fontSize: 16.0),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: const Key('prev_button'),
              onPressed: _prev,
              iconSize: 44.0,
              icon: const Icon(Icons.skip_previous),
              color: color,
            ),
            IconButton(
              key: const Key('play_button'),
              onPressed: _isPlaying ? null : _play,
              iconSize: 44.0,
              icon: Icon(Icons.play_arrow),
              color: color,
            ),
            IconButton(
              key: const Key('pause_button'),
              onPressed: _isPlaying ? _pause : null,
              iconSize: 44.0,
              icon: Icon(Icons.pause),
              color: color,
            ),
            IconButton(
              key: const Key('stop_button'),
              onPressed: _isPlaying || _isPaused ? _stop : null,
              iconSize: 44.0,
              icon: Icon(Icons.stop),
              color: color,
            ),
            IconButton(
              key: const Key('next_button'),
              onPressed: _next,
              iconSize: 44.0,
              icon: const Icon(Icons.skip_next),
              color: color,
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              key: const Key('repeat_button'),
              onPressed: _repeat,
              iconSize: 44.0,
              icon: const Icon(Icons.repeat),
              color: _repeatCheck ? Colors.amberAccent : color,
            ),
            IconButton(
              key: const Key('shuffle_button'),
              onPressed: _shuffle,
              iconSize: 44.0,
              icon: const Icon(Icons.shuffle),
              color: _shuffleCheck ? Colors.amberAccent : color,
            ),
          ],
        ),
      ],
    );
  }

  void _initStreams() {
    _durationSubscription = _player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = _player.onPositionChanged.listen(
      (p) => setState(() => _position = p),
    );

    _playerCompleteSubscription = _player.onPlayerComplete.listen((event) {
      _onCompletion();
    });
    _playerStateChangeSubscription = _player.onPlayerStateChanged.listen((
      state,
    ) {
      setState(() => _playerState = state);
    });
  }

  Future<void> _onCompletion() async {
    if (_repeatCheck) {
      await _repeatPlay();
    } else {
      await _next();
      _player.resume();
    }
  }

  Future<void> _repeatPlay() async {
    final dir = await getApplicationDocumentsDirectory();
    setState(() {
      _position = const Duration(milliseconds: 1);
    });
    final path = '${dir.path}/${_currentMusic.name}';
    await _player.setSourceDeviceFile(path);
    await _player.resume();
  }

  Future<void> _play() async {
    final position = _position;
    if (position != null && position.inMilliseconds > 0) {
      await _player.seek(position);
    }
    await _player.resume();
    setState(() => _playerState = PlayerState.playing);
  }

  Future<void> _pause() async {
    await _player.pause();
    setState(() => _playerState = PlayerState.paused);
  }

  void _repeat() {
    setState(() => _repeatCheck = !_repeatCheck);
  }

  void _shuffle() {
    setState(() => _shuffleCheck = !_shuffleCheck);
  }

  Future<void> _prev() async {
    final musics = await MusicDatabase(widget.database).getMusic();
    for (int i = 0; i < musics.length; i++) {
      if (musics[i]['name'] == widget.music.name) {
        if (i != 0) {
          await _playMusic(musics[i - 1]);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('첫 번째 곡입니다.')));
        }
        break;
      }
    }
  }

  Future<void> _next() async {
    final musics = await MusicDatabase(widget.database).getMusic();
    if (_shuffleCheck) {
      musics.shuffle();
    }
    for (int i = 0; i < musics.length; i++) {
      if (musics[i]['name'] == widget.music.name) {
        if (i + 1 < musics.length) {
          await _playMusic(musics[i + 1]);
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('마지막 곡입니다.')));
        }
        break;
      }
    }
  }

  Future<void> _playMusic(Map<String, dynamic> musicData) async {
    final dir = await getApplicationDocumentsDirectory();
    _currentMusic = Music(
      musicData['name'],
      musicData['composer'],
      musicData['tag'],
      musicData['category'],
      musicData['size'],
      musicData['type'],
      musicData['downloadUrl'],
      musicData['imageDownloadUrl'],
    );
    final path = '${dir.path}/${_currentMusic.name}';
    await _player.setSourceDeviceFile(path);
    widget.callback(_currentMusic);
    await _player.resume();
  }

  Future<void> _stop() async {
    await _player.stop();
    setState(() {
      _playerState = PlayerState.stopped;
      _position = Duration.zero;
    });
  }
}
