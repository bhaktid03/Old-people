import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../../../api/auth/auth_repository.dart';
import '../../../core/ui/ui_utils.dart';
import '../../../app/theme/colors.dart';

class OtpVerifyScreen extends StatefulWidget {
	const OtpVerifyScreen({
		super.key,
		required this.phoneNumber,
		required this.onVerified,
		required this.onEditPhone,
		required this.authRepository,
	});

	final String phoneNumber;
	final void Function(String? displayName) onVerified;
	final VoidCallback onEditPhone;
	final AuthRepository authRepository;

	@override
	State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
	final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
	final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
	bool _verifying = false;
	String? _error;
	int _secondsLeft = 30;
	Timer? _timer;

	String get _timerText {
		final min = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
		final sec = (_secondsLeft % 60).toString().padLeft(2, '0');
		return '$min:$sec';
	}

	@override
	void dispose() {
		for (final c in _controllers) {
			c.dispose();
		}
		for (final f in _focusNodes) {
			f.dispose();
		}
		_timer?.cancel();
		super.dispose();
	}

	@override
	void initState() {
		super.initState();
		_timer = Timer.periodic(const Duration(seconds: 1), (t) {
			if (!mounted) return;
			setState(() {
				if (_secondsLeft > 0) {
					_secondsLeft--;
				}
			});
		});
	}

	Future<void> _verify() async {
		final code = _controllers.map((c) => c.text).join();
		if (code.length != 6) {
			setState(() => _error = 'Enter 6-digit code');
			return;
		}
		setState(() {
			_verifying = true;
			_error = null;
		});
		try {
			final res = await widget.authRepository.verifyOtp(widget.phoneNumber, code);
			if (!mounted) return;
			if (res['ok'] == true) {
				final String? displayName = (res['user'] is Map<String, dynamic>)
					? (res['user']['displayName'] as String?)
					: null;
				UiUtils.showTopSnackBar(context: context, message: 'OTP verified', isSuccess: true);
				widget.onVerified(displayName);
			} else {
				setState(() {
					_verifying = false;
					_error = 'Invalid code, try again';
				});
				UiUtils.showTopSnackBar(context: context, message: 'Invalid code, try again', isError: true);
			}
		} catch (e) {
			if (!mounted) return;
			setState(() {
				_verifying = false;
				_error = 'Verification failed';
			});
			UiUtils.showTopSnackBar(context: context, message: e.toString(), isError: true);
		}
	}

	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final size = MediaQuery.of(context).size;
		final padding = MediaQuery.of(context).padding;
		final screenHeight = size.height - padding.top - padding.bottom;
		final screenWidth = size.width;
		return Scaffold(
			appBar: AppBar(
				title: const Text('Chaupal'),
				centerTitle: true,
				leading: IconButton(
					icon: const Icon(Icons.arrow_back),
					onPressed: _verifying ? null : widget.onEditPhone,
				),
			),
			body: SafeArea(
				child: Column(
					children: [
						Expanded(
							child: Center(
								child: Padding(
									padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
									child: Column(
										mainAxisAlignment: MainAxisAlignment.center,
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												'Verification code',
												style: TextStyle(
													fontSize: screenHeight * 0.022,
													fontWeight: FontWeight.w600,
													color: AppColors.textPrimary,
												),
											),
											const SizedBox(height: 8),
											Text(
												"Enter the verification code we've sent to your number.",
												style: TextStyle(
													fontSize: screenHeight * 0.016,
													fontWeight: FontWeight.w400,
													color: AppColors.textPrimary,
													height: 22 / 12,
												),
											),
											const SizedBox(height: 8),
											Container(width: double.infinity, height: 1, color: const Color(0xFFFFF3E9)),
											SizedBox(height: screenHeight * 0.02),
											Row(
												mainAxisAlignment: MainAxisAlignment.center,
												children: List.generate(6, (index) {
													final isFilled = _controllers[index].text.isNotEmpty;
													return Container(
														width: screenWidth * 0.11,
														margin: const EdgeInsets.symmetric(horizontal: 6),
														decoration: BoxDecoration(
															gradient: isFilled
																? const LinearGradient(colors: [AppColors.brand, AppColors.brandDark])
																: null,
															color: isFilled ? null : const Color(0xFFF3F0FF),
															borderRadius: BorderRadius.circular(12),
														),
														child: Focus(
															onKey: (node, event) {
															if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
																if (_controllers[index].text.isEmpty && index > 0) {
																	setState(() {
																		_controllers[index - 1].clear();
																		_focusNodes[index - 1].requestFocus();
																	});
																	return KeyEventResult.handled;
																}
															}
															return KeyEventResult.ignored;
														},
															child: TextField(
																controller: _controllers[index],
																focusNode: _focusNodes[index],
																keyboardType: TextInputType.number,
																textAlign: TextAlign.center,
																maxLength: 1,
																style: TextStyle(
																	fontWeight: FontWeight.w600,
																	fontSize: screenHeight * 0.028,
																	color: isFilled ? Colors.white : AppColors.textPrimary,
																),
																decoration: const InputDecoration(counterText: '', border: InputBorder.none),
																onChanged: (v) {
																	setState(() => _error = null);
																	if (v.isNotEmpty && index < 5) {
																		_focusNodes[index + 1].requestFocus();
																	}
																	if (v.isEmpty && index > 0) {
																		_focusNodes[index - 1].requestFocus();
																	}
																},
															),
														),
													);
												}),
											),
											if (_error != null) ...[
												const SizedBox(height: 8),
												Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
											],
											SizedBox(height: screenHeight * 0.04),
											Center(
												child: Column(
													children: [
														Text(
															_secondsLeft > 0 ? 'Resend available in $_timerText' : "Didn't receive the code?",
															style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
															textAlign: TextAlign.center,
														),
														TextButton(
															onPressed: (_secondsLeft == 0 && !_verifying)
																? () {
																	setState(() {
																		_secondsLeft = 30;
																	});
																			}
																			: null,
															child: const Text('Resend'),
														),
																],
															),
														),
									],
									),
								),
						),
									),
						Padding(
							padding: EdgeInsets.all(screenWidth * 0.06),
							child: SizedBox(
								width: double.infinity,
								height: screenHeight * 0.06,
								child: InkWell(
									onTap: _verifying ? null : _verify,
									borderRadius: BorderRadius.circular(12),
									child: Container(
										decoration: BoxDecoration(
											borderRadius: BorderRadius.circular(12),
											gradient: const LinearGradient(colors: [AppColors.brand, AppColors.brandDark]),
										),
										child: Center(
											child: _verifying
												? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
												: Text(
													'Confirm',
													style: TextStyle(
														color: Colors.white,
														fontSize: screenHeight * 0.022,
														fontWeight: FontWeight.w600,
													),
											),
										),
									),
								),
							),
						),
					],
				),
			),
		);
	}
}


