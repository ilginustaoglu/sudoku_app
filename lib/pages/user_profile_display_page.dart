import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../l10n/app_localizations.dart';
import '../models/profile_stats.dart';
import '../services/profile_manager.dart';
import '../services/statistics_visibility_manager.dart';

class UserProfileDisplayPage extends StatefulWidget {
  const UserProfileDisplayPage({super.key});

  @override
  State<UserProfileDisplayPage> createState() => _UserProfileDisplayPageState();
}

class _UserProfileDisplayPageState extends State<UserProfileDisplayPage> {
  ProfileStats? _stats;
  bool _isLoading = true;
  String? _expandedDifficulty;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profileManager = Provider.of<ProfileManager>(context, listen: false);
    if (profileManager.currentProfile == null) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    await profileManager.refreshCurrentProfile();

    final profileId = profileManager.currentProfile!.id;
    final stats = await profileManager.getProfileStats(profileId);

    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        centerTitle: true,
      ),
      body: Consumer<ProfileManager>(
        builder: (context, profileManager, child) {
          final profile = profileManager.currentProfile;
          
          if (profile == null || profileManager.isGuestMode) {
            return Center(
              child: Text(l10n.noProfileAvailable),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: profile.avatarColor != null
                        ? Color(profile.avatarColor!)
                        : Colors.grey.shade300,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: profile.avatarPath != null
                      ? ClipOval(
                          child: Image.file(
                            File(profile.avatarPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
                              );
                            },
                          ),
                        )
                      : const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                ),
                
                const SizedBox(height: 20),

                Text(
                  profile.personalName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: _ComingSoonButton(
                        label: l10n.myFriends,
                        comingSoon: l10n.comingSoon,
                        icon: Icons.people_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ComingSoonButton(
                        label: l10n.addFriend,
                        comingSoon: l10n.comingSoon,
                        icon: Icons.person_add_outlined,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.statistics,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // İstatistik görünürlük durumu
                    Consumer<StatisticsVisibilityManager>(
                      builder: (context, visibilityManager, child) {
                        return Tooltip(
                          message: l10n.visibilityLabel(visibilityManager.visibility),
                          child: Icon(
                            visibilityManager.visibility == StatisticsVisibility.onlyMe
                                ? Icons.lock
                                : visibilityManager.visibility == StatisticsVisibility.friends
                                    ? Icons.people
                                    : Icons.public,
                            color: Colors.grey.shade600,
                            size: 20,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // İstatistikler
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_stats != null)
                  _buildStatistics(_stats!, l10n)
                else
                  Text(l10n.noStatisticsAvailable),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatistics(ProfileStats stats, AppLocalizations l10n) {
    if (!stats.hasAnyGames) {
      return Text(l10n.noStatisticsAvailable);
    }

    final overall = stats.overall;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                l10n.statTotalGames,
                overall.totalGames.toString(),
                Icons.games,
                const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                l10n.statTotalScore,
                overall.totalScore.toString(),
                Icons.star,
                const Color(0xFF6F4E37),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                l10n.statBestScore,
                overall.bestScore.toString(),
                Icons.emoji_events,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                l10n.statAverageScore,
                overall.averageScore.toString(),
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildStatCard(
          l10n.statTotalTime,
          l10n.formatDuration(overall.totalTime),
          Icons.timer,
          Colors.blue,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            l10n.gamesByDifficulty,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildDifficultySection(
          l10n: l10n,
          label: l10n.easy,
          stats: stats.easy,
          color: Colors.green,
          icon: Icons.check_circle,
        ),
        const SizedBox(height: 12),
        _buildDifficultySection(
          l10n: l10n,
          label: l10n.medium,
          stats: stats.medium,
          color: Colors.orange,
          icon: Icons.info,
        ),
        const SizedBox(height: 12),
        _buildDifficultySection(
          l10n: l10n,
          label: l10n.hard,
          stats: stats.hard,
          color: Colors.red,
          icon: Icons.warning,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection({
    required AppLocalizations l10n,
    required String label,
    required DifficultyStats stats,
    required Color color,
    required IconData icon,
  }) {
    final isExpanded = _expandedDifficulty == stats.difficulty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedDifficulty =
                isExpanded ? null : stats.difficulty;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isExpanded ? color : color.withOpacity(0.4),
              width: isExpanded ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        Text(
                          l10n.statGamesPlayed(stats.totalGames),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _buildDifficultyDetails(l10n, stats, color),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyDetails(
    AppLocalizations l10n,
    DifficultyStats stats,
    Color color,
  ) {
    if (!stats.hasGames) {
      return Text(
        l10n.noStatisticsAvailable,
        style: TextStyle(color: Colors.grey.shade600),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                l10n.statTotalGames,
                stats.totalGames.toString(),
                color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                l10n.statTotalScore,
                stats.totalScore.toString(),
                color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDetailItem(
                l10n.statBestScore,
                stats.bestScore.toString(),
                color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDetailItem(
                l10n.statAverageScore,
                stats.averageScore.toString(),
                color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildDetailItem(
          l10n.statTotalTime,
          l10n.formatDuration(stats.totalTime),
          color,
        ),
      ],
    );
  }

  Widget _buildDetailItem(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

}

class _ComingSoonButton extends StatelessWidget {
  const _ComingSoonButton({
    required this.label,
    required this.comingSoon,
    required this.icon,
  });

  final String label;
  final String comingSoon;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: OutlinedButton(
        onPressed: null,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          foregroundColor: Colors.grey.shade700,
          disabledForegroundColor: Colors.grey.shade700,
          side: BorderSide(color: Colors.grey.shade400),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              comingSoon,
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
