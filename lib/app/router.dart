import 'package:flutter/material.dart';
import 'dart:io';
import 'home_shell.dart';
import '../api/auth/auth_repository.dart';
import '../features/auth/presentation/phone_login_screen.dart';
import '../features/auth/presentation/otp_verify_screen.dart';
import '../core/ui/ui_utils.dart';
import '../features/profile/presentation/profile_setup_screen.dart';

final appRouter = RouterConfig<Object>(
	routerDelegate: _AppRouterDelegate(),
	routeInformationParser: _AppRouteInformationParser(),
	routeInformationProvider: PlatformRouteInformationProvider(
		initialRouteInformation: const RouteInformation(location: '/'),
	),
);

class _AppRouterDelegate extends RouterDelegate<Object>
		with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
	final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

	final AuthRepository _authRepository = AuthRepository();
	final ValueNotifier<bool> _isAuthenticated = ValueNotifier<bool>(false);
	String? _phoneNumber;
	bool _awaitingOtp = false;
	bool _needsProfileSetup = false;
	String? _prefillDisplayName;

  Future<void> _onPhoneSubmitted(String phone) async {
		final BuildContext? ctx = navigatorKey.currentContext;
		try {
			await _authRepository.sendOtp(phone);
      if (ctx != null) {
        UiUtils.showTopSnackBar(context: ctx, message: 'OTP sent', isSuccess: true);
      }
			_phoneNumber = phone;
			_awaitingOtp = true;
			notifyListeners();
		} catch (e) {
      if (ctx != null) {
        UiUtils.showTopSnackBar(
          context: ctx,
          message: UiUtils.friendlyErrorMessage(e),
          isError: true,
        );
      }
		}
	}

	void _onOtpVerified(String? displayName) {
		// After OTP, show profile setup screen and prefill display name if provided
		_prefillDisplayName = displayName;
		_needsProfileSetup = true;
		_awaitingOtp = false;
		notifyListeners();
	}

	void _onProfileSkip() {
		_needsProfileSetup = false;
		_isAuthenticated.value = true;
		notifyListeners();
	}

	void _onProfileContinue({required String displayName}) {
		// Persist displayName if needed in future; for now proceed to home
		_needsProfileSetup = false;
		_isAuthenticated.value = true;
		notifyListeners();
	}

	void _onEditPhone() {
		_awaitingOtp = false;
		notifyListeners();
	}

	@override
	Widget build(BuildContext context) {
		return Navigator(
			key: navigatorKey,
			pages: <Page<dynamic>>[
				if (!_isAuthenticated.value && !_awaitingOtp)
					MaterialPage(
						child: PhoneLoginScreen(onSubmitPhone: _onPhoneSubmitted),
					),
			if (!_isAuthenticated.value && _awaitingOtp)
					MaterialPage(
					child: OtpVerifyScreen(
							phoneNumber: _phoneNumber ?? '',
							onEditPhone: _onEditPhone,
							onVerified: _onOtpVerified,
							authRepository: _authRepository,
						),
					),
			if (!_isAuthenticated.value && _needsProfileSetup)
				MaterialPage(
					child: ProfileSetupScreen(
						onSkip: _onProfileSkip,
						onContinue: ({required String displayName, File? photoFile}) {
							_onProfileContinue(displayName: displayName);
						},
						initialDisplayName: _prefillDisplayName,
					),
				),
				if (_isAuthenticated.value)
					const MaterialPage(child: HomeShell()),
			],
			onPopPage: (route, result) => route.didPop(result),
		);
	}

	@override
	Future<void> setNewRoutePath(configuration) async {}
}

class _AppRouteInformationParser
    extends RouteInformationParser<Object> {
  @override
  Future<Object> parseRouteInformation(RouteInformation routeInformation) async {
    return routeInformation.location ?? '/';
  }
}


