import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/user_profile.dart';
import '../services/profile_manager.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<UserProfile> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadFriends();
    });
  }

  Future<void> _loadFriends() async {
    final profileManager = context.read<ProfileManager>();
    try {
      final friends = await profileManager.getFriends();
      if (!mounted) return;
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      setState(() {
        _friends = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.localizeErrorMessage(e.toString()))),
      );
    }
  }

  Future<void> _addFriend() async {
    final added = await showAddFriendDialog(context);
    if (added && mounted) {
      await _loadFriends();
    }
  }

  Future<void> _removeFriend(UserProfile friend) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeFriend),
        content: Text(l10n.removeFriendConfirm(friend.personalName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.removeFriend),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<ProfileManager>().removeFriend(friend.id);
    await _loadFriends();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.friendRemoved)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myFriends), centerTitle: true),
      body: Column(
        children: [
          Consumer<ProfileManager>(
            builder: (context, profileManager, child) {
              final profile = profileManager.currentProfile;
              if (profile == null || !profile.hasFriendCode) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _FriendCodeCard(
                  label: l10n.yourFriendCode,
                  code: profile.friendCode,
                  copiedMessage: l10n.friendCodeCopied,
                  copyLabel: l10n.copyFriendCode,
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addFriend,
                icon: const Icon(Icons.person_add_outlined),
                label: Text(l10n.addFriend),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _friends.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l10n.noFriendsYet,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadFriends,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _friends.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final friend = _friends[index];
                        return _FriendTile(
                          friend: friend,
                          onRemove: () => _removeFriend(friend),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FriendCodeCard extends StatelessWidget {
  const _FriendCodeCard({
    required this.label,
    required this.code,
    required this.copiedMessage,
    required this.copyLabel,
  });

  final String label;
  final String code;
  final String copiedMessage;
  final String copyLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 4),
                  Text(
                    code,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: copyLabel,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(copiedMessage)));
              },
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.onRemove});

  final UserProfile friend;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final color = friend.avatarColor != null
        ? Color(friend.avatarColor!)
        : Colors.grey.shade400;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade300),
        ),
        leading: CircleAvatar(
          backgroundColor: color,
          backgroundImage: friend.avatarPath != null
              ? FileImage(File(friend.avatarPath!))
              : null,
          child: friend.avatarPath == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(
          friend.personalName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: IconButton(
          icon: Icon(Icons.person_remove_outlined, color: Colors.red.shade400),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

Future<bool> showAddFriendDialog(BuildContext context) async {
  final pageContext = context;
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  var isSubmitting = false;

  final added = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(l10n.addFriend),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.addFriendHint),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: l10n.friendCode,
                      hintText: '123456',
                      counterText: '',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final code = value?.trim() ?? '';
                      if (code.length != 6) {
                        return l10n.invalidFriendCode;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDialogState(() => isSubmitting = true);
                        try {
                          final friend = await context
                              .read<ProfileManager>()
                              .addFriendByCode(controller.text.trim());
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext, true);
                          ScaffoldMessenger.of(pageContext).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.friendRequestSent(friend.personalName),
                              ),
                            ),
                          );
                        } catch (e) {
                          setDialogState(() => isSubmitting = false);
                          if (!pageContext.mounted) return;
                          final message = l10n.localizeErrorMessage(
                            e.toString(),
                          );
                          ScaffoldMessenger.of(
                            pageContext,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.addFriend),
              ),
            ],
          );
        },
      );
    },
  );
  controller.dispose();
  return added ?? false;
}
