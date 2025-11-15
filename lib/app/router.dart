import 'package:flutter/material.dart';
import 'dart:io';
import 'home_shell.dart';
import '../api/auth/auth_repository.dart';
import '../features/auth/presentation/phone_login_screen.dart';
import '../features/auth/presentation/otp_verify_screen.dart';
import '../core/ui/ui_utils.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../core/session/session_manager.dart';

final _routerDelegate = _AppRouterDelegate();

final appRouter = RouterConfig<Object>(
	routerDelegate: _routerDelegate,
	routeInformationParser: _AppRouteInformationParser(),
	routeInformationProvider: PlatformRouteInformationProvider(
		initialRouteInformation: const RouteInformation(location: '/'),
	),
);

// Expose router delegate for logout/delete account functionality
_AppRouterDelegate get routerDelegate => _routerDelegate;

class _AppRouterDelegate extends RouterDelegate<Object>
		with ChangeNotifier, PopNavigatorRouterDelegateMixin<Object> {
	final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

	final AuthRepository _authRepository = AuthRepository();
	final SessionManager _session = SessionManager();
	final ValueNotifier<bool> _isAuthenticated = ValueNotifier<bool>(false);
	String? _phoneNumber;
	bool _awaitingOtp = false;
	bool _needsProfileSetup = false;
	String? _prefillDisplayName;

	_AppRouterDelegate() {
		_initialize();
		// Listen to authentication state changes and notify listeners
		_isAuthenticated.addListener(() {
			notifyListeners();
		});
	}

	@override
	void dispose() {
		_isAuthenticated.dispose();
		super.dispose();
	}

	Future<void> _initialize() async {
		await _session.init();
		if (_session.userId != null) {
			_isAuthenticated.value = true;
			notifyListeners();
		}
	}

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

	void _onOtpVerified({String? displayName, String? userId}) {
		// Save session immediately
		if (userId != null && userId.isNotEmpty) {
			_session.saveUser(userId: userId, displayName: displayName);
		}
		_prefillDisplayName = displayName;
		_awaitingOtp = false;
		// If display name exists, skip profile setup and go home
		if (displayName != null && displayName.isNotEmpty) {
			_isAuthenticated.value = true;
			_needsProfileSetup = false;
		} else {
			_needsProfileSetup = true;
		}
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

	/// Logout user - clears session and redirects to sign up page
	Future<void> logout() async {
		await _session.clear();
		// Reset all state
		_awaitingOtp = false;
		_needsProfileSetup = false;
		_phoneNumber = null;
		_prefillDisplayName = null;
		// Set authentication to false - this will trigger the ValueNotifier listener
		// which calls notifyListeners(), causing the router to rebuild
		_isAuthenticated.value = false;
		// Also call notifyListeners() directly to ensure immediate rebuild
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