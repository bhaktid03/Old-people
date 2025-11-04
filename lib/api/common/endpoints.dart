// Centralized API endpoints and base URL configuration
// Update `apiBaseUrl` to point to your backend.

/// Base URL for the API. Keep this as a single source of truth.
/// Example: https://api.example.com
String apiBaseUrl = 'https://05dd4682846e.ngrok-free.app';

/// Helpers for building endpoint URLs from the base.
class Endpoints {
  static String sendOtp() => '$apiBaseUrl/auth/otp/send';
  static String verifyOtp() => '$apiBaseUrl/auth/otp/verify';
}
