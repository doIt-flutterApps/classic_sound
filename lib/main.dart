import 'package:classic_sound/admin/upload_page.dart';
import 'package:classic_sound/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:classic_sound/view/intro/intro_page.dart';
import 'package:sqflite/sqflite.dart';
import 'data/local_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final Database database = await MusicDatabase.initDatabase();
  runApp(MyApp(database: database,));

}

class MyApp extends StatelessWidget {
  final Database database;
  const MyApp({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // home: UploadPage(),
      home: IntroPage(database: database,),
    );
  }
}
