import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../expansions/attune_track.dart';

/// Lists the masks on this device and can ask for a zip already saved here.
class AttunePackSheet extends StatelessWidget {
  const AttunePackSheet({
    super.key,
    required this.tracks,
    required this.selectedIndex,
    required this.onSelect,
    this.onAdd,
  });

  final List<AttuneTrack> tracks;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  /// Null on the web build, which has no expansion directory.
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Text(
                l10n.attunePickMusic,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: tracks.length,
                itemBuilder: (context, index) {
                  final track = tracks[index];
                  final showHeading = index == 0 ||
                      tracks[index - 1].packName != track.packName;
                  final selected = index == selectedIndex;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showHeading)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                          child: Text(
                            attunePackHeading(track, l10n).toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ListTile(
                        key: ValueKey<String>('attune-track-${track.id}'),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        selected: selected,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        title: Text(
                          attuneTrackTitle(track, l10n),
                          style: TextStyle(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : AppColors.textPrimary,
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                        trailing: selected
                            ? Icon(Icons.check_rounded,
                                color: Theme.of(context).colorScheme.primary)
                            : null,
                        onTap: () => onSelect(index),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (onAdd != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: TextButton.icon(
                  key: const Key('attune-add-pack'),
                  onPressed: onAdd,
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: Text(l10n.attuneAddPack),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
