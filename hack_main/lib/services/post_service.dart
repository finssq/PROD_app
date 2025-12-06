import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:teste/services/auth_service.dart';
import 'package:teste/models/user_post.dart';

class PostService {
  final AuthService authService = AuthService();

  final String baseUrl = "https://prod-app.ru"; 

  Future<List<UserPost>> getAllPosts() async {
    final token = await authService.getAccessToken();

    if (token == null) throw Exception("No access token");

    final response = await http.get(
      Uri.parse("$baseUrl/api/user-profiles/search"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": 'application/json; charset=utf8',
      },
    );

    if (response.statusCode == 200) {
      final List data = json.decode(
      utf8.decode(latin1.encode(response.body)), 
    );

      return data.map((e) => UserPost.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load posts: ${response.statusCode}");
    }
  }
}