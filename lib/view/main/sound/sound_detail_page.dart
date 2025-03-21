import 'package:audioplayers/audioplayers.dart';
import 'package:classic_sound/data/music.dart';
import 'package:classic_sound/view/main/sound/player_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SoundDetailPage extends StatefulWidget {
  final Music music;
  final Database database;

  const SoundDetailPage({
    super.key,
    required this.music,
    required this.database,
  });

  @override
  State<StatefulWidget> createState() {
    return _SoundDetailPage();
  }
}

class _SoundDetailPage extends State<SoundDetailPage> {
  AudioPlayer player = AudioPlayer();
  late Music currentMusic;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    currentMusic = widget.music;
    initPlayer();
  }

  void initPlayer() async {
    var dir = await getApplicationDocumentsDirectory();
    var path = '${dir.path}/${widget.music.name}';
    player.setSourceDeviceFile(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 10),
              SizedBox(
                height: 50,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ClipOval(
                child: Image.network(
                  widget.music.imageDownloadUrl,
                  height: 200, // 렌더링 넘치므로 일부러 높이 조정함
                  errorBuilder: (context, obj, err) {
                    return Icon(Icons.music_note_outlined, size: 200);
                  },
                ),
              ),
              SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.music.name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(widget.music.composer),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () async {
                      DocumentReference musicRef = firestore
                          .collection('musics')
                          .doc(widget.music.name);
                      await musicRef
                          .update({'likes': FieldValue.increment(1)})
                          .then((value) {
                            const snackBar = SnackBar(
                              content: Text('좋아요 클릭했어요!'),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
                          });
                    },
                    icon: Icon(Icons.thumb_up),
                    padding: EdgeInsets.all(5),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                    ),
                  ),
                  SizedBox(width: 20),
                  IconButton(
                    onPressed: () async {
                      DocumentReference musicRef = firestore
                          .collection('music')
                          .doc(widget.music.name);
                      await musicRef
                          .update({'likes': FieldValue.increment(-1)})
                          .then((value) {
                            const snackBar = SnackBar(
                              content: Text('싫어요 클릭했어요!'),
                            );
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(snackBar);
                          });
                    },
                    icon: Icon(Icons.thumb_down),
                    padding: EdgeInsets.all(5),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.amberAccent,
                    ),
                  ),
                ],
              ),
              // 음악 재생 위젯
              PlayerWidget(
                player: player,
                music: currentMusic,
                database: widget.database,
                callback: (music) {
                  setState(() {
                    // currentMusic = music as Music; // 필요 없는 cast 경고 뜸
                    currentMusic = music;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
