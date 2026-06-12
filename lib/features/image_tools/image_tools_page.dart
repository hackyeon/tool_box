import 'dart:math' as math;

import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/ads/ad_support.dart';
import '../../core/ads/banner_ad_widget.dart';
import 'image_processor.dart';
import 'image_tools_view_model.dart';

class ImageToolsPage extends StatefulWidget {
  const ImageToolsPage({super.key});

  @override
  State<ImageToolsPage> createState() => _ImageToolsPageState();
}

class _ImageToolsPageState extends State<ImageToolsPage> {
  late final ImageToolsViewModel viewModel;
  late final TextEditingController _widthController;
  late final TextEditingController _heightController;
  late final FocusNode _widthFocusNode;
  late final FocusNode _heightFocusNode;

  @override
  void initState() {
    super.initState();
    viewModel = ImageToolsViewModel()..addListener(_syncDimensionFields);
    _widthController = TextEditingController();
    _heightController = TextEditingController();
    _widthFocusNode = FocusNode();
    _heightFocusNode = FocusNode();
  }

  @override
  void dispose() {
    viewModel
      ..removeListener(_syncDimensionFields)
      ..dispose();
    _widthController.dispose();
    _heightController.dispose();
    _widthFocusNode.dispose();
    _heightFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('이미지 도구'),
            actions: [
              if (viewModel.hasSource)
                IconButton(
                  tooltip: '초기화',
                  onPressed: viewModel.clearImage,
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
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _UploadArea(
                            hasSource: viewModel.hasSource,
                            onTap: viewModel.pickImage,
                            onDropFiles: _handleDroppedFiles,
                          ),
                          const SizedBox(height: 20),
                          if (viewModel.source == null)
                            const _EmptyState()
                          else ...[
                            _SummaryStrip(viewModel: viewModel),
                            const SizedBox(height: 20),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isWide = constraints.maxWidth >= 900;
                                if (isWide) {
                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _PreviewPanel(
                                          viewModel: viewModel,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      SizedBox(
                                        width: 360,
                                        child: _ControlPanel(
                                          viewModel: viewModel,
                                          widthController: _widthController,
                                          heightController: _heightController,
                                          widthFocusNode: _widthFocusNode,
                                          heightFocusNode: _heightFocusNode,
                                        ),
                                      ),
                                    ],
                                  );
                                }

                                return Column(
                                  children: [
                                    _PreviewPanel(viewModel: viewModel),
                                    const SizedBox(height: 20),
                                    _ControlPanel(
                                      viewModel: viewModel,
                                      widthController: _widthController,
                                      heightController: _heightController,
                                      widthFocusNode: _widthFocusNode,
                                      heightFocusNode: _heightFocusNode,
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                          if (viewModel.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            _ErrorBanner(message: viewModel.errorMessage!),
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
                if (viewModel.isProcessing || viewModel.isSharing)
                  Positioned.fill(
                    child: AbsorbPointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.28),
                        child: Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  Text(
                                    viewModel.isSharing
                                        ? '저장 준비 중...'
                                        : '이미지 처리 중...',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _syncDimensionFields() {
    if (!_widthFocusNode.hasFocus) {
      _setControllerText(
        _widthController,
        viewModel.targetWidth?.toString() ?? '',
      );
    }

    if (!_heightFocusNode.hasFocus) {
      _setControllerText(
        _heightController,
        viewModel.targetHeight?.toString() ?? '',
      );
    }
  }

  void _setControllerText(TextEditingController controller, String text) {
    if (controller.text == text) {
      return;
    }

    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    final imageFiles = files.where(_isSupportedImageFile).toList();
    if (imageFiles.isEmpty) {
      return;
    }

    await viewModel.addImageFromFile(imageFiles.first);
  }

  bool _isSupportedImageFile(XFile file) {
    final name = file.name.toLowerCase();
    return name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.png') ||
        name.endsWith('.webp');
  }
}

class _UploadArea extends StatefulWidget {
  const _UploadArea({
    required this.hasSource,
    required this.onTap,
    required this.onDropFiles,
  });

  final bool hasSource;
  final VoidCallback onTap;
  final ValueChanged<List<XFile>> onDropFiles;

  @override
  State<_UploadArea> createState() => _UploadAreaState();
}

class _UploadAreaState extends State<_UploadArea> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragging = true),
      onDragExited: (_) => setState(() => _isDragging = false),
      onDragDone: (detail) {
        setState(() => _isDragging = false);
        widget.onDropFiles(detail.files);
      },
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          decoration: BoxDecoration(
            color: _isDragging
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isDragging
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outlineVariant,
              width: _isDragging ? 2 : 1,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 420;
              final title = widget.hasSource
                  ? '이미지 바꾸기'
                  : isCompact
                  ? '이미지 선택'
                  : kIsWeb
                  ? '이미지를 선택하거나 드래그하세요'
                  : '이미지를 선택하세요';

              return Row(
                children: [
                  Icon(
                    widget.hasSource
                        ? Icons.change_circle_outlined
                        : Icons.add_photo_alternate_outlined,
                    size: 40,
                    color: _isDragging
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG, WEBP',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_right),
                ],
              );
            },
          ),
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
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Text(
        '선택된 이미지가 없습니다.',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.viewModel});

  final ImageToolsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final source = viewModel.source!;
    final result = viewModel.result;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _StatTile(
              label: '원본',
              value: _formatBytes(source.info.sizeInBytes),
              subValue: '${source.info.width} x ${source.info.height}',
            ),
            _StatTile(
              label: '처리 후',
              value: result == null
                  ? '-'
                  : _formatBytes(result.info.sizeInBytes),
              subValue: result == null
                  ? '대기'
                  : '${result.info.width} x ${result.info.height}',
            ),
            _StatTile(
              label: '감소율',
              value: viewModel.reductionPercent == null
                  ? '-'
                  : '${viewModel.reductionPercent}%',
              subValue: result == null ? '처리 전' : result.format.label,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.subValue,
  });

  final String label;
  final String value;
  final String subValue;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
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
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.viewModel});

  final ImageToolsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final source = viewModel.source!;
    final result = viewModel.result;
    final previewBytes = result?.bytes ?? source.bytes;
    final previewInfo = result?.info ?? source.info;

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    source.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (result != null)
                  Chip(
                    avatar: const Icon(Icons.check, size: 16),
                    label: const Text('완료'),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                return _PreviewFrame(
                  bytes: previewBytes,
                  info: previewInfo,
                  cropEnabled: result == null && viewModel.cropAspect.isEnabled,
                  cropRect: viewModel.cropRect,
                  cropAspectRatio: viewModel.cropAspect.aspectRatio,
                  onCropChanged: viewModel.setCropRect,
                  maxWidth: constraints.maxWidth,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame({
    required this.bytes,
    required this.info,
    required this.cropEnabled,
    required this.cropRect,
    required this.cropAspectRatio,
    required this.onCropChanged,
    required this.maxWidth,
  });

  final Uint8List bytes;
  final ImageFileInfo info;
  final bool cropEnabled;
  final NormalizedCropRect cropRect;
  final double? cropAspectRatio;
  final ValueChanged<NormalizedCropRect> onCropChanged;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    const maxHeight = 520.0;
    final aspectRatio = info.aspectRatio;
    var width = maxWidth;
    var height = width / aspectRatio;

    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspectRatio;
    }

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(bytes, fit: BoxFit.contain),
                if (cropEnabled)
                  _CropOverlay(
                    rect: cropRect,
                    imageAspectRatio: aspectRatio,
                    cropAspectRatio: cropAspectRatio,
                    onChanged: onCropChanged,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _CropHandle { topLeft, topRight, bottomLeft, bottomRight }

class _CropOverlay extends StatelessWidget {
  const _CropOverlay({
    required this.rect,
    required this.imageAspectRatio,
    required this.cropAspectRatio,
    required this.onChanged,
  });

  final NormalizedCropRect rect;
  final double imageAspectRatio;
  final double? cropAspectRatio;
  final ValueChanged<NormalizedCropRect> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final overlayRect = Rect.fromLTRB(
          rect.left * size.width,
          rect.top * size.height,
          rect.right * size.width,
          rect.bottom * size.height,
        );

        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _CropScrimPainter(rect: overlayRect)),
            ),
            Positioned.fromRect(
              rect: overlayRect,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) => _move(details.delta, size),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            _CropHandleWidget(
              rect: overlayRect,
              handle: _CropHandle.topLeft,
              onPanUpdate: (delta) => _resize(delta, size, _CropHandle.topLeft),
            ),
            _CropHandleWidget(
              rect: overlayRect,
              handle: _CropHandle.topRight,
              onPanUpdate: (delta) =>
                  _resize(delta, size, _CropHandle.topRight),
            ),
            _CropHandleWidget(
              rect: overlayRect,
              handle: _CropHandle.bottomLeft,
              onPanUpdate: (delta) =>
                  _resize(delta, size, _CropHandle.bottomLeft),
            ),
            _CropHandleWidget(
              rect: overlayRect,
              handle: _CropHandle.bottomRight,
              onPanUpdate: (delta) =>
                  _resize(delta, size, _CropHandle.bottomRight),
            ),
          ],
        );
      },
    );
  }

  void _move(Offset delta, Size size) {
    final dx = delta.dx / size.width;
    final dy = delta.dy / size.height;
    final width = rect.width;
    final height = rect.height;
    final left = (rect.left + dx).clamp(0.0, 1.0 - width);
    final top = (rect.top + dy).clamp(0.0, 1.0 - height);

    onChanged(
      NormalizedCropRect(
        left: left,
        top: top,
        right: left + width,
        bottom: top + height,
      ),
    );
  }

  void _resize(Offset delta, Size size, _CropHandle handle) {
    final dx = delta.dx / size.width;
    final dy = delta.dy / size.height;
    final normalizedAspectRatio = cropAspectRatio == null
        ? null
        : cropAspectRatio! / imageAspectRatio;

    if (normalizedAspectRatio == null) {
      onChanged(_resizeFreely(dx, dy, handle));
      return;
    }

    onChanged(_resizeWithAspectRatio(dx, dy, handle, normalizedAspectRatio));
  }

  NormalizedCropRect _resizeFreely(double dx, double dy, _CropHandle handle) {
    const minSize = 0.08;
    var left = rect.left;
    var top = rect.top;
    var right = rect.right;
    var bottom = rect.bottom;

    switch (handle) {
      case _CropHandle.topLeft:
        left = (left + dx).clamp(0.0, right - minSize);
        top = (top + dy).clamp(0.0, bottom - minSize);
      case _CropHandle.topRight:
        right = (right + dx).clamp(left + minSize, 1.0);
        top = (top + dy).clamp(0.0, bottom - minSize);
      case _CropHandle.bottomLeft:
        left = (left + dx).clamp(0.0, right - minSize);
        bottom = (bottom + dy).clamp(top + minSize, 1.0);
      case _CropHandle.bottomRight:
        right = (right + dx).clamp(left + minSize, 1.0);
        bottom = (bottom + dy).clamp(top + minSize, 1.0);
    }

    return NormalizedCropRect(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
    );
  }

  NormalizedCropRect _resizeWithAspectRatio(
    double dx,
    double dy,
    _CropHandle handle,
    double normalizedAspectRatio,
  ) {
    const minWidth = 0.08;
    final growsRight =
        handle == _CropHandle.topRight || handle == _CropHandle.bottomRight;
    final growsDown =
        handle == _CropHandle.bottomLeft || handle == _CropHandle.bottomRight;
    final anchorX = growsRight ? rect.left : rect.right;
    final anchorY = growsDown ? rect.top : rect.bottom;

    final candidateWidth = rect.width + (growsRight ? dx : -dx);
    final candidateHeight = rect.height + (growsDown ? dy : -dy);
    var width = dx.abs() >= dy.abs()
        ? candidateWidth
        : candidateHeight * normalizedAspectRatio;
    var height = width / normalizedAspectRatio;

    final maxWidth = growsRight ? 1 - anchorX : anchorX;
    final maxHeight = growsDown ? 1 - anchorY : anchorY;
    final boundedMaxWidth = math.min(
      maxWidth,
      maxHeight * normalizedAspectRatio,
    );

    width = width.clamp(minWidth, boundedMaxWidth);
    height = width / normalizedAspectRatio;

    final left = growsRight ? anchorX : anchorX - width;
    final top = growsDown ? anchorY : anchorY - height;

    return NormalizedCropRect(
      left: left,
      top: top,
      right: left + width,
      bottom: top + height,
    ).clamped();
  }
}

class _CropHandleWidget extends StatelessWidget {
  const _CropHandleWidget({
    required this.rect,
    required this.handle,
    required this.onPanUpdate,
  });

  final Rect rect;
  final _CropHandle handle;
  final ValueChanged<Offset> onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final offset = switch (handle) {
      _CropHandle.topLeft => rect.topLeft,
      _CropHandle.topRight => rect.topRight,
      _CropHandle.bottomLeft => rect.bottomLeft,
      _CropHandle.bottomRight => rect.bottomRight,
    };

    return Positioned(
      left: offset.dx - 14,
      top: offset.dy - 14,
      width: 28,
      height: 28,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onPanUpdate(details.delta),
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              border: Border.all(
                color: Theme.of(context).colorScheme.surface,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(width: 12, height: 12),
          ),
        ),
      ),
    );
  }
}

class _CropScrimPainter extends CustomPainter {
  const _CropScrimPainter({required this.rect});

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final scrimPaint = Paint()..color = Colors.black.withValues(alpha: 0.42);
    final borderPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(rect);
    canvas.drawPath(borderPath, scrimPaint);

    final guidePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.72)
      ..strokeWidth = 1;

    for (var i = 1; i <= 2; i += 1) {
      final dx = rect.left + rect.width * i / 3;
      final dy = rect.top + rect.height * i / 3;
      canvas.drawLine(
        Offset(dx, rect.top),
        Offset(dx, rect.bottom),
        guidePaint,
      );
      canvas.drawLine(
        Offset(rect.left, dy),
        Offset(rect.right, dy),
        guidePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropScrimPainter oldDelegate) {
    return oldDelegate.rect != rect;
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.viewModel,
    required this.widthController,
    required this.heightController,
    required this.widthFocusNode,
    required this.heightFocusNode,
  });

  final ImageToolsViewModel viewModel;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final FocusNode widthFocusNode;
  final FocusNode heightFocusNode;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionTitle(icon: Icons.compress, title: '압축'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ImageToolsViewModel.qualityOptions.map((quality) {
                return ChoiceChip(
                  label: Text('$quality%'),
                  selected: viewModel.quality == quality,
                  onSelected: (_) => viewModel.setQuality(quality),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            _SectionTitle(icon: Icons.image_outlined, title: '포맷'),
            const SizedBox(height: 12),
            SegmentedButton<ImageOutputFormat>(
              segments: ImageOutputFormat.values.map((format) {
                return ButtonSegment(value: format, label: Text(format.label));
              }).toList(),
              selected: {viewModel.outputFormat},
              onSelectionChanged: (selection) =>
                  viewModel.setOutputFormat(selection.first),
            ),
            const SizedBox(height: 22),
            _ResizeControls(
              viewModel: viewModel,
              widthController: widthController,
              heightController: heightController,
              widthFocusNode: widthFocusNode,
              heightFocusNode: heightFocusNode,
            ),
            const SizedBox(height: 22),
            _SectionTitle(icon: Icons.crop, title: '자르기'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CropAspectOption.values.map((aspect) {
                return ChoiceChip(
                  label: Text(aspect.label),
                  selected: viewModel.cropAspect == aspect,
                  onSelected: (_) => viewModel.setCropAspect(aspect),
                );
              }).toList(),
            ),
            const SizedBox(height: 22),
            _SectionTitle(icon: Icons.rotate_90_degrees_ccw, title: '회전 / 뒤집기'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ToolIconButton(
                  tooltip: '왼쪽으로 회전',
                  icon: Icons.rotate_left,
                  onPressed: viewModel.rotateLeft,
                ),
                _ToolIconButton(
                  tooltip: '오른쪽으로 회전',
                  icon: Icons.rotate_right,
                  onPressed: viewModel.rotateRight,
                ),
                _ToolIconButton(
                  tooltip: '180도 회전',
                  icon: Icons.rotate_90_degrees_ccw,
                  onPressed: viewModel.rotateHalfTurn,
                ),
                _ToolIconButton(
                  tooltip: '좌우반전',
                  icon: Icons.flip,
                  selected: viewModel.flipHorizontal,
                  onPressed: viewModel.toggleFlipHorizontal,
                ),
                _ToolIconButton(
                  tooltip: '상하반전',
                  icon: Icons.flip,
                  selected: viewModel.flipVertical,
                  quarterTurns: 1,
                  onPressed: viewModel.toggleFlipVertical,
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: viewModel.canProcess ? viewModel.processImage : null,
              icon: const Icon(Icons.tune),
              label: const Text('이미지 처리하기'),
            ),
            if (viewModel.result != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: viewModel.canShare ? viewModel.shareResult : null,
                icon: const Icon(Icons.download),
                label: const Text('저장 / 공유'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResizeControls extends StatelessWidget {
  const _ResizeControls({
    required this.viewModel,
    required this.widthController,
    required this.heightController,
    required this.widthFocusNode,
    required this.heightFocusNode,
  });

  final ImageToolsViewModel viewModel;
  final TextEditingController widthController;
  final TextEditingController heightController;
  final FocusNode widthFocusNode;
  final FocusNode heightFocusNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionTitle(icon: Icons.aspect_ratio, title: '크기'),
            ),
            Switch(
              value: viewModel.resizeEnabled,
              onChanged: viewModel.setResizeEnabled,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: widthController,
                focusNode: widthFocusNode,
                enabled: viewModel.resizeEnabled,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '너비',
                  border: OutlineInputBorder(),
                  suffixText: 'px',
                ),
                onChanged: (value) =>
                    viewModel.setTargetWidth(int.tryParse(value)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: heightController,
                focusNode: heightFocusNode,
                enabled: viewModel.resizeEnabled,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: '높이',
                  border: OutlineInputBorder(),
                  suffixText: 'px',
                ),
                onChanged: (value) =>
                    viewModel.setTargetHeight(int.tryParse(value)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: viewModel.maintainAspectRatio,
          onChanged: viewModel.resizeEnabled
              ? (value) => viewModel.setMaintainAspectRatio(value ?? true)
              : null,
          title: const Text('비율 유지'),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ImageToolsViewModel.resizePresets.map((preset) {
            return ActionChip(
              label: Text(preset.label),
              avatar: const Icon(Icons.crop_landscape, size: 18),
              onPressed: () => viewModel.applyResizePreset(preset),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _ToolIconButton extends StatelessWidget {
  const _ToolIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
    this.quarterTurns = 0,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        style: IconButton.styleFrom(
          fixedSize: const Size.square(44),
          backgroundColor: selected
              ? colorScheme.primaryContainer
              : colorScheme.surface,
          foregroundColor: selected
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurface,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        onPressed: onPressed,
        icon: RotatedBox(quarterTurns: quarterTurns, child: Icon(icon)),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '${bytes}B';
  }

  final kb = bytes / 1024;
  if (kb < 1024) {
    return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)}KB';
  }

  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb >= 100 ? 0 : 1)}MB';
}
