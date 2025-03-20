import 'package:classic_sound/data/constant.dart';
import 'package:classic_sound/data/music.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:classic_sound/view/main/sound/download_listtile.dart';
import 'package:sqflite/sqflite.dart';

class MainPage extends StatefulWidget {
  final Database database;
  const MainPage({super.key, required this.database});

  @override
  State<StatefulWidget> createState() {
    return _MainPageState();
  }
}

class _MainPageState extends State<MainPage> {
  late List<DocumentSnapshot> documentList = List<DocumentSnapshot>.empty(
    growable: true,
  );
  List<Music> musicList = List<Music>.empty(growable: true);
  Dio dio = Dio();

  @override
  void initState() {
    super.initState();
    getMusicList();
    dio.options.connectTimeout = const Duration(seconds: 5); // 5초
    dio.options.receiveTimeout = const Duration(seconds: 3); // 3초
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(Constant.APP_NAME),
        actions: [IconButton(onPressed: () async {}, icon: Icon(Icons.search))],
      ),
      body: ListView.builder(
        itemBuilder: (context, value) {
          Music music = Music.fromStoreData(documentList[value]);
          musicList.add(music);
          return DownloadListTile(music: music, database: widget.database,);
        },
        itemCount: documentList.length,
      ),
    );
  }

  getMusicList() {
    final aptRef = FirebaseFirestore.instance.collection('files');
    aptRef.get().asStream().listen((event) {
      setState(() {
        documentList = event.docs;
      });
    });
  }
}
