import 'package:flutter/material.dart';
import 'package:maps_app/models/place.dart';

import '../main.dart';

class UserMap {
  final String title;
  final List<Place>? places;
  final int? id;
  UserMap(this.title, [this.places, this.id]);

  Map<String, dynamic> toDbMap() {
    return {
      'id' : id,
      'title': title,
    };
  }

  static UserMap fromDbMap(Map<String, dynamic> map,
      [List<Place>? places = null]) {
    return UserMap(map['title'], places, map['id']);
  }
}

class UserMapService with ChangeNotifier {
  UserMapService._();
  static UserMapService _instance = UserMapService._();
  static getInstanceForProvider() => _instance;

  static Future<List<UserMap>> findAll() async {
    final l = <UserMap>[];
    final users = await getDb().query('user_map');
    for (var u in users)
      l.add(UserMap.fromDbMap(u));
    return l;
  }

  static Future<UserMap> findById(int id) async {
    final places = await PlaceService.findAll(id);
    final userMap = await getDb().query('user_map',
        where: 'id = ?', whereArgs: [id]);
    return UserMap.fromDbMap(userMap.single, places);
  }

  static Future<UserMap> insert(UserMap u) async {
    final id = await getDb().insert('user_map', u.toDbMap());
    _instance.notifyListeners();
    return UserMap(u.title, [], id);
  }

  static Future<UserMap> update(UserMap u) async {
    await getDb().update('user_map', u.toDbMap(),
      where: 'id = ?', whereArgs: [u.id]);
    _instance.notifyListeners();
    return u;
  }

  static Future<int> delete(int id) async {
    var cnt = await getDb().delete('place', where: 'user_map_id = ?', whereArgs: [id]);
    cnt += await getDb().delete('user_map', where: 'id = ?', whereArgs: [id]);
    _instance.notifyListeners();
    return cnt;
  }
}
