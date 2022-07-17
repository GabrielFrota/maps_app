import '../main.dart';

class Place {
  final String title;
  final String description;
  final double latitude;
  final double longitude;
  final int? userMapId;
  final int? id;
  Place(this.title, this.description, this.latitude,
      this.longitude, [this.userMapId, this.id]);

  Map<String, dynamic> toDbMap([int? userMapId]) {
    return {
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'id': id,
      'user_map_id': userMapId ?? this.userMapId
    };
  }

  static Place fromDbMap(Map<String, dynamic> map) {
    return Place(map['title'], map['description'], map['latitude'],
        map['longitude'], map['user_map_id'], map['id']);
  }
}

class PlaceService {
  static Future<List<Place>> findAll(int userMapId) async {
    final l = <Place>[];
    final places = await getDb().query(
        'place',
        where: 'user_map_id = ?',
        whereArgs: [userMapId]
    );
    for (var p in places)
      l.add(Place.fromDbMap(p));
    return l;
  }

  static Future<Place> insert(Place p) async {
    final id = await getDb().insert('place', p.toDbMap());
    return Place(p.title, p.description, p.latitude,
        p.longitude, p.userMapId, id);
  }

  static Future<int> delete(int id) async {
    return getDb().delete('place',
        where: 'id = ?', whereArgs: [id]);
  }
}