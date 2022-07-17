import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'models/place.dart';
import 'models/user_map.dart';
import 'pages/list_maps_page.dart';

class MapsApp extends StatelessWidget {
  const MapsApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maps app',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.lightBlue,
      ),
      home: ListMapsPage(),
    );
  }
}

late final Database _db;

Database getDb() {
  return _db;
}

void main() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
  }
  WidgetsFlutterBinding.ensureInitialized();
  _db = await openDatabase(
      join(await getDatabasesPath(), 'maps_app_database.db'),
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, _) async {
        await db.execute('CREATE TABLE user_map(id INTEGER PRIMARY KEY, title TEXT NOT NULL)');
        await db.execute('''
          CREATE TABLE place(id INTEGER PRIMARY KEY, title TEXT NOT NULL,
              description TEXT NOT NULL, latitude REAL NOT NULL, longitude REAL NOT NULL, 
              user_map_id INTEGER NOT NULL,
              FOREIGN KEY (user_map_id) REFERENCES user_map (id))
          ''');
        for (var u in _sampleData) {
          int uid = await db.insert('user_map', u.toDbMap());
          for (var p in u.places!) {
            await db.insert('place', p.toDbMap(uid));
          }
        }
      },
      version: 1
  );
  runApp(const MapsApp());
}

final List<UserMap> _sampleData = [
  UserMap("Memories from University", [
    Place("Branner Hall", "Best dorm at Stanford", 37.426, -122.163),
    Place("Gates CS building", "Many long nights in this basement", 37.430, -122.173),
    Place("Pinkberry", "First date with my wife", 37.444, -122.170)
  ]),
  UserMap("January vacation planning!", [
    Place("Tokyo", "Overnight layover", 35.67, 139.65),
    Place("Ranchi", "Family visit + wedding!", 23.34, 85.31),
    Place("Singapore", "Inspired by \"Crazy Rich Asians\"", 1.35, 103.82)
  ]),
  UserMap("Singapore travel itinerary", [
    Place("Gardens by the Bay", "Amazing urban nature park", 1.282, 103.864),
    Place("Jurong Bird Park", "Family-friendly park with many varieties of birds", 1.319, 103.706),
    Place("Sentosa", "Island resort with panoramic views", 1.249, 103.830),
    Place("Botanic Gardens", "One of the world's greatest tropical gardens", 1.3138, 103.8159)
  ]),
  UserMap("My favorite places in the Midwest", [
    Place("Chicago", "Urban center of the midwest, the \"Windy City\"", 41.878, -87.630),
    Place("Rochester, Michigan", "The best of Detroit suburbia", 42.681, -83.134),
    Place("Mackinaw City", "The entrance into the Upper Peninsula", 45.777, -84.727),
    Place("Michigan State University", "Home to the Spartans", 42.701, -84.482),
    Place("University of Michigan", "Home to the Wolverines", 42.278, -83.738)
  ]),
  UserMap("Restaurants to try", [
    Place("Champ's Diner", "Retro diner in Brooklyn", 40.709, -73.941),
    Place("Althea", "Chicago upscale dining with an amazing view", 41.895, -87.625),
    Place("Shizen", "Elegant sushi in San Francisco", 37.768, -122.422),
    Place("Citizen Eatery", "Bright cafe in Austin with a pink rabbit", 30.322, -97.739),
    Place("Kati Thai", "Authentic Portland Thai food, served with love", 45.505, -122.635)
  ])
];