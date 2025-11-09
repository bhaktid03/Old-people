import 'auth_api.dart';

class AuthRepository {
	AuthRepository({AuthApi? api}) : _api = api ?? AuthApi();

	final AuthApi _api;

	Future<void> sendOtp(String phoneNumber) => _api.sendOtp(phoneNumber: phoneNumber);

  Future<Map<String, dynamic>> verifyOtp(String phoneNumber, String code) =>
      _api.verifyOtp(phoneNumber: phoneNumber, code: code);
}

