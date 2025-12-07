import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../models/event_post.dart';
import '../../models/user_entity.dart';
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

  Future<void> joinEvent(int eventId) async {
    final token = await AuthService().getAccessToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/$eventId/participants'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Ошибка при вступлении в событие: ${response.statusCode}');
      }
    } catch (e) {
      log('Error joining event: $e');
      rethrow;
    }
  }

  Future<void> leaveEvent(int eventId) async {
    final token = await AuthService().getAccessToken();
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$eventId/participants'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Ошибка при выходе из события: ${response.statusCode}');
      }
    } catch (e) {
      log('Error leaving event: $e');
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
  UserEntity? currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _performSearch();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthService().getUserInfo();
      setState(() {
        currentUser = user;
        _isLoadingUser = false;
      });
    } catch (e) {
      log('Error loading current user: $e');
      setState(() {
        _isLoadingUser = false;
      });
    }
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
        builder: (_) => EventDetailsPage(
          eventId: event.id!,
          eventName: event.name,
          currentUser: currentUser,
        ),
      ),
    );
  }

  Color _getButtonColor() {
    if (_isLoadingUser) {
      return const Color.fromARGB(255, 201, 136, 212);
    }
    if (currentUser == null) {
      return Colors.grey;
    }
    return const Color.fromARGB(255, 201, 136, 212);
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
                // Показываем загрузку если еще грузится пользователь ИЛИ события
                if (_isLoadingUser || snapshot.connectionState == ConnectionState.waiting) {
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
                    final isParticipating = currentUser != null &&
                        event.participantIds.any((p) => p.id == currentUser!.id);

                    final buttonColor = _getButtonColor();

                    return Card(
                      color: const Color.fromARGB(255, 25, 14, 39),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(event.name, style: const TextStyle(color: Colors.white)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(event.description, style: const TextStyle(color: Colors.white70)),
                            const SizedBox(height: 4),
                            Text(
                              'Участников: ${event.participantIds.length}',
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                            if (isParticipating)
                              const Text(
                                'Вы участвуете',
                                style: TextStyle(color: Colors.green, fontSize: 12),
                              ),
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: buttonColor,
                            side: _isLoadingUser || currentUser != null
                                ? const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  )
                                : BorderSide.none,
                          ),
                          onPressed: (_isLoadingUser || currentUser == null)
                              ? null
                              : () async {
                                  try {
                                    if (isParticipating) {
                                      await EventService().leaveEvent(event.id!);
                                      setState(() {
                                        event.participantIds.removeWhere((p) => p.id == currentUser!.id);
                                      });
                                    } else {
                                      await EventService().joinEvent(event.id!);
                                      setState(() {
                                        event.participantIds.add(Organizer(
                                          id: currentUser!.id,
                                          firstName: currentUser!.firstName ?? '',
                                          lastName: currentUser!.lastName ?? '',
                                          description: '',
                                          status: '',
                                          skills: [],
                                          interests: [],
                                        ));
                                      });
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Ошибка: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          child: Text(
                            isParticipating ? 'Отменить' : 'Вступить',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
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
  final UserEntity? currentUser;

  const EventDetailsPage({
    required this.eventId,
    required this.eventName,
    this.currentUser,
  });

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  EventPost? _event;
  List<Organizer> _allParticipants = [];
  List<Organizer> _filteredParticipants = [];
  final TextEditingController _skillController = TextEditingController();
  bool _isLoading = true;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _fetchEventDetails();
  }

  Future<void> _fetchEventDetails() async {
    try {
      final event = await EventService().fetchEventById(widget.eventId);
      setState(() {
        _event = event;
        _allParticipants = event.participantIds;
        _filteredParticipants = _allParticipants;
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching event details: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки события: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        builder: (_) => OtherUserProfilePage(userId: participant.id),
      ),
    );
  }

  Future<void> _toggleParticipation() async {
    if (_event == null || widget.currentUser == null || _isJoining) return;

    setState(() {
      _isJoining = true;
    });

    final isParticipating = _event!.participantIds.any((p) => p.id == widget.currentUser!.id);

    try {
      if (isParticipating) {
        await EventService().leaveEvent(_event!.id!);
        setState(() {
          _event!.participantIds.removeWhere((p) => p.id == widget.currentUser!.id);
          _allParticipants = _event!.participantIds;
          _filterParticipants();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы вышли из события'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await EventService().joinEvent(_event!.id!);
        setState(() {
          _event!.participantIds.add(Organizer(
            id: widget.currentUser!.id,
            firstName: widget.currentUser!.firstName ?? '',
            lastName: widget.currentUser!.lastName ?? '',
            description: '',
            status: '',
            skills: [],
            interests: [],
          ));
          _allParticipants = _event!.participantIds;
          _filterParticipants();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Вы вступили в событие'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isJoining = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.eventName),
          backgroundColor: const Color.fromRGBO(26, 15, 41, 1),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_event == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.eventName),
          backgroundColor: const Color.fromRGBO(26, 15, 41, 1),
        ),
        body: const Center(
          child: Text('Ошибка загрузки события', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    final isParticipating = widget.currentUser != null &&
        _event!.participantIds.any((p) => p.id == widget.currentUser!.id);

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
              
              // Кнопка вступления/отмены
              if (widget.currentUser != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: ElevatedButton(
                    onPressed: _isJoining ? null : _toggleParticipation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isJoining
                          ? Colors.grey
                          : isParticipating 
                              ? Colors.red.shade800 
                              : const Color.fromARGB(255, 201, 136, 212),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isJoining
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isParticipating ? 'Отменить участие' : 'Вступить в событие',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),

              const Text('Фильтр участников по навыкам (через запятую):',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              const SizedBox(height: 10),
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
                    borderSide: const BorderSide(color: Color.fromRGBO(198, 125, 212, 1)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (_) => _filterParticipants(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Участники:',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(
                    '${_filteredParticipants.length}/${_allParticipants.length}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_filteredParticipants.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Нет участников, соответствующих фильтру',
                    style: TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ..._filteredParticipants.map(
                  (participant) => Card(
                    color: const Color.fromRGBO(26, 15, 41, 1),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        '${participant.firstName} ${participant.lastName}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (participant.skills.isNotEmpty)
                            Text(
                              'Навыки: ${participant.skills.join(", ")}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          if (participant.status.isNotEmpty)
                            Text(
                              'Статус: ${participant.status}',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
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