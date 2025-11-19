import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../data/models/youtube_video_model.dart';
import '../../../resources/styles/colors.dart';
import '../../controllers/youtube_controller.dart';
import '../../widgets/info_card.dart';

class YoutubePlayerScreen extends StatefulWidget {
  const YoutubePlayerScreen({Key? key, required this.videoId}) : super(key: key);

  final String videoId;

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  YoutubePlayerController? _playerController;
  YoutubeVideo? _video;
  final _controller = Get.find<YoutubeController>();

  final _autoPlayEnabled = true.obs;
  final _isVideoEnded = false.obs;
  final _isFullScreen = false.obs;
  final _isInitializing = true.obs;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePlayer();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _isInitialized = true;
    }
  }

  @override
  void didUpdateWidget(YoutubePlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _reloadPlayer();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      _isInitializing.value = true;

      // Get video from route or create fallback
      _video = GoRouterState.of(context).extra as YoutubeVideo? ??
          YoutubeVideo(
            id: widget.videoId,
            title: 'Video',
            thumbnailUrl: '',
            channelTitle: '',
            publishedAt: DateTime.now(),
          );

      // Get saved position
      final savedPosition = _controller.getSavedPosition(_video!.id);
      final startSeconds = savedPosition?.inSeconds ?? 0;

      // Initialize player
      _playerController = YoutubePlayerController(
        initialVideoId: _video!.id,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          isLive: false,
          startAt: startSeconds,
          controlsVisibleAtStart: true,
          hideThumbnail: true,
          disableDragSeek: false,
        ),
      );

      _playerController!.addListener(_onPlayerStateChanged);

      // Update video index
      final foundIndex = _controller.videos.indexWhere((v) => v.id == _video!.id);
      if (foundIndex != -1) {
        _controller.setCurrentVideoIndex(foundIndex);
      }

      _isVideoEnded.value = false;

      if (mounted) {
        setState(() {});
      }

      // Wait for player to be ready
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && _playerController?.value.isReady == false) {
        _playerController!.load(_video!.id);
      }
    } catch (e) {
      _video = YoutubeVideo(
        id: widget.videoId,
        title: 'Error loading video',
        thumbnailUrl: '',
        channelTitle: '',
        publishedAt: DateTime.now(),
      );
    } finally {
      _isInitializing.value = false;
    }
  }

  Future<void> _reloadPlayer() async {
    try {
      _isInitializing.value = true;

      // Save current position
      if (_playerController != null && _video != null) {
        final currentPosition = _playerController!.value.position;
        _controller.savePosition(_video!.id, currentPosition);
      }

      // Get new video
      _video = GoRouterState.of(context).extra as YoutubeVideo? ??
          YoutubeVideo(
            id: widget.videoId,
            title: 'Video',
            thumbnailUrl: '',
            channelTitle: '',
            publishedAt: DateTime.now(),
          );

      // Clean up old controller
      _playerController?.removeListener(_onPlayerStateChanged);
      _playerController?.dispose();

      // Get saved position for new video
      final savedPosition = _controller.getSavedPosition(_video!.id);
      final startSeconds = savedPosition?.inSeconds ?? 0;

      // Initialize new controller
      _playerController = YoutubePlayerController(
        initialVideoId: _video!.id,
        flags: YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: true,
          isLive: false,
          startAt: startSeconds,
          controlsVisibleAtStart: false,
          hideThumbnail: true,
        ),
      );

      _playerController!.addListener(_onPlayerStateChanged);

      // Update video index
      final foundIndex = _controller.videos.indexWhere((v) => v.id == _video!.id);
      if (foundIndex != -1) {
        _controller.setCurrentVideoIndex(foundIndex);
      }

      _isVideoEnded.value = false;

      if (mounted) {
        setState(() {});
      }

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted && _playerController?.value.isReady == false) {
        _playerController!.load(_video!.id);
      }
    } catch (e) {
      // Silent error
    } finally {
      _isInitializing.value = false;
    }
  }

  void _onPlayerStateChanged() {
    if (!mounted || _playerController == null) return;

    final playerState = _playerController!.value.playerState;

    // Handle fullscreen changes
    if (_playerController!.value.isFullScreen != _isFullScreen.value) {
      _isFullScreen.value = _playerController!.value.isFullScreen;

      if (_isFullScreen.value) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

        // Save position when exiting fullscreen
        if (_video != null) {
          final position = _playerController!.value.position;
          _controller.savePosition(_video!.id, position);
        }
      }
    }

    // Auto-save position every 5 seconds while playing
    if (playerState == PlayerState.playing && _video != null) {
      final position = _playerController!.value.position;
      if (position.inSeconds % 5 == 0) {
        _controller.savePosition(_video!.id, position);
      }
    }

    // Handle video ended
    if (playerState == PlayerState.ended && !_isVideoEnded.value) {
      _isVideoEnded.value = true;

      if (_video != null) {
        _controller.clearPosition(_video!.id);
      }

      if (_autoPlayEnabled.value) {
        _playNextVideo();
      } else {
        Get.snackbar(
          'Video đã kết thúc',
          'Nhấn "Xem lại" để xem lại hoặc chọn video khác',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
        );
      }
    }

    if (playerState == PlayerState.playing && _isVideoEnded.value) {
      _isVideoEnded.value = false;
    }
  }

  void _toggleFullScreen() {
    _playerController?.toggleFullScreenMode();
  }

  void _replayVideo() {
    if (_playerController != null && _video != null) {
      _playerController!.seekTo(Duration.zero);
      _isVideoEnded.value = false;
      _playerController!.play();
      _controller.savePosition(_video!.id, Duration.zero);
    }
  }

  void _playNextVideo() {
    final currentIndex = _controller.currentVideoIndex.value;
    if (currentIndex == -1 || currentIndex >= _controller.videos.length - 1) {
      Get.snackbar(
        'Thông báo',
        'Đã phát hết danh sách video',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    _saveCurrentPosition();

    final nextIndex = currentIndex + 1;
    _controller.setCurrentVideoIndex(nextIndex);
    final nextVideo = _controller.videos[nextIndex];

    context.pushReplacement('/youtube/player/${nextVideo.id}', extra: nextVideo);
  }

  void _playNextManually() {
    final currentIndex = _controller.currentVideoIndex.value;
    if (currentIndex == -1 || currentIndex >= _controller.videos.length - 1) {
      Get.snackbar(
        'Thông báo',
        'Đây là video cuối cùng',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    _saveCurrentPosition();

    final nextIndex = currentIndex + 1;
    _controller.setCurrentVideoIndex(nextIndex);
    final nextVideo = _controller.videos[nextIndex];

    context.pushReplacement('/youtube/player/${nextVideo.id}', extra: nextVideo);
  }

  void _playPreviousManually() {
    final currentIndex = _controller.currentVideoIndex.value;
    if (currentIndex <= 0) {
      Get.snackbar(
        'Thông báo',
        'Đây là video đầu tiên',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    _saveCurrentPosition();

    final prevIndex = currentIndex - 1;
    _controller.setCurrentVideoIndex(prevIndex);
    final prevVideo = _controller.videos[prevIndex];

    context.pushReplacement('/youtube/player/${prevVideo.id}', extra: prevVideo);
  }

  void _saveCurrentPosition() {
    if (_video != null && _playerController != null) {
      final position = _playerController!.value.position;
      _controller.savePosition(_video!.id, position);
    }
  }

  @override
  void dispose() {
    _saveCurrentPosition();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _playerController?.removeListener(_onPlayerStateChanged);
    _playerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    return Obx(() {
      if (_isInitializing.value || _playerController == null) {
        return _buildLoadingScreen();
      }

      return _buildPlayerScreen(isDesktop);
    });
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đang tải...'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary,),
            const SizedBox(height: 16),
            Text(
              'Đang tải video...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerScreen(bool isDesktop) {
    final crossAxisCount = isDesktop ? (MediaQuery.of(context).size.width > 1200 ? 3 : 2) : 1;

    return Scaffold(
      appBar: _isFullScreen.value
          ? null
          : AppBar(
        title: Text(
          _video?.title ?? 'Video',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _autoPlayEnabled.value ? Icons.playlist_play : Icons.playlist_remove,
            ),
            tooltip: _autoPlayEnabled.value ? 'Tắt tự động phát' : 'Bật tự động phát',
            onPressed: () {
              _autoPlayEnabled.value = !_autoPlayEnabled.value;
              Get.snackbar(
                'Tự động phát',
                _autoPlayEnabled.value ? 'Đã bật' : 'Đã tắt',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 1),
                margin: const EdgeInsets.all(16),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: _toggleFullScreen,
          ),
        ],
      ),
      body: YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _playerController!,
        showVideoProgressIndicator: true,
           thumbnail: Text(_video!.title) ,
          progressIndicatorColor: AppColors.primary,
          progressColors: ProgressBarColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
          ),
        ),
        onExitFullScreen: () {
          _saveCurrentPosition();
        },
        builder: (context, playerWidget) {
          if (_playerController!.value.isFullScreen) {
            return Center(child: playerWidget);
          }

          return Column(
            children: [
              AspectRatio(
                aspectRatio: isDesktop ? 16 / 6 : 16 / 9,
                child: playerWidget,
              ),
              _buildNavigationControls(),
              Expanded(
                child: _buildVideoList(context, crossAxisCount, isDesktop),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Obx(() {
      final currentIndex = _controller.currentVideoIndex.value;
      final hasPrev = currentIndex > 0;
      final hasNext = currentIndex < _controller.videos.length - 1 && currentIndex != -1;
      final showReplay = _isVideoEnded.value && (!hasNext || !_autoPlayEnabled.value);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildControlButton(
              icon: Icons.skip_previous,
              label: 'Trước',
              onPressed: hasPrev ? _playPreviousManually : null,
              isEnabled: hasPrev,
            ),
            const SizedBox(width: 12),
            Expanded(child: _buildVideoInfo()),
            const SizedBox(width: 12),
            if (showReplay)
              _buildControlButton(
                icon: Icons.replay,
                label: 'Xem lại',
                onPressed: _replayVideo,
                isEnabled: true,
              )
            else
              _buildControlButton(
                icon: Icons.skip_next,
                label: 'Tiếp',
                onPressed: hasNext ? _playNextManually : null,
                isEnabled: hasNext,
              ),
          ],
        ),
      );
    });
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isEnabled ? AppColors.primary : Colors.grey.shade300,
        foregroundColor: isEnabled ? Colors.white : Colors.grey.shade600,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Obx(() {
      final currentIndex = _controller.currentVideoIndex.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentIndex != -1
                ? 'Video ${currentIndex + 1}/${_controller.videos.length}'
                : 'Video',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (_autoPlayEnabled.value) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.playlist_play, size: 14, color: Colors.green.shade700),
                const SizedBox(width: 4),
                Text(
                  'Tự động phát',
                  style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                ),
              ],
            ),
          ],
        ],
      );
    });
  }

  Widget _buildVideoList(BuildContext context, int crossAxisCount, bool isDesktop) {
    return Obx(() {
      if (_controller.videos.isEmpty) {
        return _buildEmptyState('Không có video tiếp theo');
      }

      final currentIndex = _controller.currentVideoIndex.value;
      final nextVideos = _controller.videos
          .asMap()
          .entries
          .where((entry) => entry.key != currentIndex)
          .map((entry) => entry.value)
          .toList();

      if (nextVideos.isEmpty) {
        return _buildEmptyState('Không có video tiếp theo');
      }

      return Column(
        children: [
          _buildSectionHeader(context, isDesktop),
          Expanded(
            child: crossAxisCount == 1
                ? _buildListView(nextVideos, context)
                : _buildGridView(nextVideos, context, crossAxisCount),
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.video_library_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, bool isDesktop) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Text(
            'Video tiếp theo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          if (isDesktop)
            TextButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.list, size: 16),
              label: const Text('Xem tất cả'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListView(List<YoutubeVideo> videos, BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical:12 ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final videoItem = videos[index];
        final actualIndex = _controller.videos.indexWhere((v) => v.id == videoItem.id);
        final isNext = actualIndex == _controller.currentVideoIndex.value + 1;

        return InfoCard(
          title: videoItem.title,
          subtitle: '${videoItem.channelTitle} • ${_formatDate(videoItem.publishedAt)}',
          subtitleStyle: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            height: 1.3,
          ),
          leading: SizedBox(
            width: 100,
            height: 58,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                videoItem.thumbnailUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.play_circle_outline, color: Colors.grey, size: 32),
                ),
              ),
            ),
          ),
          trailing: Icon(
            Icons.play_circle_outline,
            color: isNext ? Colors.green.shade200 : Colors.grey.shade400,
            size: 28,
          ),
          onTap: () => _handleVideoTap(videoItem, context),
          gradientStartColor: isNext ? AppColors.primary.withOpacity(0.05) : null,
          gradientEndColor: isNext ? AppColors.primary.withOpacity(0.05) : null,
        );
      },
    );
  }

  Widget _buildGridView(List<YoutubeVideo> videos, BuildContext context, int crossAxisCount) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 16 / 10,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final videoItem = videos[index];
        final actualIndex = _controller.videos.indexWhere((v) => v.id == videoItem.id);
        final isNext = actualIndex == _controller.currentVideoIndex.value + 1;

        return InfoCard(
          verticalLayout: true,
          leadingAspectRatio: 16 / 9,
          leading: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              videoItem.thumbnailUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade200,
                child: const Icon(
                  Icons.play_circle_outline,
                  size: 48,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
          overlay: isNext ? _buildNextBadge() : null,
          title: videoItem.title,
          subtitle: '${videoItem.channelTitle} • ${_formatDate(videoItem.publishedAt)}',
          subtitleStyle: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
            height: 1.2,
          ),
          onTap: () => _handleVideoTap(videoItem, context),
          gradientStartColor: isNext ? AppColors.primary.withOpacity(0.05) : null,
          gradientEndColor: isNext ? AppColors.primary.withOpacity(0.05) : null,
        );
      },
    );
  }

  Widget _buildNextBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade600.withOpacity(0.95),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_arrow, color: Colors.white, size: 16),
          SizedBox(width: 4),
          Text(
            'Tiếp theo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _handleVideoTap(YoutubeVideo nextVideo, BuildContext context) {
    final nextIndex = _controller.videos.indexWhere((v) => v.id == nextVideo.id);
    if (nextIndex != -1) {
      _controller.setCurrentVideoIndex(nextIndex);
    }

    _autoPlayEnabled.value = false;

    Get.snackbar(
      'Tự động phát',
      'Đã tắt để chỉ phát video này',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 1),
      margin: const EdgeInsets.all(16),
    );

    context.pushReplacement('/youtube/player/${nextVideo.id}', extra: nextVideo);
  }
}