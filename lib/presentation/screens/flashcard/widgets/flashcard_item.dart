// lib/ui/widgets/flashcard_item.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/flashcard_model.dart';

class FlashcardItem extends StatelessWidget {
  final Flashcard flashcard;
  final VoidCallback onTap;
  final VoidCallback onToggleMemorized;
  final VoidCallback onMoveToFolder;
  final VoidCallback onDelete;

  const FlashcardItem({
    Key? key,
    required this.flashcard,
    required this.onTap,
    required this.onToggleMemorized,
    required this.onMoveToFolder,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.grey.shade100,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 30,
                decoration: BoxDecoration(
                  color: flashcard.isMemorized ? Colors.green.shade400 : Colors.orange.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 10),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flashcard.vietnamese,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(children: [
                      Text(
                        flashcard.english,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 10,),
                      Text(
                        (flashcard.phonetic ?? '').toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 10,),
                      if (flashcard.partOfSpeech != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            flashcard.partOfSpeech!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],),

                  ],
                ),
              ),
              // Actions
              // PopupMenuButton<String>(
              //   onSelected: (value) {
              //     switch (value) {
              //       case 'toggle':
              //         onToggleMemorized();
              //         break;
              //       case 'move':
              //         onMoveToFolder();
              //         break;
              //       case 'delete':
              //         onDelete();
              //         break;
              //     }
              //   },
              //   itemBuilder: (context) => [
              //     PopupMenuItem(
              //       value: 'toggle',
              //       child: Row(
              //         children: [
              //           Icon(
              //             flashcard.isMemorized ? Icons.cancel : Icons.check_circle,
              //             size: 20,
              //             color: flashcard.isMemorized ? Colors.orange : Colors.green,
              //           ),
              //           const SizedBox(width: 8),
              //           Text(flashcard.isMemorized ? 'Chưa thuộc' : 'Đã thuộc'),
              //         ],
              //       ),
              //     ),
              //     const PopupMenuItem(
              //       value: 'move',
              //       child: Row(
              //         children: [
              //           Icon(Icons.drive_file_move, size: 20, color: Colors.blue),
              //           SizedBox(width: 8),
              //           Text('Chuyển thư mục'),
              //         ],
              //       ),
              //     ),
              //     const PopupMenuItem(
              //       value: 'delete',
              //       child: Row(
              //         children: [
              //           Icon(Icons.delete, size: 20, color: Colors.red),
              //           SizedBox(width: 8),
              //           Text('Xóa'),
              //         ],
              //       ),
              //     ),
              //   ],
              //   icon: const Icon(Icons.more_vert,color: Colors.grey,),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}