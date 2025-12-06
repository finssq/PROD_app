import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../models/event_post.dart';
import 'package:teste/screens/other_profile_screen.dart';

class EventService {
  final String baseUrl = 'https://prod-app.ru/api/events';

  Future<List<EventPost>> fetchEvents({List<String>? tags}) async {
    final token = await AuthService().getAccessToken();

    final Map<String, dynamic> requestBody = {};
    if (tags != null && tags.isNotEmpty) requestBody['tags'] = tags;

    final bodyJson = json.encode(requestBody);
    log('API Request Body: $bodyJson', name: 'EventService');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/search'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: bodyJson,
      );

      log('Response Status: ${response.statusCode}', name: 'EventService');
      log('Response Body: ${response.body}', name: 'EventService');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);

        if (jsonResponse is List) {
          return jsonResponse.map((e) => EventPost.fromJson(e)).toList();
        }

        if (jsonResponse is Map) {
          return [EventPost.fromJson(Map<String, dynamic>.from(jsonResponse))];
        }

        return [];
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error fetching events: $e', name: 'EventService');
      rethrow;
    }
  }

  Future<EventPost> fetchEventById(int id) async {
    final token = await AuthService().getAccessToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return EventPost.fromJson(json.decode(response.body));
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching event details: $e');
      rethrow;
    }
  }
}

class EventSearchTab extends StatefulWidget {
  const EventSearchTab({super.key});

  @override
  State<EventSearchTab> createState() => _EventSearchTabState();
}

class _EventSearchTabState extends State<EventSearchTab> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<EventPost>>? _futureEvents;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  void _performSearch() {
    final tags = _searchController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() {
      _futureEvents = EventService().fetchEvents(tags: tags);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch();
  }

  void _openParticipantProfile(Organizer participant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParticipantProfilePage(participant: participant),
      ),
    );
  }

  void _openEventDetails(EventPost event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsPage(eventId: event.id!, eventName: event.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(37, 22, 53, 1),
            Color.fromRGBO(26, 15, 41, 1),
            Color.fromRGBO(8, 8, 17, 1),
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Поиск по тегам (через запятую)',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color.fromRGBO(26, 15, 41, 1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (_) => _performSearch(),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _performSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 98, 23, 133),
                          foregroundColor: const Color.fromRGBO(195, 194, 230, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Искать', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearSearch,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color.fromRGBO(195, 194, 230, 1),
                          side: const BorderSide(color: Color.fromRGBO(195, 194, 230, 1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Очистить', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: FutureBuilder<List<EventPost>>(
              future: _futureEvents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Ошибка: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('События не найдены', style: TextStyle(color: Colors.white)));
                }

                final events = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Card(
                      color: const Color.fromARGB(255, 25, 14, 39),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(event.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(event.description, style: const TextStyle(color: Colors.white70)),
                        onTap: () => _openEventDetails(event),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EventDetailsPage extends StatefulWidget {
  final int eventId;
  final String eventName;

  const EventDetailsPage({required this.eventId, required this.eventName});

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  EventPost? _event;
  List<Organizer> _allParticipants = [];
  List<Organizer> _filteredParticipants = [];
  final TextEditingController _skillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  Future<void> _fetchEventDetails() async {
    final event = await EventService().fetchEventById(widget.eventId);
    setState(() {
      _event = event;
      _allParticipants = event.participantIds;
      _filteredParticipants = _allParticipants;
    });
  }

  void _filterParticipants() {
    final skillsInput = _skillController.text
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .where((s) => s.isNotEmpty)
        .toList();

    setState(() {
      if (skillsInput.isEmpty) {
        _filteredParticipants = _allParticipants;
      } else {
        _filteredParticipants = _allParticipants.where((p) {
          return skillsInput.every((skill) =>
              p.skills.any((s) => s.toLowerCase().contains(skill)));
        }).toList();
      }
    });
  }

  void _openParticipantProfile(Organizer participant) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParticipantProfilePage(participant: participant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.eventName),
          backgroundColor: const Color.fromRGBO(26, 15, 41, 1),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_event!.name),
        backgroundColor: const Color.fromRGBO(26, 15, 41, 1),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(37, 22, 53, 1),
              Color.fromRGBO(26, 15, 41, 1),
              Color.fromRGBO(8, 8, 17, 1),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text('Описание: ${_event!.description}',
                  style: const TextStyle(fontSize: 18, color: Colors.white)),
              const SizedBox(height: 10),
              Text('Место: ${_event!.place}', style: const TextStyle(color: Colors.white70)),
              Text('Время: ${_event!.eventTime ?? "Не указано"}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 10),
              const Text('Теги:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _event!.tags
                    .map((tag) => Chip(
                          label: Text(tag, style: const TextStyle(color: Colors.white)),
                          backgroundColor: const Color.fromARGB(255, 50, 6, 75),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),
              const Text('Фильтр участников по навыкам (через запятую):',
              
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 20),
              TextField(
                controller: _skillController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Введите навыки через запятую',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: const Color.fromRGBO(26, 15, 41, 1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(50),
                    borderSide: const BorderSide(color: Color.fromRGBO(198, 125, 212, 1)) ,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (_) => _filterParticipants(),
              ),
              const SizedBox(height: 10),
              const Text('Участники:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              ..._filteredParticipants.map(
                (participant) => Card(
                  color: const Color.fromRGBO(26, 15, 41, 1),
                  child: ListTile(
                    title: Text('${participant.firstName} ${participant.lastName}',
                        style: const TextStyle(color: Colors.white)),
                    subtitle: Text('Навыки: ${participant.skills.join(", ")}',
                        style: const TextStyle(color: Colors.white70)),
                    onTap: () => _openParticipantProfile(participant),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParticipantProfilePage extends StatelessWidget {
  final Organizer participant;

  const ParticipantProfilePage({required this.participant});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${participant.firstName} ${participant.lastName}'),
        backgroundColor: const Color.fromRGBO(26, 15, 41, 1),
      ),
      body: OtherUserProfilePage(userId: participant.id),
    );
  }
}
