// lib/app/controllers/simple_auth_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Simple AuthController for basic functionality
class SimpleAuthController extends GetxController {
  final _isAuthenticated = false.obs;
  final _isLoading = false.obs;

  // Form controllers and keys
  final loginFormKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool get isAuthenticated => _isAuthenticated.value;
  bool get isLoading => _isLoading.value;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  /// Check if user is authenticated (placeholder)
  Future<bool> checkAuthStatus() async {
    _isLoading.value = true;
    
    try {
      // Placeholder implementation
      await Future.delayed(const Duration(milliseconds: 500));
      _isAuthenticated.value = false; // Always false for now
      return _isAuthenticated.value;
    } catch (e) {
      print('Error checking auth status: $e');
      _isAuthenticated.value = false;
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Login method using form controllers
  Future<void> login() async {
    if (!loginFormKey.currentState!.validate()) return;
    
    _isLoading.value = true;
    
    try {
      // Placeholder implementation
      await Future.delayed(const Duration(seconds: 1));
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      
      print('Login attempt: $email with password length: ${password.length}');
      
      // For demo purposes, accept any email/password
      _isAuthenticated.value = true;
      
      Get.snackbar(
        'Login Exitoso',
        'Bienvenido a Baudex Desktop',
        duration: const Duration(seconds: 2),
      );
      
      // Navigate to dashboard or home
      Get.offAllNamed('/dashboard');
    } catch (e) {
      print('Login error: $e');
      Get.snackbar(
        'Error de Login',
        'No se pudo iniciar sesión: $e',
        duration: const Duration(seconds: 3),
      );
    } finally {
      _isLoading.value = false;
    }
  }
  
  /// Login method with parameters (backward compatibility)
  Future<bool> loginWithCredentials(String email, String password) async {
    emailController.text = email;
    passwordController.text = password;
    await login();
    return _isAuthenticated.value;
  }

  /// Logout method
  Future<void> logout() async {
    _isLoading.value = true;
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      _isAuthenticated.value = false;
      
      Get.snackbar(
        'Sesión Cerrada',
        'Has cerrado sesión exitosamente',
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('Logout error: $e');
    } finally {
      _isLoading.value = false;
    }
  }

  /// Get current user info (placeholder)
  Map<String, dynamic>? getCurrentUser() {
    if (!_isAuthenticated.value) return null;
    
    return {
      'id': '1',
      'name': 'Usuario Demo',
      'email': 'demo@baudex.com',
      'role': 'admin',
    };
  }
}

// Type alias for backward compatibility
typedef AuthController = SimpleAuthController;