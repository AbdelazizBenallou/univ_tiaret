import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:univ_tiaret/l10n/app_localizations.dart';
import 'package:univ_tiaret/constants.dart';
import 'package:univ_tiaret/utils/file_utils.dart';

class MediaPlayerScreen extends StatefulWidget {
  final String filePath;
  final String fileName;
  final String fileType;

  const MediaPlayerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
    required this.fileType,
  });

  @override
  State<MediaPlayerScreen> createState() => _MediaPlayerScreenState();
}

class _MediaPlayerScreenState extends State<MediaPlayerScreen> {
  late final Player _player;
  late final VideoController _videoController;
  final List<StreamSubscription> _subs = [];

  bool _isAudio = false;
  bool _loading = true;
  String? _error;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _playing = false;
  bool _buffering = false;
  double _volume = 100;
  double _lastVolume = 100;
  bool _muted = false;
  double _rate = 1.0;

  bool _controlsVisible = true;
  Timer? _hideTimer;
  Timer? _saveTimer;
  bool _fullscreen = false;
  bool _dragging = false;
  double _dragValue = 0;

  String _aspect = 'auto';
  List<AudioTrack> _audioTracks = [];
  List<SubtitleTrack> _subtitleTracks = [];
  SubtitleTrack? _selectedSubtitle;

  double _resumeTo = 0;
  bool _resumeApplied = false;

  @override
  void initState() {
    super.initState();
    _isAudio = fileCategory(widget.fileType) == FileCategory.audio;
    _player = Player(
      configuration: const PlayerConfiguration(title: 'Univ Tiaret Player'),
    );
    _videoController = VideoController(_player);
    WakelockPlus.enable();
    _open();
  }

  Future<void> _open() async {
    final file = File(widget.filePath);
    if (!file.existsSync()) {
      if (mounted) {
        setState(() {
          _error = 'media_file_not_found';
          _loading = false;
        });
      }
      return;
    }

    _resumeTo = await _loadSavedPosition();

    _subs.addAll([
      _player.stream.playing.listen((v) {
        _setState(() => _playing = v);
        if (v) {
          _startSaveTimer();
        } else {
          _stopSaveTimer();
          if (_position.inSeconds > 0) _savePosition();
        }
      }),
      _player.stream.buffering.listen((v) => _setState(() => _buffering = v)),
      _player.stream.position.listen((v) => _setState(() => _position = v)),
      _player.stream.duration.listen((v) {
        _setState(() => _duration = v);
        if (v > Duration.zero) {
          _setState(() => _loading = false);
          if (_resumeTo > 0 && !_resumeApplied) {
            _resumeApplied = true;
            _player.seek(Duration(milliseconds: (_resumeTo * 1000).round()));
            _setState(
              () => _position = Duration(
                milliseconds: (_resumeTo * 1000).round(),
              ),
            );
          }
        }
      }),
      _player.stream.volume.listen(
        (v) => _setState(() {
          _volume = v;
          if (v > 0) _lastVolume = v;
        }),
      ),
      _player.stream.rate.listen((v) => _setState(() => _rate = v)),
      _player.stream.error.listen(
        (e) => _setState(() {
          _error ??= 'media_error';
          _loading = false;
        }),
      ),
      _player.stream.completed.listen((v) {
        if (v) {
          _setState(() => _playing = false);
          _stopSaveTimer();
          _clearSavedPosition();
        }
      }),
      _player.stream.tracks.listen(
        (t) => _setState(() {
          _audioTracks = t.audio;
          _subtitleTracks = t.subtitle;
          if (_selectedSubtitle == null ||
              !t.subtitle.any((tr) => tr.id == _selectedSubtitle?.id)) {
            _selectedSubtitle = null;
          }
        }),
      ),
    ]);

    try {
      await _player.open(Media(widget.filePath));
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'media_error';
          _loading = false;
        });
      }
    }
  }

  void _startSaveTimer() {
    _saveTimer ??= Timer.periodic(const Duration(seconds: 3), (_) {
      if (_position.inSeconds > 0) _savePosition();
    });
  }

  void _stopSaveTimer() {
    _saveTimer?.cancel();
    _saveTimer = null;
  }

  void _setState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  String get _positionKey => 'media_position_${widget.filePath}';

  Future<double> _loadSavedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_positionKey) ?? 0;
  }

  Future<void> _savePosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_positionKey, _position.inSeconds.toDouble());
  }

  Future<void> _clearSavedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_positionKey);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _stopSaveTimer();
    for (final s in _subs) {
      s.cancel();
    }
    _savePosition();
    WakelockPlus.disable();
    _restoreSystemUi();
    _player.dispose();
    super.dispose();
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (_playing) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && _playing) setState(() => _controlsVisible = false);
      });
    }
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    _scheduleHide();
  }

  void _toggleControls() {
    if (_controlsVisible) {
      setState(() => _controlsVisible = false);
      _hideTimer?.cancel();
    } else {
      _showControls();
    }
  }

  Future<void> _toggleFullscreen() async {
    setState(() => _fullscreen = !_fullscreen);
    if (_fullscreen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      await _restoreSystemUi();
    }
  }

  void _seekTo(double seconds) {
    final target = seconds.clamp(0.0, _duration.inMilliseconds / 1000);
    _player.seek(Duration(milliseconds: (target * 1000).round()));
  }

  void _skip(double delta) {
    final currentMs = _dragging
        ? _dragValue
        : _position.inMilliseconds.toDouble();
    _seekTo(currentMs / 1000 + delta);
  }

  void _togglePlay() {
    _player.playOrPause();
    _scheduleHide();
  }

  NativePlayer? get _nativePlayer {
    final p = _player.platform;
    return p is NativePlayer ? p : null;
  }

  Future<void> _applyMute(bool muted) async {
    final native = _nativePlayer;
    if (native != null) {
      try {
        await native.setProperty('mute', muted ? 'yes' : 'no');
      } catch (_) {
        await _player.setVolume(muted ? 0 : 100);
      }
    } else {
      await _player.setVolume(muted ? 0 : 100);
    }
  }

  void _setVolume(double v) {
    _lastVolume = v;
    _player.setVolume(v);
    if (v > 0 && _muted) {
      _muted = false;
      _applyMute(false);
    }
    _setState(() => _volume = v);
  }

  void _toggleMute() {
    _muted = !_muted;
    if (_muted) {
      _applyMute(true);
    } else {
      final restore = _lastVolume <= 0 ? 100.0 : _lastVolume;
      _lastVolume = restore;
      _setState(() => _volume = restore);
      _applyMute(false);
      _player.setVolume(restore);
    }
  }

  void _setRate(double r) {
    _player.setRate(r);
    _showControls();
  }

  void _setAspect(String a) {
    _setState(() => _aspect = a);
  }

  void _openExternally() {
    OpenFilex.open(widget.filePath);
  }

  String _format(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white70),
            )
          else if (_error != null)
            _buildError()
          else ...[
            if (_isAudio) _buildAudioArea() else _buildVideoArea(),
            if (!_isAudio && !_playing && _controlsVisible) _buildCenterPlay(),
            if (_controlsVisible) ...[_buildTopBar(), _buildBottomBar()],
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    final t = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _error == 'media_file_not_found'
                  ? t.translate('media_file_not_found')
                  : t.translate('media_error'),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: _openExternally,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(t.translate('media_open_external')),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(t.translate('back')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoArea() {
    Widget video = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Video(
        controller: _videoController,
        fit: BoxFit.contain,
        controls: NoVideoControls,
      ),
    );

    switch (_aspect) {
      case '16:9':
        video = AspectRatio(aspectRatio: 16 / 9, child: video);
        break;
      case '4:3':
        video = AspectRatio(aspectRatio: 4 / 3, child: video);
        break;
      case '1:1':
        video = AspectRatio(aspectRatio: 1, child: video);
        break;
      case '2.35:1':
        video = AspectRatio(aspectRatio: 2.35, child: video);
        break;
    }

    return Center(
      child: _aspect == 'auto'
          ? video
          : Container(color: Colors.black, child: video),
    );
  }

  Widget _buildCenterPlay() {
    return Center(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _togglePlay,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white70, width: 2),
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            size: 44,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildAudioArea() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleControls,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              const Color(0xFF0B2B47),
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _playing
                        ? Icons.graphic_eq_rounded
                        : Icons.music_note_rounded,
                    size: 84,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  widget.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _playing ? _format(_position) : widget.fileType.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final t = AppLocalizations.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 28),
                color: Colors.white,
                tooltip: t.translate('back'),
              ),
              Expanded(
                child: Text(
                  widget.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!_isAudio)
                IconButton(
                  onPressed: _toggleFullscreen,
                  icon: Icon(
                    _fullscreen
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded,
                    size: 28,
                  ),
                  color: Colors.white,
                  tooltip: _fullscreen
                      ? t.translate('media_exit_fullscreen')
                      : t.translate('media_fullscreen'),
                ),
              IconButton(
                onPressed: () => _showMoreSheet(context),
                icon: const Icon(Icons.more_vert_rounded, size: 28),
                color: Colors.white,
                tooltip: t.translate('media_more'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMoreSheet(BuildContext context) async {
    final t = AppLocalizations.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sheetHeader(t.translate('media_speed')),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0])
                    ChoiceChip(
                      label: Text('${r}x'),
                      selected: (r - _rate).abs() < 0.001,
                      selectedColor: AppColors.primaryColor,
                      onSelected: (_) {
                        _setRate(r);
                        Navigator.pop(ctx);
                      },
                    ),
                ],
              ),
              if (!_isAudio) ...[
                const SizedBox(height: 24),
                _sheetHeader(t.translate('media_aspect')),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final a in ['auto', '16:9', '4:3', '1:1', '2.35:1'])
                      ChoiceChip(
                        label: Text(
                          a == 'auto' ? t.translate('media_aspect_auto') : a,
                        ),
                        selected: a == _aspect,
                        selectedColor: AppColors.primaryColor,
                        onSelected: (_) {
                          _setAspect(a);
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ],
              if (_audioTracks.length > 1) ...[
                const SizedBox(height: 24),
                _sheetHeader(t.translate('media_audio_tracks')),
                const SizedBox(height: 8),
                for (final track in _audioTracks)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white70,
                    ),
                    title: Text(
                      track.title ?? track.id,
                      style: const TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      _player.setAudioTrack(track);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
              if (_subtitleTracks.isNotEmpty) ...[
                const SizedBox(height: 24),
                _sheetHeader(t.translate('media_subtitles')),
                const SizedBox(height: 8),
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.closed_caption_off_rounded,
                    color: Colors.white70,
                  ),
                  title: Text(
                    t.translate('media_subtitles_off'),
                    style: const TextStyle(color: Colors.white),
                  ),
                  trailing: _selectedSubtitle == null
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.primaryColor,
                        )
                      : null,
                  onTap: () {
                    _selectedSubtitle = null;
                    _player.setSubtitleTrack(SubtitleTrack.no());
                    Navigator.pop(ctx);
                  },
                ),
                for (final track in _subtitleTracks)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.closed_caption_rounded,
                      color: Colors.white70,
                    ),
                    title: Text(
                      track.title ?? track.id,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: _selectedSubtitle?.id == track.id
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primaryColor,
                          )
                        : null,
                    onTap: () {
                      _selectedSubtitle = track;
                      _player.setSubtitleTrack(track);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildBottomBar() {
    final t = AppLocalizations.of(context);
    final total = _duration.inMilliseconds.toDouble();
    final currentMs = _dragging
        ? _dragValue
        : _position.inMilliseconds.toDouble().clamp(0.0, total);
    final sliderValue = total > 0 ? currentMs.clamp(0.0, total) : 0.0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      _format(
                        _dragging
                            ? Duration(milliseconds: _dragValue.round())
                            : _position,
                      ),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          activeTrackColor: AppColors.primaryColor,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16,
                          ),
                          overlayColor: Colors.white24,
                        ),
                        child: Slider(
                          min: 0,
                          max: total > 0 ? total : 1,
                          value: sliderValue,
                          onChangeStart: (v) => setState(() {
                            _dragging = true;
                            _dragValue = v;
                          }),
                          onChanged: (v) => setState(() {
                            _dragValue = v;
                          }),
                          onChangeEnd: (v) {
                            _player.seek(Duration(milliseconds: v.round()));
                            setState(() {
                              _dragging = false;
                              _position = Duration(milliseconds: v.round());
                            });
                            _scheduleHide();
                          },
                        ),
                      ),
                    ),
                    Text(
                      _format(_duration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: _toggleMute,
                            icon: Icon(
                              _muted || _volume == 0
                                  ? Icons.volume_off_rounded
                                  : Icons.volume_up_rounded,
                              size: 26,
                            ),
                            color: Colors.white,
                            tooltip: t.translate('media_volume'),
                          ),
                          Expanded(
                            child: Slider(
                              value: _muted ? 0 : _volume.clamp(0, 100),
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                              onChanged: _setVolume,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _skip(-10),
                      icon: const Icon(Icons.replay_10_rounded, size: 34),
                      color: Colors.white,
                      tooltip: '10',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: _buffering
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : IconButton(
                              onPressed: _togglePlay,
                              icon: Icon(
                                _playing
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_fill_rounded,
                                size: 48,
                              ),
                              color: Colors.white,
                              tooltip: _playing
                                  ? t.translate('media_pause')
                                  : t.translate('media_play'),
                            ),
                    ),
                    IconButton(
                      onPressed: () => _skip(10),
                      icon: const Icon(Icons.forward_10_rounded, size: 34),
                      color: Colors.white,
                      tooltip: '10',
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _showMoreSheet(context),
                            child: Text(
                              '${_rate}x',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!_isAudio)
                            IconButton(
                              onPressed: _toggleFullscreen,
                              icon: Icon(
                                _fullscreen
                                    ? Icons.fullscreen_exit_rounded
                                    : Icons.fullscreen_rounded,
                                size: 26,
                              ),
                              color: Colors.white,
                              tooltip: _fullscreen
                                  ? t.translate('media_exit_fullscreen')
                                  : t.translate('media_fullscreen'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
