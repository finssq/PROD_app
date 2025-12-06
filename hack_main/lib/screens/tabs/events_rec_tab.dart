import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:teste/services/auth_service.dart';
import 'event_search_tab.dart';
import 'package:teste/models/event_post.dart';
import 'dart:developer' as developer;

class EventsRecTab extends StatefulWidget {
  const EventsRecTab({super.key});

  @override
  State<EventsRecTab> createState() => _EventsRecTabState();
}

class _EventsRecTabState extends State<EventsRecTab> {
  List<EventPost> events = [];
  bool loading = true;
  String currentUserId = "";
  Map<int, bool> userParticipation = {};

  @override
  void initState() {
    super.initState();
    _loadUserAndEvents();
  }

  Future<void> _loadUserAndEvents() async {
    setState(() => loading = true);
    try {
      final user = await AuthService().getUserInfo();
      currentUserId = user.id;

      final token = await AuthService().getAccessToken();
      final response = await http.get(
        Uri.parse("https://prod-app.ru/api/events/recommendations"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        final loadedEvents = decoded.map((e) => EventPost.fromJson(e)).toList();

        for (var e in loadedEvents) {
          userParticipation[e.id!] = e.participantIds.any((p) => p.id == currentUserId);
        }

        setState(() {
          events = loadedEvents;
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      developer.log("Ошибка загрузки пользователя или событий: $e");
      setState(() => loading = false);
    }
  }

  Future<void> _joinEvent(int eventId) async {
    try {
      final token = await AuthService().getAccessToken();
      await http.post(
        Uri.parse('https://prod-app.ru/api/events/$eventId/participants'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      await _refreshEvent(eventId);
    } catch (e) {
      developer.log('Ошибка при записи на мероприятие: $e');
    }
  }

  Future<void> _leaveEvent(int eventId) async {
    try {
      final token = await AuthService().getAccessToken();
      await http.delete(
        Uri.parse('https://prod-app.ru/api/events/$eventId/participants'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      await _refreshEvent(eventId);
    } catch (e) {
      developer.log('Ошибка при отмене участия: $e');
    }
  }

  Future<void> _refreshEvent(int eventId) async {
    try {
      final token = await AuthService().getAccessToken();
      final response = await http.get(
        Uri.parse('https://prod-app.ru/api/events/$eventId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final updatedEvent = EventPost.fromJson(jsonDecode(response.body));
        setState(() {
          final index = events.indexWhere((e) => e.id == eventId);
          if (index != -1) events[index] = updatedEvent;
          userParticipation[eventId] =
              updatedEvent.participantIds.any((p) => p.id == currentUserId);
        });
      }
    } catch (e) {
      developer.log('Ошибка обновления события: $e');
    }
  }

  void _openEventDetails(EventPost event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EventDetailsPageWrapper(
          event: event,
          currentUserId: currentUserId,
          joinEvent: _joinEvent,
          leaveEvent: _leaveEvent,
        ),
      ),
    );
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_outlined,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(event.place,
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
              onPressed: () {
                setState(() {
                  userParticipation[event.id!] = !participating;
                  if (participating) {
                    event.participantIds
                        .removeWhere((p) => p.id == currentUserId);
                  } else {
                    event.participantIds.add(Organizer(
                      id: currentUserId,
                      firstName: '',
                      lastName: '',
                      description: '',
                      status: '',
                      skills: [],
                      interests: [],
                    ));
                  }
                });

                if (participating) {
                  _leaveEvent(event.id!);
                } else {
                  _joinEvent(event.id!);
                }
              },
              child: Text(
                participating ? 'Отменить участие' : 'Записаться',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading || currentUserId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (events.isEmpty) {
      return const Center(
          child: Text(
        "Нет рекомендаций",
        style: TextStyle(color: Colors.white),
      ));
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (_, i) => _buildEventCard(events[i]),
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
    RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Организатор: ',
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy'),
          ),
          TextSpan(
            text: '${event.organizer.firstName} ${event.organizer.lastName}',
            style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontFamily: 'Gilroy'),
          ),
        ],
      ),
    ),
    if (event.organizer.description.isNotEmpty)
      Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'Описание организатора: ',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Gilroy'),
              ),
              TextSpan(
                text: event.organizer.description,
                style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Gilroy'),
              ),
            ],
          ),
        ),
      ),
    const SizedBox(height: 10),
    RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Место проведения: ',
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy'),
          ),
          TextSpan(
            text: event.place,
            style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontFamily: 'Gilroy'),
          ),
        ],
      ),
    ),
    const SizedBox(height: 10),
    RichText(
      text: TextSpan(
        children: [
          const TextSpan(
            text: 'Описание: ',
            style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontFamily: 'Gilroy'),
          ),
          TextSpan(
            text: event.description,
            style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w300,
                fontFamily: 'Gilroy'),
          ),
        ],
      ),
    ),
    const SizedBox(height: 20),
    if (event.tags.isNotEmpty)
      Wrap(
        spacing: 6,
        children: event.tags
            .map((t) => Chip(
                  label: Text(
                    t,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Gilroy'),
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
        participating ? 'Отменить участие' : 'Записаться',
        style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontFamily: 'Gilroy'),
      ),
    ),
  ],
),

      ),
    );
  }
}
