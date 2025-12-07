import 'dart:convert';

import 'event_post.dart';

class ProjectPost {
  int? id;
  Organizer organizer;
  String name;
  String description;
  DateTime? deadline;
  String status;
  List<String> tags;
  List<Organizer> participants;

  ProjectPost({
    this.id,
    required this.organizer,
    required this.name,
    required this.description,
    this.deadline,
    required this.status,
    required this.tags,
    required this.participants,
  });
  factory ProjectPost.fromJson(Map<String, dynamic> json) => ProjectPost(
    id: json['id'],
    organizer: Organizer.fromJson(json['organizer']),
    name: json['name'] ?? '',
    description: json['description'] ?? '',
    deadline: json['deadline'] != null
        ? DateTime.tryParse(json['deadline'])
        : null,
    status: json['status'] ?? 'PUBLIC', // По умолчанию PUBLIC
    tags: List<String>.from(json['tags'] ?? []),
    participants: (json['participants'] as List<dynamic>?)
        ?.map((e) => Organizer.fromJson(e))
        .toList() ??
        [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizer': organizer.toJson(),
    'name': name,
    'description': description,
    'deadline': deadline != null ? deadline!.toUtc().toIso8601String() : null,
    'status': status,
    'tags': tags,
    'participants': participants.map((e) => e.toJson()).toList(),
  };
}

class ProjectParticipant {
  final String id;
  final String firstName;
  final String lastName;
  final List<String> skills;

  ProjectParticipant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.skills,
  });

  factory ProjectParticipant.fromJson(Map<String, dynamic> json) {
    return ProjectParticipant(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      skills: List<String>.from(json['skills'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'skills': skills,
    };
  }
}