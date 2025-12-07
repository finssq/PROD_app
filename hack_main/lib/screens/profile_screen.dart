import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:teste/screens/recommendation_screen.dart';
import 'package:teste/screens/search_screen.dart';
import 'package:teste/screens/tabs/my_events_tab.dart';
import 'package:teste/services/auth_service.dart';
import 'package:teste/models/user_entity.dart';
import 'package:teste/models/user_post.dart';
import 'package:teste/screens/auth_screen.dart';
import 'package:flutter/semantics.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();
  UserEntity? _user;
  UserPost? _userProfile;
  bool _isLoading = false;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Статусы для выпадающего списка
  final Map<String, String> _statusOptions = {
    'WANT_COLLABORATE': 'Ищу напарника',
    'BUSY': 'Занят(а)',
    'LOOKING_FOR_WORK': 'Ищу работу',
  };

  String _selectedStatus = 'WANT_COLLABORATE';

  // Контроллеры
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _skills = [];
  final List<String> _interests = [];
  final _skillsInputController = TextEditingController();
  final _interestsInputController = TextEditingController();

  // Base URL для API - БЕЗ /api!
  final String _baseUrl = 'https://prod-app.ru';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserInfo();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _descriptionController.dispose();
    _skillsInputController.dispose();
    _interestsInputController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAuthState();
    }
  }

  Future<void> _checkAuthState() async {
    try {
      final needsAuth = await _authService.needsAuthentication();
      if (needsAuth && _user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthScreen(),
          ),
        );
      }
    } catch (_) {}
  }

  // ЗАГРУЗКА профиля с API (GET запрос)
  Future<void> _loadUserProfile() async {
    if (_user == null || _user!.id.isEmpty) return;

    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Токен авторизации не найден');
      }

      log('Загрузка профиля пользователя ${_user!.id}', name: 'ProfileService');

      // СОЗДАЕМ HTTP КЛИЕНТ С ОБХОДОМ SSL ПРОВЕРКИ
      final httpClient = HttpClient();

      // ОБХОДИМ SSL ПРОВЕРКУ
      httpClient.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        log('Обход SSL проверки для $host:$port', name: 'ProfileService');
        return true;
      };

      // Пробуем разные URL для GET запроса
      final getUrls = [
        '$_baseUrl/api/user-profiles/${_user!.id}',  // с /api
        '$_baseUrl/user-profiles/${_user!.id}',      // без /api
      ];

      dynamic lastError;

      for (final url in getUrls) {
        try {
          log('Попытка GET: $url', name: 'ProfileService');
          final request = await httpClient.getUrl(Uri.parse(url));
          request.headers.set('Authorization', 'Bearer $token');
          request.headers.set('Content-Type', 'application/json');
          request.headers.set('Accept', 'application/json');

          final response = await request.close();
          final responseBody = await response.transform(utf8.decoder).join();

          log('GET Статус для $url: ${response.statusCode}', name: 'ProfileService');

          if (response.statusCode == 200) {
            final data = jsonDecode(responseBody) as Map<String, dynamic>;
            if (mounted) {
              setState(() {
                _userProfile = UserPost.fromJson(data);
                _skills.clear();
                _skills.addAll(_userProfile?.skills ?? []);
                _interests.clear();
                _interests.addAll(_userProfile?.interests ?? []);

                _firstNameController.text = _userProfile?.firstName ?? '';
                _lastNameController.text = _userProfile?.lastName ?? '';
                _descriptionController.text = _userProfile?.description ?? '';

                // Устанавливаем статус из профиля или дефолтный
                _selectedStatus = _userProfile?.status ?? 'WANT_COLLABORATE';
              });
            }
            log('Профиль успешно загружен с URL: $url', name: 'ProfileService');
            return;

          } else if (response.statusCode == 404) {
            log('Профиль не найден по URL: $url', name: 'ProfileService');
            lastError = 'Профиль не найден (404)';
            continue; // Пробуем следующий URL
          }

        } catch (e) {
          log('Ошибка GET для $url: $e', name: 'ProfileService');
          lastError = e;
        }
      }

      // Если все URL вернули 404, значит профиля действительно нет
      log('Профиль не найден ни по одному URL, будет создан новый', name: 'ProfileService');
      if (mounted) {
        setState(() {
          _userProfile = null;
          _selectedStatus = 'WANT_COLLABORATE'; // Дефолтный статус
        });
      }

    } catch (e) {
      log('Ошибка загрузки профиля: $e', name: 'ProfileService');
      if (mounted) {
        setState(() {
          _userProfile = null;
        });
      }
    }
  }

  // СОХРАНЕНИЕ профиля
// СОХРАНЕНИЕ профиля
  Future<void> _saveProfile() async {
    if (_user == null || _user!.id.isEmpty) {
      _showSnackBar('ID пользователя не найден', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final token = await _authService.getAccessToken();
      if (token == null) throw Exception('Токен не найден');

      final requestData = {
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "description": _descriptionController.text.trim(),
        "status": _selectedStatus,
        "skills": _skills,
        "interests": _interests,
      };

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      log('Пробуем создать/обновить профиль', name: 'ProfileService');
      log('Данные для отправки: ${json.encode(requestData)}', name: 'ProfileService');

      // Используем пакет http вместо HttpClient
      // Пробуем разные URL в порядке приоритета

      // 1. POST без ID в URL
      try {
        log('Попытка 1: POST на $_baseUrl/user-profiles', name: 'ProfileService');
        final response = await http.post(
          Uri.parse('$_baseUrl/user-profiles'),
          headers: headers,
          body: json.encode(requestData),
        );

        log('POST (без ID) Статус: ${response.statusCode}', name: 'ProfileService');
        log('Тело ответа: ${response.body}', name: 'ProfileService');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _userProfile = UserPost.fromJson(data);
              _isEditing = false;
            });
            _showSnackBar('Профиль успешно создан!', isError: false);
          }
          return;
        }
      } catch (e) {
        log('Ошибка в попытке 1: $e', name: 'ProfileService');
      }

      // 2. POST с ID в URL
      try {
        log('Попытка 2: POST на $_baseUrl/user-profiles/${_user!.id}', name: 'ProfileService');
        final response = await http.post(
          Uri.parse('$_baseUrl/user-profiles/${_user!.id}'),
          headers: headers,
          body: json.encode(requestData),
        );

        log('POST (с ID) Статус: ${response.statusCode}', name: 'ProfileService');
        log('Тело ответа: ${response.body}', name: 'ProfileService');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _userProfile = UserPost.fromJson(data);
              _isEditing = false;
            });
            _showSnackBar('Профиль успешно создан/обновлен!', isError: false);
          }
          return;
        }
      } catch (e) {
        log('Ошибка в попытке 2: $e', name: 'ProfileService');
      }

      // 3. PUT с ID - с /api
      try {
        log('Попытка 3: PUT на $_baseUrl/api/user-profiles/${_user!.id}', name: 'ProfileService');
        final response = await http.put(
          Uri.parse('$_baseUrl/api/user-profiles/${_user!.id}'),
          headers: headers,
          body: json.encode(requestData),
        );

        log('PUT Статус: ${response.statusCode}', name: 'ProfileService');
        log('Тело ответа: ${response.body}', name: 'ProfileService');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _userProfile = UserPost.fromJson(data);
              _isEditing = false;
            });
            _showSnackBar('Профиль успешно обновлен!', isError: false);
          }
          return;
        }
      } catch (e) {
        log('Ошибка в попытке 3: $e', name: 'ProfileService');
      }

      // 4. POST с /api
      try {
        log('Попытка 4: POST на $_baseUrl/api/user-profiles', name: 'ProfileService');
        final response = await http.post(
          Uri.parse('$_baseUrl/api/user-profiles'),
          headers: headers,
          body: json.encode(requestData),
        );

        log('POST (с /api) Статус: ${response.statusCode}', name: 'ProfileService');
        log('Тело ответа: ${response.body}', name: 'ProfileService');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _userProfile = UserPost.fromJson(data);
              _isEditing = false;
            });
            _showSnackBar('Профиль успешно создан!', isError: false);
          }
          return;
        }
      } catch (e) {
        log('Ошибка в попытке 4: $e', name: 'ProfileService');
      }

      // 5. PATCH запрос (на всякий случай)
      try {
        log('Попытка 5: PATCH на $_baseUrl/api/user-profiles/${_user!.id}', name: 'ProfileService');
        final response = await http.patch(
          Uri.parse('$_baseUrl/api/user-profiles/${_user!.id}'),
          headers: headers,
          body: json.encode(requestData),
        );

        log('PATCH Статус: ${response.statusCode}', name: 'ProfileService');
        log('Тело ответа: ${response.body}', name: 'ProfileService');

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _userProfile = UserPost.fromJson(data);
              _isEditing = false;
            });
            _showSnackBar('Профиль успешно обновлен!', isError: false);
          }
          return;
        }
      } catch (e) {
        log('Ошибка в попытке 5: $e', name: 'ProfileService');
      }

      throw Exception('Не удалось сохранить профиль. Все методы не сработали.');

    } catch (e) {
      log('Ошибка сохранения профиля: $e', name: 'ProfileService');
      _showSnackBar('Ошибка: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // Методы для работы с навыками (только локальное обновление состояния)
  void _addSkill() {
    final text = _skillsInputController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Введите навык', isError: true);
      return;
    }

    final newSkills = text
        .split(';')
        .map((skill) => skill.trim())
        .where((skill) => skill.isNotEmpty)
        .toList();

    if (newSkills.isEmpty) {
      _showSnackBar('Не найдено навыков для добавления', isError: true);
      return;
    }

    int addedCount = 0;
    List<String> duplicates = [];

    for (final skill in newSkills) {
      final normalizedSkill = skill.toLowerCase();
      if (!_skills.any((s) => s.toLowerCase() == normalizedSkill)) {
        setState(() {
          _skills.add(skill);
        });
        addedCount++;
      } else {
        duplicates.add(skill);
      }
    }

    _skillsInputController.clear();

    if (addedCount > 0) {
      String message;
      if (duplicates.isEmpty) {
        message = addedCount == 1
            ? 'Добавлен 1 новый навык'
            : 'Добавлено $addedCount новых навыков';
      } else {
        message = addedCount == 1
            ? 'Добавлен 1 новый навык, ${duplicates.length} уже существует'
            : 'Добавлено $addedCount новых навыков, ${duplicates.length} уже существует';
      }
      _showSnackBar(message, isError: false);
    } else if (duplicates.isNotEmpty) {
      _showSnackBar(
        'Все введенные навыки (${duplicates.length}) уже существуют',
        isError: true,
      );
    }
  }

  void _removeSkill(int index) {
    setState(() {
      _skills.removeAt(index);
    });
    _showSnackBar('Навык удален', isError: false);
  }

  void _clearAllSkills() {
    if (_skills.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все навыки?'),
        content: const Text('Вы уверены, что хотите удалить все навыки?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _skills.clear();
              });
              _showSnackBar('Все навыки удалены', isError: false);
            },
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Методы для работы с интересами (только локальное обновление состояния)
  void _addInterest() {
    final text = _interestsInputController.text.trim();
    if (text.isEmpty) {
      _showSnackBar('Введите интерес', isError: true);
      return;
    }

    final newInterests = text
        .split(';')
        .map((interest) => interest.trim())
        .where((interest) => interest.isNotEmpty)
        .toList();

    if (newInterests.isEmpty) {
      _showSnackBar('Не найдено интересов для добавления', isError: true);
      return;
    }

    int addedCount = 0;
    List<String> duplicates = [];

    for (final interest in newInterests) {
      final normalizedInterest = interest.toLowerCase();
      if (!_interests.any((s) => s.toLowerCase() == normalizedInterest)) {
        setState(() {
          _interests.add(interest);
        });
        addedCount++;
      } else {
        duplicates.add(interest);
      }
    }

    _interestsInputController.clear();

    if (addedCount > 0) {
      String message;
      if (duplicates.isEmpty) {
        message = addedCount == 1
            ? 'Добавлен 1 новый интерес'
            : 'Добавлено $addedCount новых интересов';
      } else {
        message = addedCount == 1
            ? 'Добавлен 1 новый интерес, ${duplicates.length} уже существует'
            : 'Добавлено $addedCount новых интересов, ${duplicates.length} уже существует';
      }
      _showSnackBar(message, isError: false);
    } else if (duplicates.isNotEmpty) {
      _showSnackBar(
        'Все введенные интересы (${duplicates.length}) уже существуют',
        isError: true,
      );
    }
  }

  void _removeInterest(int index) {
    setState(() {
      _interests.removeAt(index);
    });
    _showSnackBar('Интерес удален', isError: false);
  }

  void _clearAllInterests() {
    if (_interests.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Очистить все интересы?'),
        content: const Text('Вы уверены, что хотите удалить все интересы?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _interests.clear();
              });
              _showSnackBar('Все интересы удалены', isError: false);
            },
            child: const Text('Очистить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Начинаем редактирование
  void _startEditing() {
    setState(() {
      _isEditing = true;
      if (_userProfile == null) {
        _firstNameController.text = _user?.firstName ?? '';
        _lastNameController.text = _user?.lastName ?? '';
        _selectedStatus = "WANT_COLLABORATE";
      } else {
        _selectedStatus = _userProfile?.status ?? 'WANT_COLLABORATE';
      }
    });
  }

  // Отменяем редактирование
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      if (_userProfile != null) {
        _firstNameController.text = _userProfile!.firstName;
        _lastNameController.text = _userProfile!.lastName;
        _descriptionController.text = _userProfile!.description;
        _selectedStatus = _userProfile!.status;
        _skills.clear();
        _skills.addAll(_userProfile!.skills);
        _interests.clear();
        _interests.addAll(_userProfile!.interests);
      }
      _skillsInputController.clear();
      _interestsInputController.clear();
    });
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userEntity = await _authService.getUserInfo();
      if (!mounted) return;

      setState(() {
        _user = userEntity;
      });

      await _loadUserProfile();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      log('Ошибка загрузки информации пользователя: $e', name: 'ProfileService');
      _setError('Ошибка загрузки информации пользователя: ${e.toString()}');
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);

    try {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AuthScreen(),
          ),
        );
      }
    } catch (e) {
      _setError('Ошибка выхода: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 13, 13, 27),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const RecommendationScreen(),
          const SearchScreen(),
          _buildProfileScreen(context),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Color.fromARGB(255, 13, 13, 27),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border(
          top: BorderSide(
            color: Color.fromARGB(255, 84, 84, 131),
            width: 2,
          ),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (i) {
              setState(() => _selectedIndex = i);
            },
            enableFeedback: false,
            mouseCursor: SystemMouseCursors.basic,
            landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            type: BottomNavigationBarType.fixed,
            backgroundColor: const Color.fromARGB(255, 25, 25, 43),
            selectedItemColor: const Color.fromARGB(255, 108, 108, 158),
            unselectedItemColor: const Color.fromARGB(255, 56, 56, 94),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: '',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(13, 13, 27, 1),
        elevation: 0,
        title: Text(
          _isEditing ? 'Редактирование профиля' : 'Профиль',
          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w300),
        ),
        actions: _buildAppBarActions(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D1B),
              Color(0x0D0D1B),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    backgroundColor: Colors.grey[900],
                    color: Colors.white,
                    onRefresh: _loadUserInfo,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildErrorCard(),
                            ),

                          if (_isLoading && !_isEditing)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _buildLoadingIndicator(),
                            ),

                          if (_user != null)
                            _isEditing ? _buildEditForm() : _buildUserCard()
                          else
                            Center(
                              child: Text(
                                'Профиль не загрузился',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),

                          if (!_isEditing) const SizedBox(height: 32),

                          if (!_isEditing) _buildActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isEditing) {
      return [
        IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: _isSaving ? null : _cancelEditing,
        ),
        IconButton(
          icon: const Icon(Icons.save, color: Colors.green),
          onPressed: _isSaving ? null : _saveProfile,
        ),
      ];
    } else {
      return [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.grey[400]),
          onPressed: _isLoading ? null : _loadUserInfo,
        ),
        if (_userProfile != null)
          IconButton(
            icon: Icon(Icons.edit, color: Colors.grey[400]),
            onPressed: _startEditing,
            tooltip: 'Изменить профиль',
          ),
      ];
    }
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[900]!.withOpacity(0.12),
        border: Border.all(color: Colors.red[800]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[300], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: TextStyle(color: Colors.red[300], fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: Icon(Icons.close, color: Colors.red[300], size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
            ),
          ),
          const SizedBox(height: 12),
          Text('Загрузка профиля...', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        ],
      ),
    );
  }

  // Форма редактирования профиля
  Widget _buildEditForm() {
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              _user!.username.isNotEmpty ? _user!.username[0].toUpperCase() : 'U',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 42,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),

          // User ID
          Text(
            'ID: ${_user!.id}',
            style: const TextStyle(color: Colors.grey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Username
          Text(
            _user!.username,
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Email
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _user!.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (_user!.emailVerified)
                Icon(Icons.verified, color: Colors.green[400], size: 16),
            ],
          ),
          const SizedBox(height: 24),

          // Edit Form
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(30, 30, 46, 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First Name
                _buildFormField(
                  label: 'Имя',
                  controller: _firstNameController,
                  hintText: 'Введите имя',
                ),
                const SizedBox(height: 16),

                // Last Name
                _buildFormField(
                  label: 'Фамилия',
                  controller: _lastNameController,
                  hintText: 'Введите фамилию',
                ),
                const SizedBox(height: 16),

                // Description
                _buildFormField(
                  label: 'Описание',
                  controller: _descriptionController,
                  hintText: 'Расскажите о себе...',
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Status Dropdown
                _buildStatusDropdown(),
                const SizedBox(height: 32),

                // Skills Component
                _buildSkillsField(),
                const SizedBox(height: 16),

                // Interests Component
                _buildInterestsField(),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Save Button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Виджет выпадающего списка статусов
  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статус',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
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
              dropdownColor: const Color.fromRGBO(30, 30, 46, 1),
              icon: Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
              style: const TextStyle(color: Colors.white, fontSize: 16),
              items: _statusOptions.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(entry.value),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ... existing code ...

  Widget _buildSkillsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  "Навыки",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_skills.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 78, 75, 134),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _skills.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (_skills.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: _clearAllSkills,
                tooltip: 'Очистить все навыки',
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Skills chips
        if (_skills.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.asMap().entries.map((entry) {
              return Chip(
                label: Text(
                  entry.value,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                backgroundColor: const Color.fromARGB(255, 47, 47, 100),
                deleteIcon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                onDeleted: () => _removeSkill(entry.key),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              );
            }).toList(),
          ),

        const SizedBox(height: 12),

        // Поле ввода — только TextField, без кнопки
        TextField(
          controller: _skillsInputController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Введите навыки через ; (например: Flutter;Dart)',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onSubmitted: (_) => _addSkill(), // Обработка по нажатию Enter
          textInputAction: TextInputAction.done,
        ),

        if (_skills.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.grey[500], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Вводите навыки через точку с запятой (например: Flutter;Dart;UI/UX)',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInterestsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  "Интересы",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_interests.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 78, 75, 134),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _interests.length.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            if (_interests.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.grey[400],
                  size: 20,
                ),
                onPressed: _clearAllInterests,
                tooltip: 'Очистить все интересы',
              ),
          ],
        ),

        const SizedBox(height: 12),

        // Interests chips
        if (_interests.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interests.asMap().entries.map((entry) {
              return Chip(
                label: Text(
                  entry.value,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                backgroundColor: const Color.fromARGB(255, 47, 47, 100),
                deleteIcon: Icon(Icons.close, size: 18, color: Colors.grey[400]),
                onDeleted: () => _removeInterest(entry.key),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              );
            }).toList(),
          ),

        const SizedBox(height: 12),


        TextField(
          controller: _interestsInputController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Введите интересы через ; (например: Путешествия;Музыка)',
            hintStyle: TextStyle(color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[700]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[400]!),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          onSubmitted: (_) => _addInterest(),
          textInputAction: TextInputAction.done,
        ),

        if (_interests.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.grey[500], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Вводите интересы через точку с запятой (например: Путешествия;Музыка;Спорт)',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }


  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : const Text(
          'СОХРАНИТЬ ПРОФИЛЬ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    // Функция для получения человеко-читаемого статуса
    String getStatusDisplay(String status) {
      return _statusOptions[status] ?? status;
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Text(
              _user!.username.isNotEmpty ? _user!.username[0].toUpperCase() : 'U',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 42,
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            _user!.username,
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Email with verification icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _user!.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (_user!.emailVerified)
                Icon(Icons.verified, color: Colors.green[400], size: 18),
            ],
          ),
          const SizedBox(height: 32),

          // User Details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(30, 30, 46, 1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUserDetail("User ID", _user!.id),
                const SizedBox(height: 16),
                if (_userProfile?.firstName?.isNotEmpty == true)
                  Column(
                    children: [
                      _buildUserDetail("Имя", _userProfile!.firstName!),
                      const SizedBox(height: 16),
                    ],
                  ),
                if (_userProfile?.lastName?.isNotEmpty == true)
                  Column(
                    children: [
                      _buildUserDetail("Фамилия", _userProfile!.lastName!),
                      const SizedBox(height: 16),
                    ],
                  ),
                if (_userProfile?.description?.isNotEmpty == true)
                  Column(
                    children: [
                      _buildUserDetail("Описание", _userProfile!.description!),
                      const SizedBox(height: 16),
                    ],
                  ),
                if (_userProfile?.status?.isNotEmpty == true)
                  Column(
                    children: [
                      _buildUserDetail("Статус", getStatusDisplay(_userProfile!.status)),
                      const SizedBox(height: 16),
                    ],
                  ),
                if (_skills.isNotEmpty)
                  Column(
                    children: [
                      _buildUserDetail("Навыки", _skills.join(', ')),
                      const SizedBox(height: 16),
                    ],
                  ),
                if (_interests.isNotEmpty)
                  Column(
                    children: [
                      _buildUserDetail("Интересы", _interests.join(', ')),
                      const SizedBox(height: 16),
                    ],
                  ),
                _buildUserDetail(
                    "Email статус",
                    _user!.emailVerified ? "Верифицирован" : "Не верифицирован",
                    color: _user!.emailVerified
                        ? Colors.green[400]
                        : Colors.red[400]),
              ],
            ),
          ),

          if (_userProfile == null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[900]!.withOpacity(0.12),
                  border: Border.all(color: Colors.orange[800]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange[300], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Профиль еще не создан. Нажмите "Изменить профиль" для создания.',
                        style: TextStyle(color: Colors.orange[300], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserDetail(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Кнопка Изменить профиль
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _startEditing,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.blue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.blue.withOpacity(0.1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.edit,
                  size: 20,
                  color: Colors.blue[300],
                ),
                const SizedBox(width: 8),
                Text(
                  _userProfile == null ? 'СОЗДАТЬ ПРОФИЛЬ' : 'ИЗМЕНИТЬ ПРОФИЛЬ',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[300],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        SizedBox(
  width: double.infinity,
  height: 50,
  child: OutlinedButton(
    onPressed: () async {
      const url = 'https://keycloak.prod-app.ru/realms/monolith-spring-boot-app/account/';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Не удалось открыть URL: $url');
      }
    },
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.deepPurpleAccent),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.deepPurpleAccent.withOpacity(0.1),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.edit_note_outlined,
          size: 20,
          color: Colors.deepPurpleAccent,
        ),
        SizedBox(width: 8),
        Text(
          "РЕДАКТИРОВАТЬ ПРОФИЛЬ KEYCLOAK",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            fontFamily: 'Gilroy',
            color: Colors.deepPurpleAccent,
          ),
        ),
      ],
    ),
  ),
),
 

        const SizedBox(height: 16),
        SizedBox(
  width: double.infinity,
  height: 50,
  child: OutlinedButton(
    onPressed: () {
      Navigator.push(
      context,
      MaterialPageRoute(
      builder: (context) => (const MyEventsTab()), // <-- сюда твоя вкладка
    ),
  );
    },
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(
        color: Color.fromARGB(255, 58, 11, 66),
        width: 4,
        ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor:Color.fromARGB(255, 139, 109, 156),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.place_outlined,
          size: 20,
          color:Color.fromARGB(255, 58, 11, 66),
        ),
        SizedBox(width: 8),
        Text(
          "МОИ МЕРОПРИЯТИЯ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Gilroy',
            color:Color.fromARGB(255, 58, 11, 66),
          ),
        ),
      ],
    ),
  ),
),
        const SizedBox(height: 16),
        SizedBox(
  width: double.infinity,
  height: 50,
  child: OutlinedButton(
    onPressed: () {
      Navigator.push(
      context,
      MaterialPageRoute(
      builder: (context) => (const MyEventsTab()), // <-- сюда твоя вкладка
    ),
  );
    },
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: const BorderSide(
        color:Color.fromARGB(255, 43, 4, 78),
        width: 4,
        ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Color.fromARGB(255, 152, 109, 190),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.folder,
          size: 20,
          color:Color.fromARGB(255, 43, 4, 78),
        ),
        SizedBox(width: 8),
        Text(
          "МОИ ПРОЕКТЫ",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Gilroy',
            color:Color.fromARGB(255, 43, 4, 78),
          ),
        ),
      ],
    ),
  ),
),
        const SizedBox(height: 16),
        // Кнопка Выйти
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: _isLoading ? null : _handleLogout,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[400],
              side: BorderSide(color: Colors.red[800]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout, size: 20),
                const SizedBox(width: 8),
                Text(
                  "ВЫЙТИ ИЗ АККАУНТА",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}