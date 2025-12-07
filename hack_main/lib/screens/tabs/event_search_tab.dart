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
    final bodyJson =
        json.encode(tags != null && tags.isNotEmpty ? {'tags': tags} : {});

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
        throw Exception('Ошибка сервера: ${response.statusCode}');
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

  Future<void> joinEvent(int eventId) async {
    final token = await AuthService().getAccessToken();
    await http.post(
      Uri.parse('$baseUrl/$eventId/participants'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
  }

  Future<void> leaveEvent(int eventId) async {
    final token = await AuthService().getAccessToken();
    await http.delete(
      Uri.parse('$baseUrl/$eventId/participants'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
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
  String currentUserId = "";
  Map<int, bool> userParticipation = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _performSearch();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService().getUserInfo();
    setState(() {
      currentUserId = user.id;
    });
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

  void _openEventDetails(EventPost event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsPageWrapper(
          event: event,
          currentUserId: currentUserId,
          joinEvent: (id) => EventService().joinEvent(id),
          leaveEvent: (id) => EventService().leaveEvent(id),
        ),
      ),
    );
  }

  String formatEventTime(dynamic eventTime) {
    if (eventTime == null) return "Не указано";
    try {
      DateTime dt;
      if (eventTime is String) {
        dt = DateTime.parse(eventTime);
      } else if (eventTime is DateTime) {
        dt = eventTime;
      } else {
        return eventTime.toString();
      }
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return eventTime.toString();
    }
  }

  Widget _buildEventCard(EventPost event) {
    final participating = userParticipation[event.id!] ?? false;

    return Card(
      color: const Color(0xFF2A1B3D),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => _openEventDetails(event),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.name,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(event.description,
                      style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.place,
                          style: const TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.access_time, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(formatEventTime(event.eventTime),
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (event.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      children: event.tags
                          .map((t) => Chip(
                                label: Text(t),
                                backgroundColor: Colors.deepPurpleAccent,
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 71, 34, 100),
              ),
              onPressed: () async {
                setState(() {
                  userParticipation[event.id!] = !participating;
                });

                if (participating) {
                  await EventService().leaveEvent(event.id!);
                } else {
                  await EventService().joinEvent(event.id!);
                }
              },
              child: Text(
                participating ? 'Отменить участие' : 'Вступить',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
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
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          foregroundColor:
                              const Color.fromRGBO(195, 194, 230, 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child:
                            const Text('Искать', style: TextStyle(fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _clearSearch,
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              const Color.fromRGBO(195, 194, 230, 1),
                          side: const BorderSide(
                              color: Color.fromRGBO(195, 194, 230, 1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Очистить',
                            style: TextStyle(fontSize: 14)),
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
                      child: Text('События не найдены',
                          style: TextStyle(color: Colors.white)));
                }
                final events = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventCard(event);
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

class EventDetailsPageWrapper extends StatefulWidget {
  final EventPost event;
  final String currentUserId;
  final Future<void> Function(int) joinEvent;
  final Future<void> Function(int) leaveEvent;

  const EventDetailsPageWrapper({
    super.key,
    required this.event,
    required this.currentUserId,
    required this.joinEvent,
    required this.leaveEvent,
  });

  @override
  State<EventDetailsPageWrapper> createState() =>
      _EventDetailsPageWrapperState();
}

class _EventDetailsPageWrapperState extends State<EventDetailsPageWrapper> {
  late EventPost event;
  late bool participating;

  @override
  void initState() {
    super.initState();
    event = widget.event;
    participating =
        event.participantIds.any((p) => p.id == widget.currentUserId);
  }

  void _toggleParticipation() async {
    setState(() {
      participating = !participating;
      if (participating) {
        event.participantIds.add(Organizer(
          id: widget.currentUserId,
          firstName: '',
          lastName: '',
          description: '',
          status: '',
          skills: [],
          interests: [],
        ));
      } else {
        event.participantIds
            .removeWhere((p) => p.id == widget.currentUserId);
      }
    });

    if (participating) {
      await widget.joinEvent(event.id!);
    } else {
      await widget.leaveEvent(event.id!);
    }
  }

  String formatEventTime(dynamic eventTime) {
    if (eventTime == null) return "Не указано";
    try {
      DateTime dt;
      if (eventTime is String) {
        dt = DateTime.parse(eventTime);
      } else if (eventTime is DateTime) {
        dt = eventTime;
      } else {
        return eventTime.toString();
      }
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return eventTime.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.name),
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
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Описание: ${event.description}',
                style: const TextStyle(fontSize: 18, color: Colors.white)),
            const SizedBox(height: 10),
            Text('Место: ${event.place}',
                style: const TextStyle(color: Colors.white70)),
            Text('Время: ${formatEventTime(event.eventTime)}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            if (event.tags.isNotEmpty)
              Wrap(
                spacing: 6,
                children: event.tags
                    .map((t) => Chip(
                          label: Text(
                            t,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: Colors.deepPurpleAccent,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 71, 34, 100),
              ),
              onPressed: _toggleParticipation,
              child: Text(
                participating ? 'Отменить участие' : 'Вступить',
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
