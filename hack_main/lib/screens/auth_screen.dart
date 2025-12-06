import 'package:flutter/material.dart';
import 'package:teste/services/auth_service.dart';
import 'package:teste/screens/profile_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  
  Future<void> _checkAuthStatus() async {
    try {
      final isAuthenticated = await _authService.isAuthenticated();
      if (isAuthenticated && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(key: UniqueKey()),
          ),
          (route) => false,
        );
      }
    } catch (e) {
    }
  }

  
  Future<void> _handleAuthenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authService.authenticate();
      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => ProfileScreen(key: UniqueKey()),
          ),
          (route) => false,
        );
      } else {
        _setError('Ошибка при аунтетификации. Попробуйте еще раз.');
      }
    } catch (e) {
      _setError('Authentication error: ${e.toString()}');
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
    backgroundColor: Color.fromARGB(255, 13, 13, 27),
    body: SafeArea(
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
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
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                          
                          "PROD",
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w300,
                          ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Войдите в аккаунт',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            color: const Color.fromARGB(255, 255, 255, 255),
                            fontFamily: 'Gilroy',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          
               
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[900]?.withOpacity(0.2),
                      border: Border.all(color: Colors.red[800]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red[300],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red[300],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _errorMessage = null),
                          child: Icon(
                            Icons.close,
                            color: Colors.red[300],
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
          
              
                if (_isLoading)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Аутентификация...',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontFamily: 'Gilroy'
                          ),
                        ),
                      ],
                    ),
                  ),
          
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleAuthenticate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 56, 44, 88),
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: const Color.fromARGB(255, 63, 62, 88),
                            disabledForegroundColor: Colors.grey[600],
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                              
                            ),
                          ),
                          child: const Text(
                            'Войти',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 3), 
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
