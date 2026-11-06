import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/chat_providers.dart';
import 'screens/chat_screen.dart';
import '../../core/l10n/app_language.dart';

/// Opens (or creates) the chat with [otherId] and shows it. Used by the
/// Message buttons on listings, bids and barters.
Future<void> openChatWith(
  BuildContext context,
  WidgetRef ref, {
  required String otherId,
  String? otherName,
  String? listingId,
  String? listingTitle,
}) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.tr('Could not open chat', 'Dili maablihan ang chat');
  try {
    final conversationId = await ref.read(chatControllerProvider).openChat(
          otherId: otherId,
          otherName: otherName,
          listingId: listingId,
          listingTitle: listingTitle,
        );
    navigator.push(MaterialPageRoute<void>(
      builder: (_) => ChatScreen(conversationId: conversationId),
    ));
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('$failed: $error')),
    );
  }
}

/// App-bar button that opens the chat with the other party.
class MessageIconButton extends ConsumerWidget {
  const MessageIconButton({
    super.key,
    required this.otherId,
    this.listingId,
    this.listingTitle,
  });

  final String otherId;
  final String? listingId;
  final String? listingTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: context.tr('Message', 'Mensahe'),
      icon: const Icon(Icons.chat_bubble_outline),
      onPressed: () => openChatWith(
        context,
        ref,
        otherId: otherId,
        listingId: listingId,
        listingTitle: listingTitle,
      ),
    );
  }
}
