class ProfileEntity {
  final String id;
  final String username;
  final String number;
  final DateTime createdOn;
  final String email;

  ProfileEntity({
    required this.id,
    required this.username,
    required this.number,
    required this.createdOn,
    required this.email,
  });

  factory ProfileEntity.fromJson(Map<String, dynamic> json) {
    // Handle MongoDB ObjectId
    String id = '';
    if (json['_id'] is String) {
      id = json['_id'];
    } else if (json['_id'] is Map && json['_id']['\$oid'] != null) {
      id = json['_id']['\$oid'];
    }

    // Handle MongoDB Date
    DateTime createdOn = DateTime.fromMillisecondsSinceEpoch(0);
    if (json['created_on'] is String) {
      createdOn = DateTime.parse(json['created_on']);
    } else if (json['created_on'] is Map && json['created_on']['\$date'] != null) {
      createdOn = DateTime.parse(json['created_on']['\$date']);
    }

    return ProfileEntity(
      id: id,
      username: json['username'] ?? '',
      number: json['number'] ?? '',
      createdOn: createdOn,
      email: json['email'] ?? '',
    );
  }
} 