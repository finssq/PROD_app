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

/// ---------- ВКЛАДКА: ПРОФИЛИ ----------
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
      print("❌ ERROR loading profiles: $e");
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
        color: const Color(0xFF2A1B3D),
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
                    child: Text("${user.firstName} ${user.lastName}",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
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
                Text(user.description,
                    style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              if (user.skills.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: user.skills
                      .map((s) => Chip(
                            label: Text(s),
                            backgroundColor: Colors.deepPurpleAccent,
                            labelStyle: const TextStyle(color: Colors.white),
                          ))
                      .toList(),
                ),
              if (user.interests.isNotEmpty)
                Wrap(
                  spacing: 6,
                  children: user.interests
                      .map((i) => Chip(
                            label: Text(i),
                            backgroundColor: Colors.purple,
                            labelStyle: const TextStyle(color: Colors.white),
                          ))
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
            Color.fromRGBO(37, 22, 53, 1),
            Color.fromRGBO(26, 15, 41, 1),
            Color.fromRGBO(8, 8, 17, 1),
          ],
        ),
      ),
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : profiles.isEmpty
              ? const Center(
                  child: Text(
                  "Нет рекомендаций",
                  style: TextStyle(color: Colors.white),
                ))
              : ListView.builder(
                  itemCount: profiles.length,
                  itemBuilder: (_, i) => _buildProfileCard(profiles[i]),
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'WANT_COLLABORATE':
        return const Color.fromARGB(141, 76, 175, 79);
      case 'WANT_PROJECT':
        return Colors.blue;
      case 'OPEN_TO_WORK':
        return Colors.orange;
      case 'BUSY':
        return Colors.red;
      case 'UNAVAILABLE':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'WANT_COLLABORATE':
        return 'Ищет сотрудничество';
      case 'WANT_PROJECT':
        return 'Ищет проект';
      case 'OPEN_TO_WORK':
        return 'Открыт к работе';
      case 'BUSY':
        return 'Занят';
      case 'UNAVAILABLE':
        return 'Недоступен';
      default:
        return status;
    }
  }
}
