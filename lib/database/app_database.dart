import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._init();
  static Database? _database;

  AppDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('posts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE posts(
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        content TEXT NOT NULL,
        author TEXT NOT NULL,
        images TEXT,
        isLiked INTEGER NOT NULL DEFAULT 0,
        isSaved INTEGER NOT NULL DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE posts ADD COLUMN description TEXT');
      await db.execute('ALTER TABLE posts ADD COLUMN images TEXT');
      await db.execute('ALTER TABLE posts ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP');
    }
  }

  Future<List<Map<String, dynamic>>> searchPosts(String query) async {
    final db = await database;
    return await db.rawQuery(
      'SELECT * FROM posts WHERE title LIKE ? OR description LIKE ? OR content LIKE ?',
      ['%$query%', '%$query%', '%$query%']
    );
  }

  Future<int> updatePost(Map<String, dynamic> post) async {
    final db = await database;
    return await db.update(
      'posts',
      post,
      where: 'id = ?',
      whereArgs: [post['id']],
    );
  }

  Future<int> insertPost(Map<String, dynamic> post) async {
    final db = await database;
    return await db.insert('posts', post);
  }

  Future<int> deletePost(int id) async {
    final db = await database;
    return await db.delete(
      'posts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await database;
    db.close();
    _database = null;
  }
}