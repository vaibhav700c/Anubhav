import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Auto-scrolling transcript feed that fades in each new line.
class TranscriptFeed extends StatefulWidget {
  final List<String> lines;

  const TranscriptFeed({super.key, required this.lines});

  @override
  State<TranscriptFeed> createState() => _TranscriptFeedState();
}

class _TranscriptFeedState extends State<TranscriptFeed> {
  final _scrollController = ScrollController();
  final List<GlobalKey<_FadeLineState>> _lineKeys = [];

  @override
  void didUpdateWidget(TranscriptFeed old) {
    super.didUpdateWidget(old);
    if (widget.lines.length > old.lines.length) {
      _lineKeys.add(GlobalKey<_FadeLineState>());
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    while (_lineKeys.length < widget.lines.length) {
      _lineKeys.add(GlobalKey<_FadeLineState>());
    }

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AnubhavColors.bgCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AnubhavColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.mic, size: 16, color: AnubhavColors.teal),
                const SizedBox(width: 6),
                Text(
                  'Live Transcript Feed',
                  style: AnubhavTextStyles.titleMedium.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AnubhavColors.divider),
          Expanded(
            child: widget.lines.isEmpty
                ? const Center(
                    child: Text(
                      'Waiting for speech input...',
                      style: TextStyle(
                        color: AnubhavColors.textTertiary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: widget.lines.length,
                    itemBuilder: (ctx, i) => _FadeLine(
                      key: _lineKeys[i],
                      text: widget.lines[i],
                      isLatest: i == widget.lines.length - 1,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _FadeLine extends StatefulWidget {
  final String text;
  final bool isLatest;

  const _FadeLine({super.key, required this.text, required this.isLatest});

  @override
  State<_FadeLine> createState() => _FadeLineState();
}

class _FadeLineState extends State<_FadeLine> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          widget.text,
          style: AnubhavTextStyles.bodyMedium.copyWith(
            color: widget.isLatest ? AnubhavColors.textPrimary : AnubhavColors.textSecondary,
            fontWeight: widget.isLatest ? FontWeight.w600 : FontWeight.w400,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
