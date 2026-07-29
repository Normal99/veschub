library;

import 'package:flutter/material.dart';
import 'package:dashboard_runtime/dashboard_runtime.dart';
import '../src/cosmetic_helpers.dart';

class MusicWidget extends StatelessWidget {
  final ResolvedProperties properties;
  const MusicWidget({required this.properties, super.key});

  @override
  Widget build(BuildContext context) {
    final title = properties['title'] as String? ?? 'No Track';
    final artist = properties['artist'] as String? ?? 'Unknown Artist';
    final color = Color((properties['color'] as int?) ?? 0xFFFFFFFF);
    final accent = Color((properties['accent'] as int?) ?? 0xFF888888);
    final progress = (properties['progress'] as num?)?.toDouble() ?? 0.0;
    final duration = (properties['duration'] as num?)?.toDouble() ?? 0.0;
    final showControls = properties['showControls'] as bool? ?? true;
    final albumColor = Color((properties['albumColor'] as int?) ?? 0xFF333333);

    return applyOpacity(
      Container(
        decoration: resolveBoxDecoration(properties),
        child: Padding(
          padding: resolvePadding(properties),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: albumColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.music_note, color: Colors.white54, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: applyTextStyle(
                        TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
                        properties,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artist,
                      style: TextStyle(color: accent, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (duration > 0) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: duration > 0 ? (progress / duration).clamp(0.0, 1.0) : 0,
                          backgroundColor: accent.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_fmtTime(progress), style: TextStyle(color: accent, fontSize: 10)),
                          Text(_fmtTime(duration), style: TextStyle(color: accent, fontSize: 10)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (showControls)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.skip_previous, color: color, size: 20),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    IconButton(
                      icon: Icon(Icons.play_arrow, color: color, size: 24),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: Icon(Icons.skip_next, color: color, size: 20),
                      onPressed: () {},
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      properties,
    );
  }

  String _fmtTime(double seconds) {
    final m = (seconds ~/ 60).toInt();
    final s = (seconds % 60).toInt();
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
