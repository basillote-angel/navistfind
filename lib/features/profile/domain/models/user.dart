class User {
  final int id;
  final String name;
  final String email;
  final String? userType;
  final String? gradeLevel;
  final String? otherUserType;
  final String? contactNumber;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.userType,
    this.gradeLevel,
    this.otherUserType,
    this.contactNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      userType: json['user_type'],
      gradeLevel: json['grade_level'],
      otherUserType: json['other_user_type'],
      contactNumber: json['contact_number'],
    );
  }
}
