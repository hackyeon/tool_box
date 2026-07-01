import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/ads/ad_support.dart';
import '../../core/ads/banner_ad_widget.dart';
import 'video_gif_models.dart';
import 'video_gif_view_model.dart';

class VideoGifPage extends StatefulWidget {
  const VideoGifPage({super.key});

  @override
  State<VideoGifPage> createState() => _VideoGifPageState();
}

class _VideoGifPageState extends State<VideoGifPage> {
  late final VideoGifViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = VideoGifViewModel();
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('움짤 만들기'),
            actions: [
              if (viewModel.hasSource)
                IconButton(
                  tooltip: '초기화',
                  onPressed: viewModel.isBusy ? null : viewModel.clearVideo,
                  icon: const Icon(Icons.restart_alt),
                ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            '동영상의 짧은 구간을 선택해 GIF 움짤로 변환할 수 있어요.',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 16),
                          _VideoPickerCard(
                            hasSource: viewModel.hasSource,
                            isSupported: viewModel.isSupported,
                            onTap: viewModel.pickVideo,
                          ),
                          if (viewModel.source == null) ...[
                            const SizedBox(height: 28),
                            const _EmptyState(),
                          ] else ...[
                            const SizedBox(height: 16),
                            _VideoInfoCard(source: viewModel.source!),
                            const SizedBox(height: 16),
                            _SettingsPanel(viewModel: viewModel),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 56,
                              child: FilledButton.icon(
                                onPressed: viewModel.canCreateGif
                                    ? viewModel.createGif
                                    : null,
                                icon: const Icon(Icons.gif_box_outlined),
                                label: const Text('GIF 만들기'),
                              ),
                            ),
                            if (viewModel.result != null) ...[
                              const SizedBox(height: 20),
                              _ResultPanel(viewModel: viewModel),
                            ],
                          ],
                          if (viewModel.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _MessageBanner(
                              message: viewModel.errorMessage!,
                              isError: true,
                            ),
                          ],
                          if (viewModel.noticeMessage != null) ...[
                            const SizedBox(height: 16),
                            _MessageBanner(
                              message: viewModel.noticeMessage!,
                              subMessage: viewModel.savedPath,
                              isError: false,
                            ),
                          ],
                          if (isMobileAdSupported) ...[
                            const SizedBox(height: 20),
                            const Center(child: BannerAdWidget()),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (viewModel.isBusy) _BusyOverlay(viewModel: viewModel),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VideoPickerCard extends StatelessWidget {
  const _VideoPickerCard({
    required this.hasSource,
    required this.isSupported,
    required this.onTap,
  });

  final bool hasSource;
  final bool isSupported;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: isSupported ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasSource ? Icons.change_circle_outlined : Icons.video_library,
              size: 42,
              color: isSupported
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).disabledColor,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasSource ? '동영상 바꾸기' : '동영상 선택',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSupported
                        ? 'MP4, MOV 등 기기에서 재생 가능한 동영상'
                        : 'Android와 iOS에서 사용할 수 있어요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_right),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 64),
      child: Text(
        '아직 선택된 동영상이 없습니다.',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _VideoInfoCard extends StatelessWidget {
  const _VideoInfoCard({required this.source});

  final VideoGifSource source;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final canCreate = source.canCreateGif;

    return Card(
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.movie_creation_outlined),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatDuration(source.duration)} · '
                        '${source.width} x ${source.height} · '
                        '${_formatBytes(source.sizeInBytes)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Chip(
              avatar: Icon(
                canCreate ? Icons.check_circle_outline : Icons.info_outline,
                size: 18,
              ),
              label: Text(
                canCreate
                    ? 'GIF 생성 가능'
                    : source.warningMessage ?? 'GIF 생성이 어려운 동영상이에요.',
              ),
              side: BorderSide(
                color: canCreate ? colorScheme.primary : colorScheme.error,
              ),
              backgroundColor: canCreate
                  ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                  : colorScheme.errorContainer.withValues(alpha: 0.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPanel extends StatelessWidget {
  const _SettingsPanel({required this.viewModel});

  final VideoGifViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: '시작 시간',
              trailing: _formatDuration(viewModel.startTime),
            ),
            const SizedBox(height: 10),
            _StartTimeSlider(viewModel: viewModel),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: viewModel.quickStartTimes.map((time) {
                final selected = time == viewModel.startTime;
                return ChoiceChip(
                  label: Text(_formatDuration(time)),
                  selected: selected,
                  onSelected: (_) => viewModel.setStartTime(time),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            const _SectionHeader(title: 'GIF 길이'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GifLengthOption.values.map((option) {
                final enabled = viewModel.canUseLength(option);
                return ChoiceChip(
                  label: Text(option.label),
                  selected: viewModel.length == option,
                  onSelected: enabled
                      ? (_) => viewModel.setLength(option)
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              'GIF는 길이가 길수록 파일 용량이 커질 수 있어요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            const _SectionHeader(title: '품질'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: GifQualityOption.values.map((option) {
                return ChoiceChip(
                  label: Text(option.label),
                  selected: viewModel.quality == option,
                  onSelected: (_) => viewModel.setQuality(option),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.quality.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _StartTimeSlider extends StatelessWidget {
  const _StartTimeSlider({required this.viewModel});

  final VideoGifViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final maxMilliseconds = viewModel.maxStartTime.inMilliseconds;
    final value = math.min(
      viewModel.startTime.inMilliseconds,
      math.max(0, maxMilliseconds),
    );

    return Slider(
      min: 0,
      max: maxMilliseconds <= 0 ? 1 : maxMilliseconds.toDouble(),
      divisions: maxMilliseconds <= 0
          ? null
          : math.max(1, math.min(240, maxMilliseconds ~/ 1000)),
      value: value.toDouble(),
      onChanged: maxMilliseconds <= 0
          ? null
          : (value) =>
                viewModel.setStartTime(Duration(milliseconds: value.round())),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.viewModel});

  final VideoGifViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final result = viewModel.result!;
    final colorScheme = Theme.of(context).colorScheme;
    final aspectRatio = result.width > 0 && result.height > 0
        ? result.width / result.height
        : 1.0;

    return Card(
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GIF가 완성되었어요.',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ColoredBox(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.55,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: AspectRatio(
                      aspectRatio: aspectRatio,
                      child: Image.memory(
                        result.bytes,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _InfoTile(
                  label: '파일 용량',
                  value: _formatBytes(result.sizeInBytes),
                ),
                _InfoTile(label: '길이', value: _formatDuration(result.duration)),
                _InfoTile(label: '품질', value: result.quality.label),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: viewModel.canSave ? viewModel.saveResult : null,
                  icon: const Icon(Icons.save_alt),
                  label: const Text('저장하기'),
                ),
                OutlinedButton.icon(
                  onPressed: viewModel.canShare ? viewModel.shareResult : null,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('공유하기'),
                ),
                TextButton.icon(
                  onPressed: viewModel.isBusy ? null : viewModel.makeAgain,
                  icon: const Icon(Icons.refresh),
                  label: const Text('다시 만들기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.isError,
    this.subMessage,
  });

  final String message;
  final String? subMessage;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = isError
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subMessage!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: foreground),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusyOverlay extends StatelessWidget {
  const _BusyOverlay({required this.viewModel});

  final VideoGifViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final isConverting = viewModel.isConverting;
    final message = isConverting
        ? 'GIF를 만들고 있어요. 잠시만 기다려주세요.'
        : viewModel.isLoadingVideo
        ? '동영상을 불러오고 있어요.'
        : viewModel.isSaving
        ? 'GIF를 저장하고 있어요.'
        : '공유 준비 중...';

    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: ModalBarrier(
              color: Colors.black.withValues(alpha: 0.30),
              dismissible: false,
            ),
          ),
          Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      value: isConverting && viewModel.progress > 0
                          ? viewModel.progress
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (isConverting)
                      Text(
                        '${viewModel.progressPercent}%',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    if (isConverting) const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (isConverting) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: viewModel.isCancelling
                            ? null
                            : viewModel.cancelConversion,
                        child: Text(viewModel.isCancelling ? '취소 중...' : '취소'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}

String _formatBytes(int bytes) {
  if (bytes <= 0) {
    return '0 KB';
  }

  const units = ['B', 'KB', 'MB', 'GB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex += 1;
  }

  if (unitIndex == 0) {
    return '${size.round()} ${units[unitIndex]}';
  }
  return '${size.toStringAsFixed(size >= 10 ? 1 : 2)} ${units[unitIndex]}';
}
