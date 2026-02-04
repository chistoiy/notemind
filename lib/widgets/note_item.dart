
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'dart:io';
import '../models/note.dart';

class NoteItem extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  const NoteItem({
    Key? key,
    required this.note,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: '编辑',
          ),
          SlidableAction(
            onPressed: (_) => onPin(),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: note.isPinned ? Icons.push_pin_outlined : Icons.push_pin,
            label: note.isPinned ? '取消置顶' : '置顶',
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
          ),
        ],
      ),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题和置顶标识
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        note.title.isNotEmpty ? note.title : '无标题',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    if (note.isPinned)
                      Icon(Icons.push_pin, color: Colors.orange, size: 16),
                  ],
                ),
                SizedBox(height: 8),
                
                // 内容预览
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                    [
                      // 文本内容
                      Text(
                        note.content,
                        style:
                          TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                      ),
                      
                      // 图片预览
                      if (note.imagePaths != null && note.imagePaths!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child:
                            Container(
                              height: 60,
                              child:
                                ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount:
                                    note.imagePaths!.length > 3
                                        ? 3
                                        : note.imagePaths!.length,
                                  itemBuilder:
                                    (context, index) {
                                      final imagePath = note.imagePaths![index];
                                      final file = File(imagePath);
                                      return file.existsSync()
                                          ? Padding(
                                              padding: const EdgeInsets.only(right: 8.0),
                                              child:
                                                Container(
                                                  width: 60,
                                                  height: 60,
                                                  child:
                                                    Image.file(
                                                      file,
                                                      fit: BoxFit.cover,
                                                    ),
                                                ),
                                            )
                                          : SizedBox();
                                    },
                                ),
                            ),
                        ),
                    ],
                ),
                SizedBox(height: 12),
                
                // 底部信息
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      note.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    Text(
                      note.formattedUpdatedAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
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
