import 'package:flutter/material.dart';
import 'package:teste/screens/tabs/user_profiles_rec_tab.dart';
import 'package:teste/screens/tabs/events_rec_tab.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Градиентный фон
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromRGBO(55, 33, 78, 1),
                Color.fromRGBO(44, 22, 75, 1),
                Color.fromRGBO(8, 8, 17, 1),
              ],
            ),
          ),
        ),
        // Scaffold поверх градиента
        Scaffold(
          backgroundColor: Colors.transparent, // чтобы был виден градиент
          appBar: AppBar(
            backgroundColor: const Color(0xFF2A1B3D),
            title: const Text("Рекомендации"),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: const Color.fromARGB(255, 87, 15, 100),
              tabs: const [
                Tab(text: "Профили"),
                Tab(text: "Мероприятия"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: const [
              UserProfilesRecTab(),
              EventsRecTab(),
            ],
          ),
        ),
      ],
    );
  }
}
