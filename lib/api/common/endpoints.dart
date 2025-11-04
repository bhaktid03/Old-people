// Centralized API endpoints and base URL configuration
// Update `apiBaseUrl` to point to your backend.

/// Base URL for the API. Keep this as a single source of truth.
/// Example: https://api.example.com
String apiBaseUrl = 'http://10.19.1.115:4000';

/// Helpers for building endpoint URLs from the base.
class Endpoints {
  static String sendOtp() => '$apiBaseUrl/auth/otp/send';
  static String verifyOtp() => '$apiBaseUrl/auth/otp/verify';
}
