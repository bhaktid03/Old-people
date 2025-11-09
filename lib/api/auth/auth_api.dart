import 'dart:async';

import '../client/api_client.dart';
import '../common/endpoints.dart';

class AuthApi {
	AuthApi({ApiClient? client}) : _client = client ?? ApiClient(enableLogging: true);

	final ApiClient _client;

	Future<void> sendOtp({required String phoneNumber}) async {
		final String normalizedPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
		final Map<String, dynamic> res = await _client.postJson(
			url: Endpoints.sendOtp(),
			body: <String, dynamic>{'phone': normalizedPhone},
		);
		if (res['ok'] != true) {
			throw Exception(res['error'] ?? 'Failed to send OTP');
		}
	}

  Future<Map<String, dynamic>> verifyOtp({
		required String phoneNumber,
		required String code,
		String? displayName,
	}) async {
		final String normalizedPhone = phoneNumber.replaceAll(RegExp(r'\s+'), '');
		final String normalizedCode = code.replaceAll(RegExp(r'\s+'), '');
		final Map<String, dynamic> payload = <String, dynamic>{
			'phone': normalizedPhone,
			'code': normalizedCode,
			if (displayName != null && displayName.isNotEmpty) 'displayName': displayName,
		};
    final Map<String, dynamic> res = await _client.postJson(
			url: Endpoints.verifyOtp(),
			body: payload,
		);
    return res;
	}
}

