import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'data.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  int _activeIndex = 1; // default: 5 Easy Juggling
  int _chapterIndex = 0;
  bool _isLooping = false;
  bool _isSlowMotion = false;
  bool _sidebarOpen = false;
  bool _menuOpen = false;

  VideoPlayerController? _controller;
  Timer? _chapterTimer;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = playlists[_activeIndex].videoUrl;
    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    await ctrl.initialize();
    ctrl.addListener(_onVideoTick);
    if (mounted) {
      setState(() => _controller = ctrl);
      _seekToChapter();
      _startChapterWatcher();
    }
  }

  void _onVideoTick() {
    if (mounted) setState(() {});
  }

  void _startChapterWatcher() {
    _chapterTimer?.cancel();
    _chapterTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      final ctrl = _controller;
      if (ctrl == null || !ctrl.value.isPlaying) return;
      final pos = ctrl.value.position.inSeconds;
      final ch = playlists[_activeIndex].chapters[_chapterIndex];
      if (pos >= ch.endSeconds) {
        if (_isLooping) {
          ctrl.seekTo(Duration(seconds: ch.startSeconds));
        } else {
          final nextIdx = _chapterIndex + 1;
          if (nextIdx < playlists[_activeIndex].chapters.length) {
            setState(() => _chapterIndex = nextIdx);
            ctrl.seekTo(Duration(seconds: playlists[_activeIndex].chapters[nextIdx].startSeconds));
          } else {
            ctrl.pause();
          }
        }
      }
    });
  }

  void _seekToChapter() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final ch = playlists[_activeIndex].chapters[_chapterIndex];
    ctrl.seekTo(Duration(seconds: ch.startSeconds));
  }

  void _jumpTo(int i) {
    setState(() {
      _chapterIndex = i;
      _sidebarOpen = false;
    });
    final ctrl = _controller;
    if (ctrl == null) return;
    ctrl.seekTo(Duration(seconds: playlists[_activeIndex].chapters[i].startSeconds));
    ctrl.play();
  }

  void _togglePlay() {
    final ctrl = _controller;
    if (ctrl == null) return;
    if (ctrl.value.isPlaying) {
      ctrl.pause();
    } else {
      ctrl.play();
    }
    setState(() {});
  }

  void _toggleSlowMotion() {
    setState(() => _isSlowMotion = !_isSlowMotion);
    _controller?.setPlaybackSpeed(_isSlowMotion ? 0.5 : 1.0);
  }

  void _selectPlaylist(int i) {
    _chapterTimer?.cancel();
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    setState(() {
      _activeIndex = i;
      _chapterIndex = 0;
      _menuOpen = false;
      _controller = null;
    });
    _initVideo();
  }

  void _toggleFullScreen() {
    final isFullScreen = MediaQuery.of(context).viewPadding.top == 0 &&
        SystemChrome.latestStyle?.statusBarColor == Colors.transparent;
    if (!isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    _chapterTimer?.cancel();
    _controller?.removeListener(_onVideoTick);
    _controller?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _controller;
    final isPlaying = ctrl?.value.isPlaying ?? false;
    final playlist = playlists[_activeIndex];
    final chapters = playlist.chapters;
    final currentChapter = chapters[_chapterIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Header ──────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _Header(
              playlistName: playlist.name,
              isLooping: _isLooping,
              isSlowMotion: _isSlowMotion,
              menuOpen: _menuOpen,
              sidebarOpen: _sidebarOpen,
              onToggleSlowMotion: _toggleSlowMotion,
              onToggleLoop: () => setState(() => _isLooping = !_isLooping),
              onToggleFullScreen: _toggleFullScreen,
              onToggleMenu: () => setState(() => _menuOpen = !_menuOpen),
              onToggleSidebar: () => setState(() => _sidebarOpen = !_sidebarOpen),
            ),
          ),

          // ── Video area ──────────────────────────────────────────
          Positioned.fill(
            top: 52,
            child: Stack(
              children: [
                // Video
                ctrl != null && ctrl.value.isInitialized
                    ? Center(
                        child: AspectRatio(
                          aspectRatio: ctrl.value.aspectRatio,
                          child: VideoPlayer(ctrl),
                        ),
                      )
                    : const Center(child: CircularProgressIndicator(color: Colors.white30)),

                // Tap to play/pause
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _togglePlay,
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedOpacity(
                      opacity: isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Center(
                        child: Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white, size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Chapter name overlay bottom-left
                Positioned(
                  bottom: 16, left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      currentChapter.name,
                      style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                // Chapter sidebar (slides from RIGHT)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  top: 0, bottom: 0,
                  right: _sidebarOpen ? 0 : -300,
                  width: 300,
                  child: _ChapterSidebar(
                    chapters: chapters,
                    chapterIndex: _chapterIndex,
                    onClose: () => setState(() => _sidebarOpen = false),
                    onJump: _jumpTo,
                  ),
                ),
              ],
            ),
          ),

          // ── Playlist drawer (slides from LEFT) ──────────────────
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            top: 52, bottom: 0,
            left: _menuOpen ? 0 : -300,
            width: 300,
            child: _PlaylistDrawer(
              playlists: playlists,
              activeIndex: _activeIndex,
              onClose: () => setState(() => _menuOpen = false),
              onSelect: _selectPlaylist,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String playlistName;
  final bool isLooping, isSlowMotion, menuOpen, sidebarOpen;
  final VoidCallback onToggleSlowMotion, onToggleLoop, onToggleFullScreen,
      onToggleMenu, onToggleSidebar;

  const _Header({
    required this.playlistName,
    required this.isLooping,
    required this.isSlowMotion,
    required this.menuOpen,
    required this.sidebarOpen,
    required this.onToggleSlowMotion,
    required this.onToggleLoop,
    required this.onToggleFullScreen,
    required this.onToggleMenu,
    required this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: const Color(0xFF171717), // neutral-900
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              playlistName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _IconBtn(
            active: isSlowMotion,
            tooltip: 'Slow motion',
            onTap: onToggleSlowMotion,
            child: const Icon(Icons.slow_motion_video, size: 20),
          ),
          _IconBtn(
            active: isLooping,
            tooltip: 'Loop',
            onTap: onToggleLoop,
            child: const Icon(Icons.repeat_one, size: 20),
          ),
          _IconBtn(
            active: false,
            tooltip: 'Fullscreen',
            onTap: onToggleFullScreen,
            child: const Icon(Icons.fullscreen, size: 20),
          ),
          _IconBtn(
            active: menuOpen,
            tooltip: 'Playlists',
            onTap: onToggleMenu,
            child: const Icon(Icons.playlist_play, size: 20),
          ),
          _IconBtn(
            active: sidebarOpen,
            tooltip: 'Chapters',
            onTap: onToggleSidebar,
            child: const Icon(Icons.view_sidebar_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final bool active;
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

  const _IconBtn({
    required this.active,
    required this.tooltip,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF404040) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconTheme(
            data: IconThemeData(
              color: active ? Colors.white : const Color(0xFF737373),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── Playlist Drawer ────────────────────────────────────────────────────────

class _PlaylistDrawer extends StatelessWidget {
  final List<Playlist> playlists;
  final int activeIndex;
  final VoidCallback onClose;
  final void Function(int) onSelect;

  const _PlaylistDrawer({
    required this.playlists,
    required this.activeIndex,
    required this.onClose,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF171717),
      child: Column(
        children: [
          // header row
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF262626))),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('PLAYLISTS',
                      style: TextStyle(
                          color: Color(0xFF737373),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Color(0xFF737373)),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: playlists.length,
              itemBuilder: (_, i) {
                final active = i == activeIndex;
                return InkWell(
                  onTap: () => onSelect(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF262626) : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: active ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        bottom: const BorderSide(color: Color(0xFF262626)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80, height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF262626),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(Icons.play_circle_outline,
                              color: Color(0xFF525252), size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            playlists[i].name,
                            style: TextStyle(
                              color: active ? Colors.white : const Color(0xFFD4D4D4),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Chapter Sidebar ────────────────────────────────────────────────────────

class _ChapterSidebar extends StatelessWidget {
  final List<Chapter> chapters;
  final int chapterIndex;
  final VoidCallback onClose;
  final void Function(int) onJump;

  const _ChapterSidebar({
    required this.chapters,
    required this.chapterIndex,
    required this.onClose,
    required this.onJump,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF171717),
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF262626))),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text('CHAPTERS',
                      style: TextStyle(
                          color: Color(0xFF737373),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Color(0xFF737373)),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (_, i) {
                final active = i == chapterIndex;
                return InkWell(
                  onTap: () => onJump(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF262626) : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: active ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                        bottom: const BorderSide(color: Color(0xFF262626)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80, height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF262626),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              _fmt(chapters[i].startSeconds),
                              style: const TextStyle(
                                  color: Color(0xFF737373), fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            chapters[i].name,
                            style: TextStyle(
                              color: active ? Colors.white : const Color(0xFFD4D4D4),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '$m:${sec.toString().padLeft(2, '0')}';
  }
}
