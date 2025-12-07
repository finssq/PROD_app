import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../../models/project_post.dart';

class MyProjectsTab extends StatefulWidget {
  const MyProjectsTab({super.key});

  @override
  State<MyProjectsTab> createState() => _MyProjectsTabState();
}

class _MyProjectsTabState extends State<MyProjectsTab> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  DateTime? _selectedDeadline;
  String _selectedStatus = 'PUBLIC';

  final DateFormat _displayFormat = DateFormat('dd.MM.yyyy HH:mm');
  final DateFormat _apiFormat = DateFormat("yyyy-MM-ddTHH:mm:ss.SSS'Z'");

  bool _creating = false;
  List<ProjectPost> _myProjects = [];
  bool _loadingProjects = true;

  @override
  void initState() {
    super.initState();
    _fetchMyProjects();
  }

  Future<void> _fetchMyProjects() async {
    setState(() => _loadingProjects = true);
    try {
      final token = await AuthService().getAccessToken();
      final response = await http.post(
        Uri.parse('https://prod-app.ru/api/projects/search'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "name": null,
          "description": null,
          "deadline": null,
          "status": null,
          "tags": null,
          "onlyMyProjects": true,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List<dynamic>;
        setState(() {
          _myProjects = data.map((e) => ProjectPost.fromJson(e)).toList();
        });
      } else {
        debugPrint('Ошибка загрузки проектов: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Ошибка загрузки проектов: $e');
    } finally {
      setState(() => _loadingProjects = false);
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
      _selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _createProject() async {
    if (_nameController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Заполните обязательные поля')),
      );
      return;
    }

    setState(() => _creating = true);

    try {
      final token = await AuthService().getAccessToken();

      // Тело запроса согласно API
      final Map<String, dynamic> requestBody = {
        "name": _nameController.text.trim(),
        "description": _descriptionController.text.trim(),
        "status": _selectedStatus,
        "tags": _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      };

      // Добавляем дедлайн если выбран
      if (_selectedDeadline != null) {
        requestBody["deadline"] = _apiFormat.format(_selectedDeadline!);
      }

      debugPrint('Создание проекта. Тело запроса: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('https://prod-app.ru/api/projects'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      debugPrint('Статус ответа: ${response.statusCode}');
      debugPrint('Тело ответа: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final newProject = ProjectPost.fromJson(data);

          setState(() {
            _myProjects.insert(0, newProject);
          });

          _clearForm();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Проект "${newProject.name}" успешно создан!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          Navigator.pop(context);

        } catch (e) {
          debugPrint('Ошибка парсинга ответа: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Проект создан!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        String errorMessage = 'Ошибка создания проекта';
        try {
          final error = json.decode(response.body);
          errorMessage = error['message'] ?? error.toString();
        } catch (_) {
          errorMessage = 'Ошибка ${response.statusCode}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Ошибка создания проекта: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() => _creating = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _tagsController.clear();
    _selectedDeadline = null;
    _selectedStatus = 'PUBLIC';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A0F29),
      appBar: AppBar(
        title: const Text('Мои проекты'),
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
                    _showCreateProjectDialog();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurpleAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _creating
                      ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 20),
                      SizedBox(width: 8),
                      Text('Создать проект', style: TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loadingProjects
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : _myProjects.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open,
                    color: Colors.grey[400],
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'У вас пока нет проектов',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Создайте свой первый проект!',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _fetchMyProjects,
              backgroundColor: const Color(0xFF1A0F29),
              color: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _myProjects.length,
                itemBuilder: (context, index) {
                  final project = _myProjects[index];
                  return Card(
                    color: const Color(0xFF251635),
                    margin: const EdgeInsets.only(bottom: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  project.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Chip(
                                label: Text(
                                  project.status == 'PRIVATE' ? 'Приватный' : 'Публичный',
                                  style: const TextStyle(fontSize: 12, color: Colors.white),
                                ),
                                backgroundColor: project.status == 'PRIVATE'
                                    ? Colors.deepPurple[700]
                                    : Colors.green[700],
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            project.description,
                            style: const TextStyle(color: Colors.white70),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (project.tags.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Wrap(
                                spacing: 6,
                                children: project.tags.map((tag) => Chip(
                                  label: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 11, color: Colors.white),
                                  ),
                                  backgroundColor: Colors.deepPurple[300],
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                )).toList(),
                              ),
                            ),
                          if (project.deadline != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.grey[400], size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Дедлайн: ${DateFormat('dd.MM.yyyy').format(project.deadline!)}',
                                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF2A1B3D),
              title: const Text('Создать проект', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Название проекта*',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurpleAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Описание*',
                        labelStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurpleAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tagsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Теги (через запятую)',
                        labelStyle: TextStyle(color: Colors.white70),
                        hintText: 'flutter, dart, mobile',
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.deepPurpleAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Выбор статуса проекта
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          isExpanded: true,
                          dropdownColor: const Color.fromRGBO(42, 27, 61, 1),
                          icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          items: [
                            DropdownMenuItem<String>(
                              value: 'PUBLIC',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.public, color: Colors.green[400], size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Публичный'),
                                  ],
                                ),
                              ),
                            ),
                            DropdownMenuItem<String>(
                              value: 'PRIVATE',
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock, color: Colors.deepPurple[400], size: 20),
                                    const SizedBox(width: 8),
                                    const Text('Приватный'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: _creating ? null : (String? newValue) {
                            if (newValue != null) {
                              setStateDialog(() {
                                _selectedStatus = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Дата дедлайна
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[700]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDeadline == null
                                  ? 'Дедлайн: не выбрано'
                                  : 'Дедлайн: ${_displayFormat.format(_selectedDeadline!)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                          IconButton(
                            onPressed: _creating ? null : _pickDateTime,
                            icon: Icon(
                              Icons.calendar_today,
                              color: _creating ? Colors.grey[600] : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '* - обязательные поля',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
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
                  onPressed: _creating ? null : _createProject,
                  child: _creating
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text('Создать', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}