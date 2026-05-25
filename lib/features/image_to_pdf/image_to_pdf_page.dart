import 'package:flutter/material.dart';

import '../../core/ads/banner_ad_widget.dart';
import 'image_to_pdf_view_model.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';

class ImageToPdfPage extends StatefulWidget {
  const ImageToPdfPage({super.key});

  @override
  State<ImageToPdfPage> createState() => _ImageToPdfPageState();
}

class _ImageToPdfPageState extends State<ImageToPdfPage> {
  late final ImageToPdfViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = ImageToPdfViewModel();
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
            title: const Text('EZ PDF'),
            actions: [
              if (viewModel.images.isNotEmpty)
                IconButton(
                  onPressed: viewModel.clearImages,
                  icon: const Icon(Icons.restart_alt),
                ),
            ],
          ),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _UploadArea(
                      onTap: () => viewModel.pickImages(context),
                      onDropFiles: viewModel.addImagesFromFiles,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Text(
                            '선택된 이미지 ${viewModel.images.length}장',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: viewModel.images.isEmpty
                          ? const _EmptyView()
                          : _ImageList(
                        viewModel: viewModel,
                      ),
                    ),
                    if (!kIsWeb)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: BannerAdWidget(),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: viewModel.canCreatePdf
                              ? viewModel.createPdf
                              : null,
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF 생성하기'),
                        ),
                      ),
                    ),
                  ],
                ),

                if (viewModel.isLoading)
                  Positioned.fill(
                    child: AbsorbPointer(
                      absorbing: true,
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                        child: Center(
                          child: Container(
                            width: 180,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  value: viewModel.progress == 0
                                      ? null
                                      : viewModel.progress,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '${viewModel.progressPercent}%',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                const Text('PDF 생성 중...'),
                              ],
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
}

class _UploadArea extends StatefulWidget {
  final VoidCallback onTap;
  final ValueChanged<List<XFile>> onDropFiles;

  const _UploadArea({
    required this.onTap,
    required this.onDropFiles,
  });

  @override
  State<_UploadArea> createState() => _UploadAreaState();
}

class _UploadAreaState extends State<_UploadArea> {
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) {
        setState(() {
          isDragging = true;
        });
      },
      onDragExited: (_) {
        setState(() {
          isDragging = false;
        });
      },
      onDragDone: (detail) {
        setState(() {
          isDragging = false;
        });

        final imageFiles = detail.files.where((file) {
          final name = file.name.toLowerCase();
          return name.endsWith('.jpg') ||
              name.endsWith('.jpeg') ||
              name.endsWith('.png') ||
              name.endsWith('.webp');
        }).toList();

        widget.onDropFiles(imageFiles);
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: 36,
              horizontal: 20,
            ),
            decoration: BoxDecoration(
              color: isDragging
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                width: isDragging ? 2 : 1,
                color: isDragging
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 48,
                  color: isDragging
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  isDragging ? '여기에 이미지를 놓으세요' : kIsWeb ? '이미지를 선택하거나 드래그하세요' : '이미지를 선택하세요',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('여러 장을 선택하면 PDF로 변환됩니다.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('아직 선택된 이미지가 없습니다.'),
    );
  }
}

class _ImageList extends StatelessWidget {
  final ImageToPdfViewModel viewModel;

  const _ImageList({
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: viewModel.images.length,
      onReorder: viewModel.reorderImages,

      buildDefaultDragHandles: false,

      itemBuilder: (context, index) {
        final image = viewModel.images[index];

        return Card(
          key: ValueKey('${image.name}_$index'),
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                image.bytes,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              image.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('${index + 1}번째 페이지'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => viewModel.removeImage(index),
                  icon: const Icon(Icons.close),
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}