import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/friendship.dart';
import '../services/profile_manager.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<FriendNotification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final manager = context.read<ProfileManager>();
    try {
      final notifications = await manager.getFriendNotifications();
      await manager.markFriendNotificationsSeen();
      if (!mounted) return;
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.localizeErrorMessage(e.toString()))),
      );
    }
  }

  Future<void> _accept(FriendNotification notification) async {
    await context.read<ProfileManager>().acceptFriendRequest(
      notification.friendship.id,
    );
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n.friendRequestAccepted(notification.otherProfile.name),
        ),
      ),
    );
    await _load();
  }

  Future<void> _reject(FriendNotification notification) async {
    await context.read<ProfileManager>().rejectFriendRequest(
      notification.friendship.id,
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notifications), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? Center(child: Text(l10n.noNotifications))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final notification = _notifications[index];
                  return _NotificationTile(
                    notification: notification,
                    requestText: l10n.friendRequestReceived(
                      notification.otherProfile.name,
                    ),
                    acceptedText: l10n.friendRequestAccepted(
                      notification.otherProfile.name,
                    ),
                    acceptLabel: l10n.accept,
                    rejectLabel: l10n.reject,
                    onAccept: () => _accept(notification),
                    onReject: () => _reject(notification),
                  );
                },
              ),
            ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.requestText,
    required this.acceptedText,
    required this.acceptLabel,
    required this.rejectLabel,
    required this.onAccept,
    required this.onReject,
  });

  final FriendNotification notification;
  final String requestText;
  final String acceptedText;
  final String acceptLabel;
  final String rejectLabel;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final profile = notification.otherProfile;
    final isRequest = notification.isIncomingRequest;
    final color = profile.avatarColor != null
        ? Color(profile.avatarColor!)
        : Colors.grey.shade400;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color,
              backgroundImage: profile.avatarPath != null
                  ? FileImage(File(profile.avatarPath!))
                  : null,
              child: profile.avatarPath == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRequest ? requestText : acceptedText,
                    style: TextStyle(
                      fontWeight: notification.isUnread
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  if (isRequest) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        FilledButton(
                          onPressed: onAccept,
                          child: Text(acceptLabel),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: onReject,
                          child: Text(rejectLabel),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isRequest
                      ? Icons.person_add_outlined
                      : Icons.check_circle_outline,
                  color: isRequest ? Colors.orange : Colors.green,
                ),
                if (notification.isUnread)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
