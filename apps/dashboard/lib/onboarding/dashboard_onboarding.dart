/// First-run onboarding for the dashboard runtime app.
///
/// Introduces the connect-to-VESC flow and the transport preference, then
/// marks onboarding complete.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:settings/settings.dart';

import '../providers/settings_provider.dart';

class DashboardOnboarding extends ConsumerStatefulWidget {
  final VoidCallback onDone;
  const DashboardOnboarding({required this.onDone, super.key});

  @override
  ConsumerState<DashboardOnboarding> createState() =>
      _DashboardOnboardingState();
}

class _DashboardOnboardingState extends ConsumerState<DashboardOnboarding> {
  final _controller = PageController();
  int _page = 0;
  TransportPreference _transport = TransportPreference.auto;

  static const _pages = <_OnboardPage>[
    _OnboardPage(
      icon: Icons.electric_scooter,
      title: 'Veschub Dashboard',
      body: 'Render the dashboards you built in Studio, live against your '
          'VESC controller over BLE or USB.',
    ),
    _OnboardPage(
      icon: Icons.bluetooth,
      title: 'Connect your VESC',
      body: 'Pick how the runtime talks to your controller. You can change '
          'this later in Settings.',
    ),
    _OnboardPage(
      icon: Icons.play_circle,
      title: 'Ready to ride',
      body: 'The viewer loads a sample dashboard wired to a simulated VESC '
          'so you can explore immediately. Connect real hardware from the '
          'toolbar.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final settings = ref.read(settingsServiceProvider);
    await settings.setTransport(_transport);
    await settings.markOnboardingDone();
    widget.onDone();
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
                          if (i == 1) ...[
                            const SizedBox(height: 24),
                            Wrap(
                              spacing: 8,
                              children: TransportPreference.values.map((t) {
                                return ChoiceChip(
                                  label: Text(_transportLabel(t)),
                                  selected: _transport == t,
                                  onSelected: (_) =>
                                      setState(() => _transport = t),
                                );
                              }).toList(),
                            ),
                          ],
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

  String _transportLabel(TransportPreference t) => switch (t) {
        TransportPreference.ble => 'BLE',
        TransportPreference.usb => 'USB',
        TransportPreference.auto => 'Auto',
      };
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
