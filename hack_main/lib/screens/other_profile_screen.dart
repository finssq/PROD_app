import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';

class UserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String description;
  final String status;
  final List<String> skills;
  final List<String> interests;

  UserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.description,
    required this.status,
    required this.skills,
    required this.interests,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
    );
  }
}

class OtherUserProfilePage extends StatefulWidget {
  final String userId;

  const OtherUserProfilePage({required this.userId});

  @override
  State<OtherUserProfilePage> createState() => _OtherUserProfilePageState();
}

class _OtherUserProfilePageState extends State<OtherUserProfilePage> {
  UserProfile? _profile;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final token = await AuthService().getAccessToken();
      final response = await http.get(
        Uri.parse('https://prod-app.ru/api/user-profiles/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _profile = UserProfile.fromJson(data);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Ошибка сервера: ${response.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Ошибка: $e';
        _loading = false;
      });
    }
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
        child: SafeArea(
          child: Column(
            children: [
              Container(
                height: kToolbarHeight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  color: Color(0xFF2A1B3D),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _profile != null
                            ? '${_profile!.firstName} ${_profile!.lastName}'
                            : 'Профиль пользователя',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.white),
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(16),
                            child: ListView(
                              children: [
                                const SizedBox(height: 10),
                                Text(
                                  'Статус: ${_profile!.status}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Описание: ${_profile!.description}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 20),
                                const Text('Навыки:',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: _profile!.skills
                                      .map((skill) => Chip(
                                            label: Text(skill),
                                            backgroundColor:
                                               Colors.purple,
                                          ))
                                      .toList(),
                                ),
                                const SizedBox(height: 20),
                                const Text('Интересы:',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white)),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: _profile!.interests
                                      .map((interest) => Chip(
                                            label: Text(interest),
                                            backgroundColor:
                                                Colors.deepPurpleAccent,
                                          ))
                                      .toList(),
                                ),
                              ],
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
