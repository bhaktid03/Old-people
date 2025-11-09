import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/app_ctrl.dart';
import '../widgets/app_layout_switcher.dart';
import '../screens/welcome_screen.dart';
import '../screens/agent_screen.dart';

class VoiceAssistantWrapper extends StatelessWidget {
  const VoiceAssistantWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final appCtrl = AppCtrl();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appCtrl),
        ChangeNotifierProvider.value(value: appCtrl.roomContext),
      ],
      child: Builder(
        builder: (ctx) {
          final screen = ctx.watch<AppCtrl>().appScreenState;

          return Scaffold(
            appBar: AppBar(
              
              backgroundColor: const Color.fromARGB(0, 255, 255, 255),
              elevation: 0,
            ),
            body: AppLayoutSwitcher(
              isFront: screen == AppScreenState.welcome,
              frontBuilder: (_) => const WelcomeScreen(),
              backBuilder: (_) => const AgentScreen(),
            ),
          );
        },
      ),
    );
  }
}
