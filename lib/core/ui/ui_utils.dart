import 'package:flutter/material.dart';
import 'dart:io';

class UiUtils {
  const UiUtils._();

  static String friendlyErrorMessage(Object error) {
    if (error is HttpException) return error.message;
    return error.toString();
  }

  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    bool hasBottomNavigationBar = false,
  }) {
    final double bottomMargin = hasBottomNavigationBar
        ? 20 + MediaQuery.of(context).padding.bottom
        : 50;

    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor ?? Theme.of(context).primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.only(
            left: 10,
            right: 10,
            bottom: bottomMargin,
          ),
        ),
      );
  }

  static void showTopSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    bool isWarning = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    _showCustomTopSnackBar(
      context: context,
      message: message,
      isError: isError,
      isWarning: isWarning,
      isSuccess: isSuccess,
      duration: duration,
    );
  }

  static void _showCustomTopSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    bool isWarning = false,
    bool isSuccess = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    const Color successColor = Color.fromRGBO(21, 133, 49, 1);
    const Color successBackgroundColor = Color.fromRGBO(235, 249, 238, 1);

    final OverlayState? overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      // Fallback to a regular SnackBar if no Overlay is available in this context
      showSnackBar(
        context,
        message,
        backgroundColor: isError
            ? Colors.red
            : isWarning
                ? Colors.orange
                : isSuccess
                    ? const Color.fromRGBO(21, 133, 49, 1)
                    : Theme.of(context).primaryColor,
      );
      return;
    }

    final Color fgColor = isError
        ? Colors.red
        : isWarning
            ? Colors.orange
            : isSuccess
                ? successColor
                : Colors.black;

    final Color bgColor = isError
        ? Colors.red.shade50
        : isWarning
            ? Colors.orange.shade50
            : isSuccess
                ? successBackgroundColor
                : Colors.black;

    final Color borderColor = isError
        ? Colors.red.shade100
        : isWarning
            ? Colors.orange.shade100
            : isSuccess
                ? successBackgroundColor
                : Colors.black;

    final double topInset = MediaQuery.of(context).padding.top;
    final double topPosition = topInset + 20;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPosition,
        right: 0,
        left: MediaQuery.of(context).size.width / 3,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(10),
                  ),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      isError
                          ? Icons.error
                          : isWarning
                              ? Icons.error
                              : Icons.check,
                      color: fgColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: fgColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}


