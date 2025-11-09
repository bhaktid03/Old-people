import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:newseva/features/headlines/presentation/news_home_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;
import '../controllers/app_ctrl.dart' as ctrl;
import '../widgets/button.dart' as buttons;

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext ctx) => Scaffold(

        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 30,
              children: [
                Image.asset(
                  'assets/sathi_logo.png',
                  width: 500,
                  height:500,
                ),
                Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    children: [
                      const TextSpan(
                        text:
                            'A friendly voice, always here to listen. Tap to talk with your companion, Saathi.',
                      ),
                      const TextSpan(text: '.'),
                    ],
                  ),
                ),
                Builder(
                  builder: (ctx) {
                    final isProgressing = [
                      ctrl.ConnectionState.connecting,
                      ctrl.ConnectionState.connected,
                    ].contains(ctx.watch<ctrl.AppCtrl>().connectionState);

                    return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isProgressing ? Colors.blue : Colors.blue, // ✅ Button color
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: buttons.Button(
                          text: isProgressing ? 'Connecting' : 'Start call',
                          isProgressing: isProgressing,
                          onPressed: () => ctx.read<ctrl.AppCtrl>().connect(),
                        ),
                      );

                  },
                ),
              ],
            ),
          ),
        ),
      );
}

