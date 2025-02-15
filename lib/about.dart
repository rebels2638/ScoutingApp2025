import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scouting App 2025',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Version 0.6.9-Beta',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),
          _buildSection(
            context,
            title: 'Update Notes',
            icon: Icons.update,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildUpdateNote('0.6.9-Beta', [
                  'Revamped UI for a modern look and improved usability.',
                  'Enhanced performance with faster load times.',
                  'Updated dependencies and improved security measures.',
                  'Fixed too many bugs with API page.',
                  'Bug fixes and minor improvements.',
                ]),
                const SizedBox(height: AppSpacing.md),
                _buildUpdateNote('0.6.8-Beta', [
                  'Reworked dark mode to be more consistent.',
                  'Overhauled team search functionality.',
                  'Improved QR code scanning for reliability.',
                  'Enhanced UI consistency.',
                ]),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          _buildSection(
            context,
            title: 'Credits',
            icon: Icons.people,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Developers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ethan Kang - Developer'),
                      Text('Chiming Wang - Developer'),
                      Text('Richard Xu - Developer'),
                    ],
                  ),
                ),
                
                Text(
                  'Special Thanks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 16),
                  child: Text(
                    'Thank you to all our mentors for their continuous support '
                    'and guidance throughout our robotics journey.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
                
                Text(
                  'Team Recognition',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'Thank you to all members of Team 2638 Rebel Robotics '
                    'for their support, testing, and feedback throughout '
                    'the development of this app.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildUpdateNote(String version, List<String> notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Version $version',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...notes.map((note) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(child: Text(note)),
            ],
          ),
        )),
      ],
    );
  }
}