class Post {
  final String id;
  final String title;
  final String description;
  final List<String> images;
  final DateTime eventStartAt;
  final DateTime eventEndAt;
  final bool registrationRequired;
  final bool isLiked;
  final bool isSaved;
  final User user;

  Post({
    required this.id,
    required this.title,
    required this.description,
    required this.images,
    required this.eventStartAt,
    required this.eventEndAt,
    required this.registrationRequired,
    this.isLiked = false,
    this.isSaved = false,
    required this.user,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      images: (json['images'] as List<dynamic>).cast<String>(),
      eventStartAt: DateTime.parse(json['eventStartAt'] as String),
      eventEndAt: DateTime.parse(json['eventEndAt'] as String),
      registrationRequired: json['registrationRequired'] as bool,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Post copyWith({
    bool? isLiked,
    bool? isSaved,
  }) {
    return Post(
      id: id,
      title: title,
      description: description,
      images: images,
      eventStartAt: eventStartAt,
      eventEndAt: eventEndAt,
      registrationRequired: registrationRequired,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      user: user,
    );
  }
}

class User {
  final String id;
  final String firstName;
  final String lastName;
  final bool isVerified;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.isVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      isVerified: json['isVerified'] as bool,
    );
  }
}