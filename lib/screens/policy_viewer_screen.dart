// lib/screens/policy_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';

class PolicyViewerScreen extends StatefulWidget {
  final String title;
  final String markdownAssetPath;

  const PolicyViewerScreen({
    super.key,
    required this.title,
    required this.markdownAssetPath,
  });

  @override
  State<PolicyViewerScreen> createState() => _PolicyViewerScreenState();
}

class _PolicyViewerScreenState extends State<PolicyViewerScreen> {
  final ScrollController _scrollController = ScrollController();
  String _markdownData = "";
  bool _isLoading = true;
  
  bool _canScrollUp = false;
  bool _canScrollDown = false;
  bool _hasReachedEnd = false;

  @override
  void initState() {
    super.initState();
    _loadMarkdown();
    _scrollController.addListener(_onScrollChanged);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollChanged);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMarkdown() async {
    try {
      final data = await rootBundle.loadString(widget.markdownAssetPath);
      if (mounted) {
        setState(() {
          _markdownData = data;
          _isLoading = false;
          WidgetsBinding.instance.addPostFrameCallback((_) => _onScrollChanged());
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _markdownData = "Erro ao carregar o documento.";
          _isLoading = false;
        });
      }
    }
  }

  void _onScrollChanged() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final maxScroll = pos.maxScrollExtent;
    final current = pos.pixels;
    final canUp = current > 0.0;
    final canDown = current < maxScroll;
    final hasReachedEnd = current >= maxScroll;

    if (canUp != _canScrollUp || canDown != _canScrollDown || hasReachedEnd != _hasReachedEnd) {
      setState(() {
        _canScrollUp = canUp;
        _canScrollDown = canDown;
        _hasReachedEnd = hasReachedEnd;
      });
    }
  }

  Future<void> _scrollPageUp() async {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final viewport = pos.viewportDimension;
    final target = (pos.pixels - viewport).clamp(0.0, pos.maxScrollExtent);
    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  Future<void> _scrollPageDown() async {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    final viewport = pos.viewportDimension;
    final target = (pos.pixels + viewport).clamp(0.0, pos.maxScrollExtent);
    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: const [],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Markdown(
                    controller: _scrollController,
                    data: _markdownData,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  ),
                  if (_canScrollDown)
                    Positioned(
                      right: 16,
                      bottom: 88,
                      child: FloatingActionButton.small(
                        heroTag: 'scroll_down',
                        onPressed: _scrollPageDown,
                        tooltip: 'Mostrar conteúdo abaixo',
                        child: const Icon(Icons.arrow_downward),
                      ),
                    ),
                  if (_canScrollUp)
                    Positioned(
                      right: 16,
                      top: 8,
                      child: FloatingActionButton.small(
                        heroTag: 'scroll_up_overlay',
                        onPressed: _scrollPageUp,
                        tooltip: 'Mostrar conteúdo acima',
                        child: const Icon(Icons.arrow_upward),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16).copyWith(top: 8),
                      // CORREÇÃO DO 'withOpacity':
                      color: Theme.of(context).scaffoldBackgroundColor.withAlpha(242), // 242 é ~95%
                      child: ElevatedButton(
                        onPressed: _hasReachedEnd
                            ? () => Navigator.of(context).pop(true)
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(_hasReachedEnd ? 'Marcar como Lido' : 'Role até o fim para continuar'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}