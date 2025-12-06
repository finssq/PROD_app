import 'package:flutter/material.dart';
import 'package:teste/screens/auth_screen.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PROD',
      navigatorObservers: [routeObserver], 
      theme: ThemeData(
        fontFamily: 'Gilroy',
        useMaterial3: true,
        scaffoldBackgroundColor: Color.fromRGBO(37, 22, 53, 1),
        colorScheme: const ColorScheme.dark(
          //primary: Color.fromRGBO(78, 75, 134, 1),
          //secondary: Color.fromRGBO(13, 13, 27, 1),
          //surface: Color.fromRGBO(78, 75, 134, 1),
          //onPrimary: Color.fromRGBO(78, 75, 134, 1),
          //onSecondary:  Color.fromRGBO(13, 13, 27, 1),
          //onSurface:Color.fromRGBO(78, 75, 134, 1),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'Gilroy',
            fontSize: 48,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.5,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromRGBO(26, 25, 29, 1),
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor:Color.fromRGBO(195, 194, 230, 1),
            side: const BorderSide(color: Color.fromRGBO(195, 194, 230, 1)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50),
            ),
          ),
        ),
      ),
      home: const AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
