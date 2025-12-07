import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../models/event_post.dart';

class MyEventsTab extends StatefulWidget {
  const MyEventsTab({super.key});

  @override
  State<MyEventsTab> createState() => _MyEventsTabState();
}

class _MyEventsTabState extends State<MyEventsTab> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime? _selectedDateTime;

  final DateFormat _displayFormat = DateFormat('dd.MM.yyyy HH:mm');
  final DateFormat _apiFormat = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'");

  bool _creating = false;
  List<EventPost> _myEvents = [];
  bool _loadingEvents = true;

  @override
  void initState() {
    super.initState();
    _fetchMyEvents();
  }

  Future<void> _fetchMyEvents() async {
    setState(() => _loadingEvents = true);
    try {
      final token = await AuthService().getAccessToken();
      final response = await http.post(
        Uri.parse('https://prod-app.ru/api/events/search'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "name": null,
          "description": null,
          "eventTime": null,
          "place": null,
          "tags": null,
          "onlyMyEvents": true,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        setState(() {
          _myEvents = data.map((e) => EventPost.fromJson(e)).toList();
        });
      } else {
        debugPrint('Ошибка загрузки мероприятий: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Ошибка загрузки мероприятий: $e');
    } finally {
      setState(() => _loadingEvents = false);
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.deepPurple,
            onPrimary: Colors.white,
            surface: Color(0xFF1A0F29),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Colors.deepPurple,
            onPrimary: Colors.white,
            surface: Color(0xFF1A0F29),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null) return;

    setState(() {
      _selectedDateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _createEvent() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _placeController.text.isEmpty ||
        _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните все поля')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final token = await AuthService().getAccessToken();
      final response = await http.post(
        Uri.parse('https://prod-app.ru/api/events'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "name": _nameController.text,
          "description": _descriptionController.text,
          "eventTime": _apiFormat.format(_selectedDateTime!),
          "place": _placeController.text,
          "tags": _tagsController.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final newEvent = EventPost.fromJson(data);
        setState(() {
          _myEvents.insert(0, newEvent);
        });
        _clearForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Мероприятие создано')),
        );
      } else {
        debugPrint('Ошибка создания: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка создания мероприятия')),
        );
      }
    } catch (e) {
      debugPrint('Ошибка создания мероприятия: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка создания мероприятия')),
      );
    } finally {
      setState(() => _creating = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _placeController.clear();
    _tagsController.clear();
    _selectedDateTime = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F29),
      appBar: AppBar(
        title: const Text('Мои мероприятия'),
        backgroundColor: const Color(0xFF2A1B3D),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ElevatedButton(
                  onPressed: _creating ? null : () {
                    _showCreateEventDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Создать мероприятие', style:  TextStyle(fontWeight: FontWeight.w600),),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingEvents
                ? const Center(child: CircularProgressIndicator())
                : _myEvents.isEmpty
                    ? const Center(child: Text('Мероприятия не найдены', style: TextStyle(color: Colors.white)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _myEvents.length,
                        itemBuilder: (context, index) {
                          final event = _myEvents[index];
                          return Card(
                            color: const Color(0xFF251635),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ListTile(
                              title: Text(event.name, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                event.description,
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A1B3D),
          title: const Text('Создать мероприятие', style: TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Название',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _placeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Место',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tagsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Теги (через запятую)',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedDateTime == null
                            ? 'Дата и время: не выбрано'
                            : 'Дата и время: ${_displayFormat.format(_selectedDateTime!)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    IconButton(
                      onPressed: _pickDateTime,
                      icon: const Icon(Icons.calendar_today, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _creating ? null : () {
                Navigator.pop(context);
              },
              child: const Text('Отмена', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurpleAccent,
              ),
              onPressed: _creating ? null : () async {
                Navigator.pop(context);
                await _createEvent();
              },
              child: const Text('Создать', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),),
            ),
          ],
        );
      },
    );
  }
}
