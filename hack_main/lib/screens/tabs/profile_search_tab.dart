import 'package:flutter/material.dart';
import 'package:teste/services/auth_service.dart';
import 'package:teste/models/user_post.dart';
import 'package:teste/screens/other_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

class ProfileSearchTab extends StatefulWidget {
  const ProfileSearchTab({super.key});

  @override
  State<ProfileSearchTab> createState() => _ProfileSearchTabState();
}

class _ProfileSearchTabState extends State<ProfileSearchTab> {
  late Future<List<UserPost>> _futureUserPosts;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _selectedSkills = [];
  final List<String> _selectedInterests = [];
  String _selectedStatus = 'WANT_COLLABORATE';

  @override
  void initState() {
    super.initState();
    _futureUserPosts = _fetchUserPosts();
  }

  Future<void> refreshUserPosts() async {
    setState(() {
      _futureUserPosts = _fetchUserPosts();
    });
  }

  Future<List<UserPost>> _fetchUserPosts() async {
    final token = await AuthService().getAccessToken();

    // Разделяем введенный текст на firstName и lastName
    String firstName = '';
    String lastName = '';
    final parts = _searchController.text.trim().split(' ');
    if (parts.isNotEmpty) {
      firstName = parts[0];
      if (parts.length > 1) {
        lastName = parts.sublist(1).join(' ');
      }
    }

    final Map<String, dynamic> requestBody = {
      "firstName": firstName.isEmpty ? null : firstName,
      "lastName": lastName.isEmpty ? null : lastName,
      "description": null,
      "status": _selectedStatus,
    };

    if (_selectedSkills.isNotEmpty) {
      requestBody["skills"] = _selectedSkills;
    }

    if (_selectedInterests.isNotEmpty) {
      requestBody["interests"] = _selectedInterests;
    }

    final bodyJson = json.encode(requestBody);
    log('API Request Body: $bodyJson', name: 'SearchScreen');

    try {
      final response = await http.post(
        Uri.parse('https://prod-app.ru/api/user-profiles/search'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: bodyJson,
      );

      log('Response Status: ${response.statusCode}', name: 'SearchScreen');
      log('Response Body: ${response.body}', name: 'SearchScreen');

      if (response.statusCode == 200) {
        final dynamic jsonResponse = json.decode(response.body);

        if (jsonResponse is List) {
          return jsonResponse.map((e) => UserPost.fromJson(e)).toList();
        }

        if (jsonResponse is Map) {
          return [UserPost.fromJson(Map<String, dynamic>.from(jsonResponse))];
        }

        return [];
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error fetching posts: $e', name: 'SearchScreen');
      rethrow;
    }
  }

  void _performSearch() {
    setState(() {
      _futureUserPosts = _fetchUserPosts();
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedSkills.clear();
      _selectedInterests.clear();
      _selectedStatus = 'WANT_COLLABORATE';
    });
    _performSearch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: Column(
          children: [
            // Верхняя панель с фильтрами
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Поиск по имени и фамилии',
                      hintStyle: const TextStyle(color: Colors.grey),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: _performSearch,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                  const SizedBox(height: 16),
                  // Навыки и интересы
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.code, color: Color.fromRGBO(195, 194, 230, 1)),
                          label: const Text(
                            'Навыки',
                            style: TextStyle(color: Color.fromRGBO(195, 194, 230, 1)),
                          ),
                          onPressed: () => _showTagInputDialog(
                            title: 'Навыки',
                            currentTags: _selectedSkills,
                            onApply: (tags) {
                              setState(() {
                                _selectedSkills.clear();
                                _selectedSkills.addAll(tags);
                              });
                              _performSearch();
                            },
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 42, 19, 53),
                            foregroundColor: const Color.fromRGBO(195, 194, 230, 1),
                            elevation: 1,
                            side: const BorderSide(color: Color.fromRGBO(196, 194, 230, 1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.interests, color: Color.fromRGBO(195, 194, 230, 1)),
                          label: const Text(
                            'Интересы',
                            style: TextStyle(color: Color.fromRGBO(195, 194, 230, 1)),
                          ),
                          onPressed: () => _showTagInputDialog(
                            title: 'Интересы',
                            currentTags: _selectedInterests,
                            onApply: (tags) {
                              setState(() {
                                _selectedInterests.clear();
                                _selectedInterests.addAll(tags);
                              });
                              _performSearch();
                            },
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 42, 19, 53),
                            foregroundColor: const Color.fromRGBO(195, 194, 230, 1),
                            side: const BorderSide(color: Color.fromRGBO(196, 194, 230, 1)),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Статус',
                      labelStyle: const TextStyle(color: Colors.white),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    dropdownColor: const Color.fromRGBO(26, 15, 41, 1),
                    style: const TextStyle(color: Colors.white),
                    items: const [
                      DropdownMenuItem(value: 'WANT_COLLABORATE', child: Text('Ищет сотрудничество', style: TextStyle(fontFamily: 'Gilroy'))),
                      DropdownMenuItem(value: 'EXPLORING_OPPORTUNITIES', child: Text('Ищу возможности', style: TextStyle(fontFamily: 'Gilroy'))),
                      DropdownMenuItem(value: 'OPEN_TO_COLLABORATION', child: Text('Открыт к сотрудничеству', style: TextStyle(fontFamily: 'Gilroy'))),
                      DropdownMenuItem(value: 'AVAILABLE_FOR_FEEDBACK', child: Text('Готов получать советы', style: TextStyle(fontFamily: 'Gilroy'))),
                      DropdownMenuItem(value: 'LEADING_PROJECT', child: Text('Веду проект', style: TextStyle(fontFamily: 'Gilroy'))),
                      DropdownMenuItem(value: 'NOT_AVAILABLE', child: Text('Не доступен', style: TextStyle(fontFamily: 'Gilroy'))),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value!;
                      });
                      _performSearch();
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 100, 41, 128),
                          ),
                          onPressed: _performSearch,
                          child: const Text('Искать', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _clearFilters,
                        child: const Text('Очистить', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            Expanded(
              child: FutureBuilder<List<UserPost>>(
                future: _futureUserPosts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Ошибка при загрузке: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Пользователи не найдены',
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  final userPosts = snapshot.data!;

                  return RefreshIndicator(
                    onRefresh: refreshUserPosts,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: userPosts.length,
                      itemBuilder: (context, index) {
                        final userPost = userPosts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OtherUserProfilePage(userId: userPost.id),
                              ),
                            );
                          },
                          child: Card(
                            color: const Color.fromRGBO(26, 15, 41, 1),
                            margin: const EdgeInsets.only(bottom: 16),
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
                                          '${userPost.firstName} ${userPost.lastName}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(userPost.status),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          _getStatusText(userPost.status),
                                          style: const TextStyle(color: Colors.white, fontSize: 10),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (userPost.description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Text(
                                        userPost.description,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  if (userPost.skills.isNotEmpty) ...[
                                    const Text(
                                      'Навыки:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    Wrap(
                                      spacing: 4,
                                      children: userPost.skills.map((s) => Chip(
                                        label: Text(
                                          s,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: Colors.purple,
                                      )).toList(),
                                    ),
                                  ],
                                  if (userPost.interests.isNotEmpty) ...[
                                    const Text(
                                      'Интересы:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 7),
                                    Wrap(
                                      spacing: 4,
                                      children: userPost.interests.map((s) => Container(
                                        decoration: BoxDecoration(
                                          color: Colors.deepPurpleAccent,
                                          border: Border.all(color: Colors.white),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: Text(
                                          s,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                      )).toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WANT_COLLABORATE': return const Color.fromARGB(141, 76, 175, 79);
      case 'WANT_PROJECT': return Colors.blue;
      case 'OPEN_TO_WORK': return Colors.orange;
      case 'BUSY': return Colors.red;
      case 'UNAVAILABLE': return Colors.grey;
      default: return Colors.black;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'WANT_COLLABORATE': return 'Ищет сотрудничество';
      case 'WANT_PROJECT': return 'Ищет проект';
      case 'OPEN_TO_WORK': return 'Открыт к работе';
      case 'BUSY': return 'Занят';
      case 'UNAVAILABLE': return 'Недоступен';
      default: return status;
    }
  }

  void _showTagInputDialog({
    required String title,
    required List<String> currentTags,
    required Function(List<String>) onApply,
  }) async {
    final TextEditingController tagController = TextEditingController();
    final List<String> tempTags = List.from(currentTags);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            void addTag() {
              final text = tagController.text.trim();
              if (text.isNotEmpty && !tempTags.contains(text)) {
                setStateDialog(() {
                  tempTags.add(text);
                  tagController.clear();
                });
              }
            }

            return AlertDialog(
              scrollable: true,
              title: Text('Добавить $title'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tagController,
                          decoration: InputDecoration(
                            hintText: 'Введите $title',
                            isDense: true,
                            border: const OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => addTag(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: addTag,
                        icon: const Icon(Icons.add_circle, color: Colors.blue),
                        tooltip: 'Добавить',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (tempTags.isEmpty)
                    const Text(
                      'Список пуст',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: tempTags.map((tag) {
                        return Chip(
                          label: Text(tag),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setStateDialog(() {
                              tempTags.remove(tag);
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tagController.text.trim().isNotEmpty) {
                      addTag();
                    }
                    Navigator.pop(context);
                    onApply(tempTags);
                  },
                  child: const Text('Применить'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
