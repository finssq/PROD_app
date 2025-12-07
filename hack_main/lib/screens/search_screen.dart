import 'package:flutter/material.dart';
import 'package:teste/services/auth_service.dart';
import 'package:teste/models/user_post.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer'; 
import 'package:teste/screens/tabs/profile_search_tab.dart';
import 'package:teste/screens/tabs/event_search_tab.dart';
import 'package:teste/screens/tabs/projects_search_tab.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 48),
          child: AppBar(
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                color: const Color.fromARGB(255, 13, 13, 27),
              ),
            ),
            title: const Text(
              "Поиск",
              style: TextStyle(color: Colors.white),
            ),
            bottom: const TabBar(
              indicatorColor: Color.fromRGBO(195, 194, 230, 1),
              labelColor: Color.fromRGBO(195, 194, 230, 1),
              unselectedLabelColor: Colors.grey,
              tabs: [
                Tab(text: "Профили", icon: Icon(Icons.person_search)),
                Tab(text: "Мероприятия", icon: Icon(Icons.event)),
                Tab(text: "Проекты", icon: Icon(Icons.folder))
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            ProfileSearchTab(),
            EventSearchTab(),
            ProjectsSearchTab(),
          ],
        ),
      ),
    );
  }
}


