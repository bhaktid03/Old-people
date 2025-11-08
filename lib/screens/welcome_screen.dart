import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;
import '../controllers/app_ctrl.dart' as ctrl;
import '../widgets/button.dart' as buttons;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext ctx) => Material(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 30,
              children: [
                Image.asset(
                  'assets/sathi_logo.png',
                  width: 400,
                  height: 400,
                  // color: Theme.brightnessOf(ctx) == Brightness.light ? Colors.black : Colors.white,
                ),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'A friendly voice, always here to listen.Tap to talk with your companion, Saathi.',
                      ),
        
                      const TextSpan(
                        text: '.',
                      ),
                    ],
                  ),
                ),
                Builder(
                  builder: (ctx) {
                    final isProgressing = [
                      ctrl.ConnectionState.connecting,
                      ctrl.ConnectionState.connected,
                    ].contains(ctx.watch<ctrl.AppCtrl>().connectionState);
                    return buttons.Button(
                      text: isProgressing ? 'Connecting' : 'Start call',
                      isProgressing: isProgressing,
                      onPressed: () => ctx.read<ctrl.AppCtrl>().connect(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
}
