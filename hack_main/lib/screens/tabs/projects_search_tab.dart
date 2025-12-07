import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/project_post.dart';
import 'package:teste/screens/other_profile_screen.dart';

class ProjectService {
  final String baseUrl = 'https://prod-app.ru/api/projects';

  Future<List<ProjectPost>> fetchProjects({List<String>? tags}) async {
    final token = await AuthService().getAccessToken();
    if (token == null) {
      throw Exception('Токен авторизации не найден');
    }

    // Создаем тело запроса
    final Map<String, dynamic> requestBody = {
      "name": null,
      "description": null,
      "deadline": null,
      "tags": tags != null && tags.isNotEmpty ? tags : null,
      "onlyMyProjects": false,
    };

    // Удаляем null значения
    requestBody.removeWhere((key, value) => value == null);

    final bodyJson = json.encode(requestBody);

    log('Поиск проектов. Тело запроса: $bodyJson', name: 'ProjectService');

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

      log('Статус ответа: ${response.statusCode}', name: 'ProjectService');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);

        if (jsonResponse is List) {
          return jsonResponse.map((e) => ProjectPost.fromJson(e)).toList();
        }

        if (jsonResponse is Map) {
          return [ProjectPost.fromJson(Map<String, dynamic>.from(jsonResponse))];
        }

        return [];
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error fetching projects: $e', name: 'ProjectService');
      rethrow;
    }
  }

  Future<ProjectPost> fetchProjectById(int id) async {
    final token = await AuthService().getAccessToken();
    if (token == null) {
      throw Exception('Токен авторизации не найден');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return ProjectPost.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        throw Exception('Проект не найден');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } catch (e) {
      log('Error fetching project details: $e');
      rethrow;
    }
  }
}

class ProjectsSearchTab extends StatefulWidget {
  const ProjectsSearchTab({super.key});

  @override
  State<ProjectsSearchTab> createState() => _ProjectsSearchTabState();
}

class _ProjectsSearchTabState extends State<ProjectsSearchTab> {
  final TextEditingController _searchController = TextEditingController();
  Future<List<ProjectPost>>? _futureProjects;
  String? _errorMessage;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _performSearch();
  }

  void _performSearch() {
    setState(() {
      _errorMessage = null;
      _isSearching = true;

      final tags = _searchController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      _futureProjects = ProjectService().fetchProjects(
        tags: tags.isEmpty ? null : tags,
      ).catchError((error) {
        setState(() {
          _errorMessage = error.toString();
        });
        return <ProjectPost>[];
      }).whenComplete(() {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      });
    });
  }

  void _clearSearch() {
    _searchController.clear();
    _performSearch();
  }

  void _openProjectDetails(ProjectPost project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProjectDetailsPage(projectId: project.id!, projectName: project.name),
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
            Color.fromRGBO(37, 22, 53, 1), // Темно-фиолетовый
            Color.fromRGBO(26, 15, 41, 1), // Еще темнее фиолетовый
            Color.fromRGBO(8, 8, 17, 1),   // Почти черный с фиолетовым оттенком
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Поле поиска по тегам
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Поиск по тегам проектов (через запятую)',
                    hintStyle: const TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: const Color.fromRGBO(42, 27, 61, 1), // Фиолетовый фон
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Color.fromRGBO(98, 23, 133, 1)), // Фиолетовая граница
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Color.fromRGBO(98, 23, 133, 1)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                      borderSide: const BorderSide(color: Color.fromRGBO(156, 39, 176, 1)), // Ярко-фиолетовый при фокусе
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    suffixIcon: _isSearching
                        ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(195, 194, 230, 1)),
                        ),
                      ),
                    )
                        : IconButton(
                      icon: const Icon(Icons.search, color: Color.fromRGBO(195, 194, 230, 1)),
                      onPressed: _performSearch,
                    ),
                  ),
                  onChanged: (_) => _performSearch(),
                ),
                const SizedBox(height: 16),

                // Кнопки поиска
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSearching ? null : _performSearch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 98, 23, 133), // Фиолетовый
                          foregroundColor: const Color.fromRGBO(195, 194, 230, 1), // Светло-фиолетовый текст
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: _isSearching
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(195, 194, 230, 1)),
                          ),
                        )
                            : const Text('Искать', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSearching ? null : _clearSearch,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color.fromRGBO(195, 194, 230, 1),
                          side: const BorderSide(color: Color.fromRGBO(195, 194, 230, 1)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Очистить', style: TextStyle(fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Сообщение об ошибке
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(40, 244, 67, 54), // Прозрачный красный
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color.fromARGB(255, 183, 28, 28)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Color.fromARGB(255, 244, 67, 54), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color.fromARGB(255, 244, 67, 54), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Результаты поиска
          Expanded(
            child: FutureBuilder<List<ProjectPost>>(
              future: _futureProjects,
              builder: (context, snapshot) {
                // Загрузка
                if (snapshot.connectionState == ConnectionState.waiting || _isSearching) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(195, 194, 230, 1)),
                    ),
                  );
                }

                // Ошибка
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Color.fromARGB(255, 244, 67, 54), size: 50),
                          const SizedBox(height: 16),
                          const Text(
                            'Ошибка загрузки',
                            style: TextStyle(color: Color.fromRGBO(195, 194, 230, 1), fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Нет данных
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          color: const Color.fromRGBO(195, 194, 230, 1).withOpacity(0.5),
                          size: 50,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Проекты не найдены',
                          style: TextStyle(color: Color.fromRGBO(195, 194, 230, 1), fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchController.text.isEmpty
                              ? 'Создайте первый проект или подождите пока кто-то создаст'
                              : 'Попробуйте другие теги для поиска',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                // Данные есть
                final projects = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return GestureDetector(
                      onTap: () => _openProjectDetails(project),
                      child: Card(
                        color: const Color.fromARGB(255, 42, 27, 61), // Фиолетовый фон карточки
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: Color.fromARGB(255, 98, 23, 133), // Фиолетовая граница
                            width: 1,
                          ),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Заголовок и статус
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
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      project.status == 'PRIVATE' ? 'Приватный' : 'Публичный',
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                    backgroundColor: project.status == 'PRIVATE'
                                        ? const Color.fromARGB(255, 68, 13, 47) // Фиолетовый
                                        : const Color.fromARGB(255, 77, 12, 71), // Зеленый
                                  ),
                                ],
                              ),

                              // Описание
                              const SizedBox(height: 8),
                              Text(
                                project.description,
                                style: const TextStyle(color: Color.fromRGBO(195, 194, 230, 1)), // Светло-фиолетовый
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),

                              // Теги
                              if (project.tags.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: project.tags.map((tag) => Chip(
                                    label: Text(
                                      tag,
                                      style: const TextStyle(fontSize: 11, color: Colors.white),
                                    ),
                                    backgroundColor: const Color.fromARGB(255, 98, 23, 133), // Фиолетовый
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  )).toList(),
                                ),
                              ],

                              // Дедлайн
                              if (project.deadline != null) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, 
                                         color: const Color.fromRGBO(195, 194, 230, 1).withOpacity(0.7), 
                                         size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Дедлайн: ${DateFormat('dd.MM.yyyy').format(project.deadline!)}',
                                      style: const TextStyle(color: Color.fromRGBO(195, 194, 230, 1), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],

                              // Подсказка для нажатия
                              const SizedBox(height: 12),
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Нажмите для деталей',
                                    style: TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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

class ProjectDetailsPage extends StatefulWidget {
  final int projectId;
  final String projectName;

  const ProjectDetailsPage({required this.projectId, required this.projectName});

  @override
  State<ProjectDetailsPage> createState() => _ProjectDetailsPageState();
}

class _ProjectDetailsPageState extends State<ProjectDetailsPage> {
  ProjectPost? _project;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProjectDetails();
  }

  Future<void> _fetchProjectDetails() async {
    try {
      final project = await ProjectService().fetchProjectById(widget.projectId);
      setState(() {
        _project = project;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(8, 8, 17, 1), // Темный фон
      appBar: AppBar(
        title: Text(_project?.name ?? widget.projectName,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromRGBO(26, 15, 41, 1), // Темно-фиолетовый
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color.fromRGBO(195, 194, 230, 1)),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, 
                  color: Color.fromARGB(255, 244, 67, 54), size: 50),
              const SizedBox(height: 16),
              const Text(
                'Ошибка загрузки проекта',
                style: TextStyle(color: Color.fromRGBO(195, 194, 230, 1), fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProjectDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 98, 23, 133),
                  foregroundColor: const Color.fromRGBO(195, 194, 230, 1),
                ),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
      )
          : Container(
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
            // Статус
            Row(
              children: [
                Chip(
                  label: Text(
                    _project!.status == 'PRIVATE' ? 'Приватный проект' : 'Публичный проект',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _project!.status == 'PRIVATE'
                      ? const Color.fromARGB(255, 98, 23, 133) // Фиолетовый
                      : const Color.fromARGB(255, 76, 175, 80), // Зеленый
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Описание
            const Text(
              'Описание',
              style: TextStyle(
                color: Color.fromRGBO(195, 194, 230, 1), // Светло-фиолетовый
                fontSize: 16,
                fontWeight: FontWeight.w600
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(42, 27, 61, 1), // Фиолетовый фон
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _project!.description,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),

            // Дедлайн
            if (_project!.deadline != null) ...[
              const Text(
                'Дедлайн',
                style: TextStyle(
                  color: Color.fromRGBO(195, 194, 230, 1),
                  fontSize: 16,
                  fontWeight: FontWeight.w600
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(42, 27, 61, 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, 
                         color: const Color.fromRGBO(195, 194, 230, 1).withOpacity(0.7), 
                         size: 20),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(_project!.deadline!),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Теги
            if (_project!.tags.isNotEmpty) ...[
              const Text(
                'Теги',
                style: TextStyle(
                  color: Color.fromRGBO(195, 194, 230, 1),
                  fontSize: 16,
                  fontWeight: FontWeight.w600
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(42, 27, 61, 1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _project!.tags
                      .map((tag) => Chip(
                    label: Text(tag, style: const TextStyle(color: Colors.white)),
                    backgroundColor: const Color.fromARGB(255, 98, 23, 133), // Фиолетовый
                  ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Создатель
            const Text(
              'Создатель',
              style: TextStyle(
                color: Color.fromRGBO(195, 194, 230, 1),
                fontSize: 16,
                fontWeight: FontWeight.w600
              ),
            ),
            const SizedBox(height: 8),
            Card(
              color: const Color.fromRGBO(42, 27, 61, 1), // Фиолетовый фон
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(
                  color: Color.fromARGB(255, 98, 23, 133), // Фиолетовая граница
                  width: 1,
                ),
              ),
              child: ListTile(
                title: Text(
                  '${_project!.organizer.firstName} ${_project!.organizer.lastName}',
                  style: const TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  _project!.organizer.description,
                  style: const TextStyle(color: Color.fromRGBO(195, 194, 230, 1)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.person, 
                    color: Color.fromRGBO(195, 194, 230, 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}