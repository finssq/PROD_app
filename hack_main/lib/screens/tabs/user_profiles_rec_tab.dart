import 'package:flutter/material.dart';
import 'package:teste/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:teste/screens/other_profile_screen.dart';

class UserProfileRec {
  final String id;
  final String firstName;
  final String lastName;
  final String description;
  final String status;
  final List<String> skills;
  final List<String> interests;

  UserProfileRec({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.description,
    required this.status,
    required this.skills,
    required this.interests,
  });

  factory UserProfileRec.fromJson(Map<String, dynamic> json) {
    return UserProfileRec(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      interests: List<String>.from(json['interests'] ?? []),
    );
  }
}

class UserProfilesRecTab extends StatefulWidget {
  const UserProfilesRecTab({super.key});

  @override
  State<UserProfilesRecTab> createState() => _UserProfilesRecTabState();
}

class _UserProfilesRecTabState extends State<UserProfilesRecTab> {
  List<UserProfileRec> profiles = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    try {
      final token = await AuthService().getAccessToken();
      final response = await http.get(
        Uri.parse("https://prod-app.ru/api/user-profiles/recommendations"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          profiles = decoded.map((e) => UserProfileRec.fromJson(e)).toList();
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (e) {
      print("ERROR loading profiles: $e");
      setState(() => loading = false);
    }
  }

  Widget _buildProfileCard(UserProfileRec user) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtherUserProfilePage(userId: user.id),
          ),
        );
      },
      child: Card(
        color: const Color(0xFF2A1B3D), // тёмно-фиолетовый фон
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "${user.firstName} ${user.lastName}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      _getStatusText(user.status),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: _getStatusColor(user.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (user.description.isNotEmpty)
                Text(
                  user.description,
                  style: const TextStyle(color: Colors.white70),
                ),
              const SizedBox(height: 8),
              if (user.skills.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: user.skills
                      .map(
                        (s) => Chip(
                          label: Text(s),
                          backgroundColor: const Color.fromARGB(255, 68, 42, 94),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      )
                      .toList(),
                ),
              if (user.interests.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: user.interests
                      .map(
                        (i) => Chip(
                          label: Text(i),
                          backgroundColor: const Color(0xFF7B4DA0),
                          labelStyle: const TextStyle(color: Colors.white),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
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
            Color(0xFF1B0E2F),
            Color(0xFF2A1B3D),
            Color(0xFF0D0415),
          ],
        ),
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
          : profiles.isEmpty
              ? const Center(
                  child: Text(
                    "Нет рекомендаций",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (_, i) => _buildProfileCard(profiles[i]),
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WANT_COLLABORATE':
        return const Color(0xFF8E44AD);
      case 'EXPLORING_OPPORTUNITIES':
        return const Color(0xFF9B59B6);
      case 'OPEN_TO_COLLABORATION':
        return const Color(0xFF6C3483);
      case 'AVAILABLE_FOR_FEEDBACK':
        return const Color(0xFF5B2C6F);
      case 'LEADING_PROJECT':
        return const Color(0xFF7D3C98);
      case 'LOOKING_FOR_TEAM':
        return const Color(0xFF4A235A);
      case 'NOT_AVAILABLE':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'WANT_COLLABORATE':
        return 'Хочу сотрудничать';
      case 'EXPLORING_OPPORTUNITIES':
        return 'Ищу возможности';
      case 'OPEN_TO_COLLABORATION':
        return 'Открыт к сотрудничеству';
      case 'AVAILABLE_FOR_FEEDBACK':
        return 'Готов давать советы';
      case 'LEADING_PROJECT':
        return 'Веду проект';
      case 'LOOKING_FOR_TEAM':
        return 'Ищу команду';
      case 'NOT_AVAILABLE':
        return 'Недоступен';
      default:
        return status;
    }
  }
}
