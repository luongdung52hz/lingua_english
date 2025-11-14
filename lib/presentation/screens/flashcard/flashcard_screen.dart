import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:learn_english/presentation/screens/flashcard/widgets/delete_flashcard_dialog.dart';
import 'package:learn_english/presentation/screens/flashcard/widgets/flashcard_action_buttons.dart';
import 'package:learn_english/presentation/screens/flashcard/widgets/flashcard_list.dart';
import 'package:learn_english/presentation/screens/flashcard/widgets/folder_chips.dart';
import 'package:learn_english/presentation/screens/flashcard/widgets/move_to_folder_dialog.dart';
import 'package:learn_english/presentation/screens/flashcard/widgets/reset_all_dialog.dart';
import 'package:learn_english/presentation/widgets/search_bar.dart';
import '../../../data/models/flashcard_model.dart';
import '../../../resources/styles/colors.dart';
import '../../controllers/flashcard_controller.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../widgets/custom_sliver_appbar.dart';

class FlashcardListScreen extends StatefulWidget {
  const FlashcardListScreen({Key? key}) : super(key: key);

  @override
  State<FlashcardListScreen> createState() => _FlashcardListScreenState();
}

class _FlashcardListScreenState extends State<FlashcardListScreen> {
  late final FlashcardController controller;
  final TextEditingController searchController = TextEditingController();
  bool showOnlyUnmemorized = false;

  @override
  void initState() {
    super.initState();
    controller = Get.put(FlashcardController());
    searchController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Tự động reload mỗi khi quay lại trang
    _reloadData();
  }

  void _reloadData() {
    if (showOnlyUnmemorized) {
      controller.loadFlashcardsToReview(
        folderId: controller.currentFolderId.value != 'default'
            ? controller.currentFolderId.value
            : null,
      );
    } else {
      if (controller.currentFolderId.value == 'default') {
        controller.loadFlashcards();
      } else {
        controller.loadFlashcardsByFolder(
          controller.currentFolderId.value,
        );
      }
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            CustomSliverAppBar(
              icon: Icons.style_rounded,
              title: 'Flashcards',
              subtitle: 'Ôn tập từ vựng của bạn',
              expandedHeight: 90,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                  ),
                  color: Colors.grey[100],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'filter') {
                      final selected = !showOnlyUnmemorized;
                      setState(() => showOnlyUnmemorized = selected);

                      if (selected) {
                        controller.loadFlashcardsToReview(
                          folderId: controller.currentFolderId.value != 'default'
                              ? controller.currentFolderId.value
                              : null,
                        );
                      } else {
                        if (controller.currentFolderId.value == 'default') {
                          controller.loadFlashcards();
                        } else {
                          controller.loadFlashcardsByFolder(
                            controller.currentFolderId.value,
                          );
                        }
                      }
                    } else if (value == 'reset') {
                      _showResetAllDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'filter',
                      child: Row(
                        children: [
                          Icon(
                            showOnlyUnmemorized
                                ? Icons.filter_alt
                                : Icons.filter_alt_outlined,
                            size: 20,
                            color: showOnlyUnmemorized
                                ? AppColors.primary
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            showOnlyUnmemorized
                                ? 'Hiện tất cả'
                                : 'Từ chưa thuộc',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'reset',
                      child: Row(
                        children: [
                          Icon(Icons.restart_alt, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Reset tất cả',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ];
        },
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  SearchBarWidget(
                    controller: searchController,
                    onChanged: (value) => controller.searchFlashcards(value),
                    onClear: () {
                      if (controller.currentFolderId.value == 'default') {
                        controller.loadFlashcards();
                      } else {
                        controller.loadFlashcardsByFolder(controller.currentFolderId.value);
                      }
                    },
                  ),
                  Obx(() => ActionButtons(
                    onCreatePressed: () => context.push('/flashcards/create'),
                    onStudyPressed: () => context.push('/flashcards/study'),
                    studyEnabled: controller.hasUnmemorized.value,
                  )),
                  const FolderChips(),
                  const SizedBox(height: 2),
                ],
              ),
            ),
            Expanded(
              child: FlashcardList(
                searchText: searchController.text,
                showOnlyUnmemorized: showOnlyUnmemorized,
                onTapFlashcard: (flashcard) =>
                    context.push('/flashcards/detail/${flashcard.id}'),
                onToggleMemorized: (id, isMemorized) =>
                    controller.toggleMemorized(id, !isMemorized),
                onMoveToFolder: (flashcard) => _showMoveToFolderDialog(flashcard),
                onDeleteFlashcard: (flashcard) => _showDeleteFlashcardDialog(flashcard),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  void _showMoveToFolderDialog(Flashcard flashcard) {
    showDialog(
      context: context,
      builder: (context) => MoveToFolderDialog(
        flashcard: flashcard,
        onMove: (folderId) async {
          await controller.moveToFolder(flashcard.id!, folderId);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }

  void _showDeleteFlashcardDialog(Flashcard flashcard) {
    showDialog(
      context: context,
      builder: (context) => DeleteFlashcardDialog(
        flashcard: flashcard,
        onDelete: () {
          Navigator.pop(context);
          controller.deleteFlashcard(flashcard.id!);
        },
      ),
    );
  }

  void _showResetAllDialog() {
    showDialog(
      context: context,
      builder: (context) => ResetAllDialog(
        onReset: () => controller.resetAllFlashcards(),
      ),
    );
  }
}