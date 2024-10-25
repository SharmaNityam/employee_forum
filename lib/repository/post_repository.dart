import 'package:sqflite/sqflite.dart';
import '../services/api_service.dart';
import '../models/post.dart';

class PostRepository {
  final ApiService apiService;
  final Database database;

  PostRepository({
    required this.apiService,
    required this.database,
  });

  Future<List<Post>> getPosts({int page = 1}) async {
    try {
      final response = await apiService.getPosts(page: page);
      final List<dynamic> postsJson = response['events'] as List<dynamic>;
      return postsJson.map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      print('Error in repository: $e');
      rethrow;
    }
  }

  Future<List<Post>> searchPosts({
    required String query,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await apiService.searchPosts(
        query: query,
        page: page,
        limit: limit,
      );
      return (response['data'] as List)
          .map((json) => Post.fromJson(json))
          .toList();
    } catch (e) {
      return _searchLocalPosts(query);
    }
  }

  Future<void> _storePosts(List<Post> posts) async {
    final batch = database.batch();
    
    for (final post in posts) {
      batch.insert(
        'posts',
        {
          'id': post.id,
          'title': post.title,
          'description': post.description,
          'images': post.images.join(','),
          'eventStartAt': post.eventStartAt.toIso8601String(),
          'eventEndAt': post.eventEndAt.toIso8601String(),
          'registrationRequired': post.registrationRequired ? 1 : 0,
          'isLiked': post.isLiked ? 1 : 0,
          'isSaved': post.isSaved ? 1 : 0,
          'userId': post.user.id,
          'userFirstName': post.user.firstName,
          'userLastName': post.user.lastName,
          'userIsVerified': post.user.isVerified ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<List<Post>> _getLocalPosts() async {
    final maps = await database.query('posts');
    return maps.map((map) => Post(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      images: (map['images'] as String).split(','),
      eventStartAt: DateTime.parse(map['eventStartAt'] as String),
      eventEndAt: DateTime.parse(map['eventEndAt'] as String),
      registrationRequired: (map['registrationRequired'] as int) == 1,
      isLiked: (map['isLiked'] as int) == 1,
      isSaved: (map['isSaved'] as int) == 1,
      user: User(
        id: map['userId'] as String,
        firstName: map['userFirstName'] as String,
        lastName: map['userLastName'] as String,
        isVerified: (map['userIsVerified'] as int) == 1,
      ),
    )).toList();
  }

  Future<List<Post>> _searchLocalPosts(String query) async {
    final maps = await database.query(
      'posts',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return maps.map((map) => Post(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      images: (map['images'] as String).split(','),
      eventStartAt: DateTime.parse(map['eventStartAt'] as String),
      eventEndAt: DateTime.parse(map['eventEndAt'] as String),
      registrationRequired: (map['registrationRequired'] as int) == 1,
      isLiked: (map['isLiked'] as int) == 1,
      isSaved: (map['isSaved'] as int) == 1,
      user: User(
        id: map['userId'] as String,
        firstName: map['userFirstName'] as String,
        lastName: map['userLastName'] as String,
        isVerified: (map['userIsVerified'] as int) == 1,
      ),
    )).toList();
  }

  Future<void> updateLocalPost(Post post) async {
    await database.update(
      'posts',
      {
        'id': post.id,
        'title': post.title,
        'description': post.description,
        'images': post.images.join(','),
        'eventStartAt': post.eventStartAt.toIso8601String(),
        'eventEndAt': post.eventEndAt.toIso8601String(),
        'registrationRequired': post.registrationRequired ? 1 : 0,
        'isLiked': post.isLiked ? 1 : 0,
        'isSaved': post.isSaved ? 1 : 0,
        'userId': post.user.id,
        'userFirstName': post.user.firstName,
        'userLastName': post.user.lastName,
        'userIsVerified': post.user.isVerified ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [post.id],
    );
  }
}