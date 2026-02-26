import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool showAvatar;
  final String initials;
  final DateTime time;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isMe,
    required this.showAvatar,
    required this.initials,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bubbleColor = isMe ? cs.secondary.withOpacity(0.92) : cs.primary.withOpacity(0.86);
    final fg = isMe ? const Color(0xFF0B0F14) : Colors.white;
    final borderColor = Theme.of(context).dividerColor.withOpacity(0.6);

    final t = DateFormat('dd/MM/yyyy HH:mm').format(time);

    // ✅ Dimensionamento automático:
    // IntrinsicWidth + Column(mainAxisSize: min) + maxWidth
    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: IntrinsicWidth(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // ✅ não estica
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.25,
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  t,
                  style: TextStyle(
                    fontSize: 11,
                    color: fg.withOpacity(0.78),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isMe) ...[
          SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: showAvatar ? _SmallAvatar(initials: initials) : const SizedBox(height: 24),
            ),
          ),
          bubble,
          const SizedBox(width: 42),
        ],
        if (isMe) ...[
          const SizedBox(width: 42),
          bubble,
          SizedBox(
            width: 40,
            child: Align(
              alignment: Alignment.bottomRight,
              child: showAvatar ? _SmallAvatar(initials: initials) : const SizedBox(height: 24),
            ),
          ),
        ],
      ],
    );
  }
}

class _SmallAvatar extends StatelessWidget {
  final String initials;

  const _SmallAvatar({required this.initials});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Theme.of(context).dividerColor),
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.9),
            cs.secondary.withOpacity(0.9),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}