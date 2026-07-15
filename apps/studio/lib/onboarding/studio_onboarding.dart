/// First-run onboarding for the studio.
///
/// Shown when `settings.onboardingDone` is false. Walks the user through the
/// three editing modes (Template / Canvas / Flow) and the capability concept,
/// then marks onboarding complete and hands off to the editor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:settings/settings.dart';

class StudioOnboarding extends ConsumerStatefulWidget {
  const StudioOnboarding({super.key});

  @override
  ConsumerState<StudioOnboarding> createState() => _StudioOnboardingState();
}

class _StudioOnboardingState extends ConsumerState<StudioOnboarding> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <_OnboardPage>[
    _OnboardPage(
      icon: Icons.dashboard_customize,
      title: 'Welcome to Veschub Studio',
      body: 'Build dashboards for your VESC controller and render them live '
          'on any device. What you author here is exactly what renders.',
    ),
    _OnboardPage(
      icon: Icons.tune,
      title: 'Three editing modes',
      body: 'Template: pick a starter and tweak colours and limits. '
          'Canvas: drag-drop widgets and bind them to telemetry. '
          'Flow: wire telemetry through a node graph for full control.',
    ),
    _OnboardPage(
      icon: Icons.speed,
      title: 'Capability levels',
      body: 'Basic, Advanced and Expert progressively reveal properties and '
          'tools. Switch any time from the toolbar — the editor adapts.',
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
                  for (final p in _pages)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(p.icon, size: 72),
                          const SizedBox(height: 24),
                          Text(p.title,
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          Text(p.body,
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
                  TextButton(
                    onPressed: _finish,
                    child: const Text('Skip'),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _pages.length; i++)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _page
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
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
