/// First-run onboarding for the dashboard runtime app.
///
/// Introduces the connect-to-VESC flow, then marks onboarding complete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';

class DashboardOnboarding extends ConsumerStatefulWidget {
  const DashboardOnboarding({super.key});

  @override
  ConsumerState<DashboardOnboarding> createState() =>
      _DashboardOnboardingState();
}

class _DashboardOnboardingState extends ConsumerState<DashboardOnboarding> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <_OnboardPage>[
    _OnboardPage(
      icon: Icons.electric_moped,
      title: 'Veschub Dashboard',
      body: 'Render the dashboards you built in Studio, live against your '
          'VESC controller over BLE or USB.',
    ),
    _OnboardPage(
      icon: Icons.bluetooth,
      title: 'Connect your VESC',
      body: 'The viewer currently runs against a built-in simulator so you '
          'can explore immediately. Real BLE/USB connectivity is coming soon.',
    ),
    _OnboardPage(
      icon: Icons.play_circle,
      title: 'Ready to ride',
      body: 'The viewer loads a sample dashboard wired to a simulated VESC. '
          'Open the folder icon in the toolbar to load dashboards you saved '
          'from Studio.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsServiceProvider).markOnboardingDone();
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (var i = 0; i < _pages.length; i++)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_pages[i].icon, size: 72),
                          const SizedBox(height: 24),
                          Text(_pages[i].title,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          Text(_pages[i].body,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(onPressed: _finish, child: const Text('Skip')),
                  FilledButton(
                    onPressed: isLast
                        ? _finish
                        : () => _controller.nextPage(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                            ),
                    child: Text(isLast ? 'Get started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final String title;
  final String body;
  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.body,
  });
}
