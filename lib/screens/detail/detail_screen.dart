
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../../models/note.dart';
import '../../services/hive_service.dart';
import '../edit/edit_screen.dart';

class DetailScreen extends StatelessWidget {
  final Note note;

  const DetailScreen({Key? key, required this.note}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('笔记详情'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => _navigateToEdit(context),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => _deleteNote(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题
            Text(
              note.title.isNotEmpty ? note.title : '无标题',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // 分类和时间信息
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(label: Text(note.category)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('创建: ${note.formattedCreatedAt}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('更新: ${note.formattedUpdatedAt}', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),

            // 内容
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(16),
              child: buildContent(note.content),
            ),
            SizedBox(height: 24),

            // 操作按钮
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _shareNote(),
                  icon: Icon(Icons.share),
                  label: Text('分享'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _copyContent(),
                  icon: Icon(Icons.copy),
                  label: Text('复制内容'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _togglePin(),
                  icon: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                  label: Text(note.isPinned ? '取消置顶' : '置顶'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 导航到编辑页面
  void _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => EditScreen(note: note)),
    );
    if (result == true) {
      Navigator.pop(context, true);
    }
  }

  // 删除笔记
  void _deleteNote(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('删除笔记'),
          content: Text('确定要删除这篇笔记吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await HiveService.deleteNote(note);
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // 分享笔记
  void _shareNote() {
    // 这里可以实现分享功能，例如使用share_plus库
    // 由于我们没有添加该依赖，这里只是打印日志
    print('分享笔记: ${note.title}');
  }

  // 复制内容
  void _copyContent() async {
    try {
      // 简化处理，直接复制内容
      await Clipboard.setData(ClipboardData(text: note.content));
      // 可以添加一个Toast提示
      print('内容已复制到剪贴板');
    } catch (e) {
      print('复制内容失败: $e');
    }
  }

  // 切换置顶状态
  void _togglePin() async {
    note.isPinned = !note.isPinned;
    await HiveService.updateNote(note);
  }

  // 构建内容，支持图片渲染
  Widget buildContent(String content) {
    final parts = content.split('\n');
    final widgets = <Widget>[];

    for (var part in parts) {
      if (part.startsWith('[图片]')) {
        // 提取图片路径（移除 [图片] 前缀）
        final imagePath = part.substring('[图片]'.length).trim();
        final file = File(imagePath);
        
        if (file.existsSync()) {
          // 图片存在，渲染图片
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          );
        } else {
          // 图片不存在，显示路径
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                '图片不存在: $imagePath',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }
      } else if (part.isNotEmpty) {
        // 普通文本（非空）
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              part,
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
