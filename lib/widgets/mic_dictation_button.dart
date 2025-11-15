import 'package:flutter/material.dart';
import '../app/theme/colors.dart';
import '../app/theme/spacing.dart';

enum _MicState { idle, listening, processing }

class MicDictationButton extends StatefulWidget {
  const MicDictationButton({
    super.key,
    required this.controller,
    this.onResult,
    this.size = 48,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onResult;
  final double size;

  @override
  State<MicDictationButton> createState() => _MicDictationButtonState();
}

class _MicDictationButtonState extends State<MicDictationButton>
    with SingleTickerProviderStateMixin {
  _MicState _state = _MicState.idle;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.95,
      upperBound: 1.05,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    if (_state != _MicState.idle) return;
    setState(() {
      _state = _MicState.listening;
    });
    _pulseController.repeat(reverse: true);

    // Mock listening -> processing -> result flow
    await Future<void>.delayed(const Duration(seconds: 2));
    setState(() {
      _state = _MicState.processing;
    });
    _pulseController.stop();

    await Future<void>.delayed(const Duration(milliseconds: 800));

    const String mockTranscript = ' Hello, this is a test.';
    final selection = widget.controller.selection;
    final baseText = widget.controller.text;
    if (selection.isValid) {
      final start = selection.start;
      final end = selection.end;
      final updated = baseText.replaceRange(start, end, mockTranscript);
      widget.controller.text = updated;
      widget.controller.selection = TextSelection.collapsed(
        offset: start + mockTranscript.length,
      );
    } else {
      widget.controller.text = baseText + mockTranscript;
      widget.controller.selection = TextSelection.collapsed(
        offset: widget.controller.text.length,
      );
    }
    widget.onResult?.call(mockTranscript);

    setState(() {
      _state = _MicState.idle;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double dim = widget.size;
    final bool isListening = _state == _MicState.listening;
    final bool isProcessing = _state == _MicState.processing;

    Widget content;
    if (isProcessing) {
      content = const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    } else {
      content = Icon(
        isListening ? Icons.mic : Icons.mic_none,
        color: Colors.white,
      );
    }

    final Color bg = isProcessing
        ? AppColors.brandDark
        : (isListening ? AppColors.brand : AppColors.textPrimary);

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: dim,
      height: dim,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Center(child: content),
    );

    return Semantics(
      button: true,
      label: _state == _MicState.idle
          ? 'Start dictation'
          : (_state == _MicState.listening ? 'Listening' : 'Processing'),
      child: GestureDetector(
        onTap: _onTap,
        child: isListening
            ? ScaleTransition(
                scale: _pulseController,
                child: button,
              )
            : button,
      ),
    );
  }
}


