class Organizer {
  String id;
  String firstName;
  String lastName;
  String description;
  String status;
  List<String> skills;
  List<String> interests;

  Organizer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.description,
    required this.status,
    required this.skills,
    required this.interests,
  });

  factory Organizer.fromJson(Map<String, dynamic> json) => Organizer(
        id: json['id'],
        firstName: json['firstName'],
        lastName: json['lastName'],
        description: json['description'],
        status: json['status'],
        skills: List<String>.from(json['skills'] ?? []),
        interests: List<String>.from(json['interests'] ?? []),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'description': description,
        'status': status,
        'skills': skills,
        'interests': interests,
      };
}

class EventPost {
  int? id;
  Organizer organizer;
  String name;
  String description;
  DateTime? eventTime;
  String place;
  List<String> tags;
  List<Organizer> participantIds;

  EventPost({
    this.id,
    required this.organizer,
    required this.name,
    required this.description,
    required this.eventTime,
    required this.place,
    required this.tags,
    required this.participantIds,
  });

  factory EventPost.fromJson(Map<String, dynamic> json) => EventPost(
        id: json['id'],
        organizer: Organizer.fromJson(json['organizer']),
        name: json['name'],
        description: json['description'],
        eventTime: null,
        place: json['place'],
        tags: List<String>.from(json['tags'] ?? []),
        participantIds: (json['participantIds'] as List<dynamic>?)
                ?.map((e) => Organizer.fromJson(e))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizer': organizer.toJson(),
        'name': name,
        'description': description,
        'eventTime':null,
        'place': place,
        'tags': tags,
        'participantIds': participantIds.map((e) => e.toJson()).toList(),
      };
}
