import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', width: 96, height: 96),
                const SizedBox(height: 16),
                Text(
                  'Sinclear Beyond',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Deine intelligente Plattform',
                  style: TextStyle(
                    fontSize: 22,
                    color: theme.textTheme.textStyle.color?.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Willkommen bei Sinclear Beyond – deiner neuen '
                  'digitalen Lösung für mehr Übersicht und Effizienz. '
                  'Wir sind noch im Aufbau, aber bald kannst du hier '
                  'auf all deine Daten zugreifen und sie verwalten.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.textTheme.textStyle.color?.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                CupertinoButton.filled(
                  onPressed: () => context.go('/login'),
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  child: const Text('Zum Login', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
