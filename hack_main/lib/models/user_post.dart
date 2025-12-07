import 'package:teste/models/event_post.dart';

class UserPost {
  final String id;
  final String firstName;
  final String lastName;
  final String description;
  final String status;
  final List<String> skills;
  final List<String> interests;

  UserPost({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.description,
    required this.status,
    required this.skills,
    required this.interests,
  });

  factory UserPost.fromJson(Map<String, dynamic> json) {
    final List<dynamic> skillsList = (json['skills'] ?? []) as List;
    final List<dynamic> interestsList = (json['interests'] ?? []) as List;

    return UserPost(
      id: (json['id'] ?? '') as String, 
      
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      status: (json['status'] ?? 'UNKNOWN') as String,
      skills: skillsList.map((item) => item.toString()).toList(), 
      interests: interestsList.map((item) => item.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'description': description,
      'status': status,
      'skills': skills,
      'interests': interests,
    };
  }
  Organizer toOrganizer() {
    return Organizer(
      id: id,
      firstName: firstName,
      lastName: lastName,
      description: description,
      status: status,
      skills: skills,
      interests: interests,
    );
  }
}