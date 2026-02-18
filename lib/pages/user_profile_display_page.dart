import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../services/profile_manager.dart';
import '../services/statistics_visibility_manager.dart';
import '../services/profile_visibility_manager.dart';

class UserProfileDisplayPage extends StatefulWidget {
  const UserProfileDisplayPage({super.key});

  @override
  State<UserProfileDisplayPage> createState() => _UserProfileDisplayPageState();
}

class _UserProfileDisplayPageState extends State<UserProfileDisplayPage> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final profileManager = Provider.of<ProfileManager>(context, listen: false);
    if (profileManager.currentProfile != null) {
      final stats = await profileManager.getProfileStats(
        profileManager.currentProfile!.id,
      );
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white.withOpacity(0.9),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
      ),
      body: Consumer<ProfileManager>(
        builder: (context, profileManager, child) {
          final profile = profileManager.currentProfile;
          
          if (profile == null || profileManager.isGuestMode) {
            return const Center(
              child: Text('No profile available'),
            );
          }

          return Stack(
            children: [
              // Cover Image veya Cover Color (arkaplan)
              Positioned.fill(
                child: profile.coverImagePath != null && profile.coverImagePath!.isNotEmpty
                    ? Opacity(
                        opacity: 0.8, // %80 opaklık
                        child: _buildCoverImage(profile.coverImagePath!, profile),
                      )
                    : Container(
                        color: profile.coverImageColor != null
                            ? Color(profile.coverImageColor!)
                            : Colors.grey.shade300,
                      ),
              ),
              // İçerik
              SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Profil fotoğrafı
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
                        color: Colors.black.withOpacity(0.2),
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
                
                const SizedBox(height: 24),
                
                // İsim Soyisim veya Display Name
                Consumer<ProfileVisibilityManager>(
                  builder: (context, visibilityManager, child) {
                    String displayText;
                    
                    // Eğer tüm bilgiler gizliyse "no name user" göster
                    if (visibilityManager.isAllInfoHidden) {
                      displayText = 'no name user';
                    } else if (profile.displayName != null && profile.displayName!.isNotEmpty) {
                      // Display name varsa onu göster
                      displayText = profile.displayName!;
                    } else if (visibilityManager.showName) {
                      // İsim gösteriliyorsa fullName göster
                      displayText = profile.fullName;
                    } else {
                      // Hiçbiri gösterilmiyorsa "no name user"
                      displayText = 'no name user';
                    }
                    
                    return Text(
                      displayText,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Email (görünürlük ayarına göre)
                Consumer<ProfileVisibilityManager>(
                  builder: (context, visibilityManager, child) {
                    if (!visibilityManager.showEmail) {
                      return const SizedBox.shrink();
                    }
                    
                    return Text(
                      profile.email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // İstatistikler başlığı
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    // İstatistik görünürlük durumu
                    Consumer<StatisticsVisibilityManager>(
                      builder: (context, visibilityManager, child) {
                        IconData icon;
                        String tooltip;
                        switch (visibilityManager.visibility) {
                          case StatisticsVisibility.onlyMe:
                            icon = Icons.lock;
                            tooltip = 'Only Me';
                            break;
                          case StatisticsVisibility.friends:
                            icon = Icons.people;
                            tooltip = 'My Friends';
                            break;
                          case StatisticsVisibility.everyone:
                            icon = Icons.public;
                            tooltip = 'Everyone';
                            break;
                        }
                        return Tooltip(
                          message: tooltip,
                          child: Icon(
                            icon,
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
                  _buildStatistics(_stats!)
                else
                  const Text('No statistics available'),
                ],
              ),
            ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatistics(Map<String, dynamic> stats) {
    return Column(
      children: [
        // Toplam oyunlar ve toplam skor
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Games',
                stats['totalGames'].toString(),
                Icons.games,
                const Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Score',
                stats['totalScore'].toString(),
                Icons.star,
                const Color(0xFF6F4E37),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // En iyi skor ve ortalama skor
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Best Score',
                stats['bestScore'].toString(),
                Icons.emoji_events,
                Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Average Score',
                stats['averageScore'].toString(),
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Toplam süre
        _buildStatCard(
          'Total Time',
          _formatTime(stats['totalTime'] as int),
          Icons.timer,
          Colors.blue,
        ),
        
        const SizedBox(height: 24),
        
        // Zorluk seviyelerine göre oyunlar
        const Text(
          'Games by Difficulty',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Easy',
                stats['easyGames'].toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Medium',
                stats['mediumGames'].toString(),
                Icons.info,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Hard',
                stats['hardGames'].toString(),
                Icons.warning,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // Opak beyaz arka plan
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  Widget _buildCoverImage(String imagePath, profile) {
    // Asset path kontrolü (assets/ ile başlıyorsa)
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        repeat: ImageRepeat.noRepeat,
        errorBuilder: (context, error, stackTrace) {
          // Hata durumunda renk göster
          debugPrint('Error loading cover image: $error');
          debugPrint('Image path: $imagePath');
          return Container(
            color: profile.coverImageColor != null
                ? Color(profile.coverImageColor!)
                : Colors.grey.shade300,
          );
        },
      );
    } else {
      // File path ise
      final file = File(imagePath);
      return FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              repeat: ImageRepeat.noRepeat,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error loading cover image file: $error');
                debugPrint('Image path: $imagePath');
                return Container(
                  color: profile.coverImageColor != null
                      ? Color(profile.coverImageColor!)
                      : Colors.grey.shade300,
                );
              },
            );
          } else {
            // Dosya yoksa renk göster
            return Container(
              color: profile.coverImageColor != null
                  ? Color(profile.coverImageColor!)
                  : Colors.grey.shade300,
            );
          }
        },
      );
    }
  }
}
