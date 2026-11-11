import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_theme.dart';

class _CrisisLine {
  final String country;
  final String name;
  final String number;
  final String? web;

  const _CrisisLine({
    required this.country,
    required this.name,
    required this.number,
    this.web,
  });
}

const _lines = [
  _CrisisLine(
    country: 'Malta',
    name: 'Supportline',
    number: '179',
    web: 'supportline.org.mt',
  ),
  _CrisisLine(
    country: 'Malta',
    name: 'Mental Health Support — Agenzija Sapport',
    number: '2590 0000',
  ),
  _CrisisLine(
    country: 'International',
    name: 'International Association for Suicide Prevention',
    number: '',
    web: 'https://www.iasp.info/resources/Crisis_Centres',
  ),
  _CrisisLine(
    country: 'UK',
    name: 'Samaritans',
    number: '116 123',
    web: 'samaritans.org',
  ),
  _CrisisLine(
    country: 'US',
    name: '988 Suicide & Crisis Lifeline',
    number: '988',
    web: 'samhsa.gov/find-help/988',
  ),
  _CrisisLine(
    country: 'EU',
    name: 'European Emergency Number',
    number: '112',
  ),
];

class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Group by country
    final grouped = <String, List<_CrisisLine>>{};
    for (final line in _lines) {
      grouped.putIfAbsent(line.country, () => []).add(line);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Crisis resources')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
          children: [
            // Top message — calm, not clinical
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'If you are in immediate danger, please call emergency services.\n\n'
                'You do not have to go through this alone. '
                'Real humans are on the other end of these lines.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: 28),

            for (final country in grouped.keys) ...[
              _CountryHeader(country),
              const SizedBox(height: 10),
              for (final line in grouped[country]!) ...[
                _CrisisCard(line: line),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
            ],

            // Bottom note
            const Text(
              'If your country is not listed, search "[your country] mental health crisis line" '
              'or go to the International Association for Suicide Prevention link above.',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountryHeader extends StatelessWidget {
  final String country;
  const _CountryHeader(this.country);

  @override
  Widget build(BuildContext context) {
    return Text(
      country.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
      ),
    );
  }
}

class _CrisisCard extends StatelessWidget {
  final _CrisisLine line;
  const _CrisisCard({required this.line});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line.name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (line.number.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: line.number));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Number copied'),
                    backgroundColor: AppColors.surface,
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_rounded,
                        color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      line.number,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (line.web != null) ...[
            const SizedBox(height: 6),
            Text(
              line.web!,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
