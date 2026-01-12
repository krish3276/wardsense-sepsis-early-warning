/// Home screen - Role selection and app entry point
///
/// Allows users to select their role (Nurse/Doctor) which determines
/// the appropriate dashboard view.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../nurse/nurse_dashboard_screen.dart';
import '../doctor/doctor_dashboard_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo and title
                _buildHeader(context),

                const SizedBox(height: 48),

                // Role selection cards
                _buildRoleSelection(context, ref),

                const SizedBox(height: 48),

                // Footer with version
                _buildFooter(context, ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // App icon
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.monitor_heart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
        ).animate().fadeIn(duration: 400.ms).scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1, 1),
              duration: 400.ms,
            ),

        const SizedBox(height: 24),

        // App name
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 8),

        // Tagline
        Text(
          AppConstants.appTagline,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildRoleSelection(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text(
          'Select Your Role',
          style: Theme.of(context).textTheme.titleLarge,
        ).animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 24),

        // Role cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;

            if (isWide) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _RoleCard(
                      title: 'Nurse',
                      description:
                          'Quick vitals entry, patient list, and alerts',
                      icon: Icons.medical_services_outlined,
                      color: const Color(0xFF4CAF50),
                      onTap: () => _selectRole(context, ref, UserRole.nurse),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RoleCard(
                      title: 'Doctor',
                      description:
                          'Trend analysis, detailed review, escalations',
                      icon: Icons.medical_information,
                      color: const Color(0xFF2196F3),
                      onTap: () => _selectRole(context, ref, UserRole.doctor),
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _RoleCard(
                  title: 'Nurse',
                  description: 'Quick vitals entry, patient list, and alerts',
                  icon: Icons.medical_services_outlined,
                  color: const Color(0xFF4CAF50),
                  onTap: () => _selectRole(context, ref, UserRole.nurse),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  title: 'Doctor',
                  description: 'Trend analysis, detailed review, escalations',
                  icon: Icons.medical_information,
                  color: const Color(0xFF2196F3),
                  onTap: () => _selectRole(context, ref, UserRole.doctor),
                ),
              ],
            );
          },
        )
            .animate()
            .fadeIn(delay: 500.ms, duration: 400.ms)
            .slideY(begin: 0.1, end: 0, duration: 400.ms),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Theme toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.light_mode, size: 18),
            const SizedBox(width: 8),
            Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: (_) {
                ref.read(themeModeProvider.notifier).toggleDarkMode();
              },
            ),
            const SizedBox(width: 8),
            const Icon(Icons.dark_mode, size: 18),
          ],
        ),

        const SizedBox(height: 16),

        Text(
          'Version ${AppConstants.appVersion}',
          style: Theme.of(context).textTheme.bodySmall,
        ),

        const SizedBox(height: 4),

        Text(
          'Clinical Decision Support Tool',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms);
  }

  void _selectRole(BuildContext context, WidgetRef ref, UserRole role) {
    ref.read(userRoleProvider.notifier).state = role;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => role == UserRole.nurse
            ? const NurseDashboardScreen()
            : const DoctorDashboardScreen(),
      ),
    );
  }
}

/// Role selection card widget
class _RoleCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
