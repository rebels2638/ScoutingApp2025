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
                    'FRC 2638 - Scouting App 2025',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Version 0.8.1-Beta',
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
                _buildUpdateNote('0.8.1-Beta', [
                  'Refined main scouting page.',
                  'Added edit match detail functionality.',
                  'Much improved data analytics features.',
                ]),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Warning: Data from version 0.7.6 and earlier is not compatible with version 0.8.0 and newer.',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                /*
                  _buildUpdateNote('0.8.1-Stable', [
                  'Updated scouting page to have more granular data input fields.',
                  'Added sorting to team analysis page.',
                  'Improved team analysis page UI',
                  'Added more metrics and analysis features to team analysis page.',
                ]),
                */
                /*
                const SizedBox(height: AppSpacing.md),
                _buildUpdateNote('0.7.6-Stable', [
                  'Decreased friction and improved UX for QR code scanning.',
                  'Added features in data and settings pages.',
                  'Fixed scouting page bug that allowed users to enter strings into an integer field.',
                  'Changed order for match data records to show newest first.',
                  'Added a refresh button to the match data page.',
                ]),
                
                const SizedBox(height: AppSpacing.md),
                _buildUpdateNote('0.7.5-Stable', [
                  'Added Bluetooth connectivity support with device scanning and management.',
                  'Fixed iOS and Android Bluetooth permissions and functionality.',
                  'Fixed taking a path photo with the camera.',
                  'Improved API page with refreshing data and limits.',
                  'Enhanced dark mode/light mode handling.',
                  'Added QR code export without drawing.',
                  'Added Team Data Visualization.',
                  'Fixed various bugs and improved stability.',
                ]),
                const SizedBox(height: AppSpacing.md),
                _buildUpdateNote('0.7.4-Beta', [
                  'Fixed major bugs and improved performance.',
                  'Enhanced record detail view.',
                  'Added new data team analysis features.',
                  'Added blue alliance API scraping.',
                  'Improved dark mode appearance.',
                ]),
                const SizedBox(height: AppSpacing.md),
                _buildUpdateNote('0.7.3-Beta', [
                  'Made record detail view more user-friendly.',
                  'Added more settings and customization options.',
                  'Implemented comprehensive data analysis tools.',
                  'Enhanced UI consistency and visual appeal.',
                ]),
                */
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
                      Text('Chiming Wang - Developer'),
                      Text('Richard Xu - Developer'),
                      Text('Ethan Kang - Developer'),
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
                    'Thank you to all our mentors for their continuous support and guidance through our robotics journey.',
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
                    'Thank you to all members of FRC Team 2638, Rebel Robotics, for their support, testing, and feedback throughout the development of this app.',
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