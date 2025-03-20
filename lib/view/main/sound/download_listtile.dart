import 'package:classic_sound/data/music.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:io';
import 'package:classic_sound/view/main/sound/sound_detail_page.dart';
import 'package:sqflite/sqflite.dart';
import '../../../data/local_database.dart';

class DownloadListTile extends StatefulWidget {
  final Music music;
  final Database database;
  const DownloadListTile({super.key, required this.music, required this.database,});

  @override
  _DownloadListTileState createState() => _DownloadListTileState();
}

class _DownloadListTileState extends State<DownloadListTile> {
  double progress = 0.0; // 내려받기 진행률
  bool isDownloading = false; // 내려받는 중인지 여부
  bool isPlaying = false;
  IconData leadingIcon = Icons.music_note;
  final player = AudioPlayer();
  AudioCache audioCache = AudioCache();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Card(
        child: ListTile(
          leading: Icon(leadingIcon),
          title: Text(widget.music.name),
          subtitle: Text('${widget.music.composer} / ${widget.music.tag}'),
          trailing:
              isDownloading
                  ? CircularProgressIndicator(value: progress, strokeWidth: 5.0)
                  : const Icon(Icons.arrow_circle_right_sharp),
          tileColor: Colors.grey[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
      ),
      onTap: () async {
        var url = widget.music.downloadUrl;
        var dir = await getApplicationDocumentsDirectory();
        var path = '${dir.path}/${widget.music.name}';
        // File 객체 생성하기
        var file = File(path);
        // 파일이 있는지 확인하기
        bool exists = await file.exists();
        if (exists) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) {
                return SoundDetailPage(music: widget.music);
              },
            ),
          );
        } else {
          // 파일이 없다면 내려받기 시작하기
          setState(() {
            isDownloading = true;
            MusicDatabase(widget.database).insertMusic(widget.music);
          });
          await Dio().download(
            url,
            path,
            onReceiveProgress: (received, total) {
              if (total != -1) {
                setState(() {
                  progress = received / total;
                });
              }
            },
          );
          setState(() {
            isDownloading = false;
          });
        }
      },
    );
  }
}
