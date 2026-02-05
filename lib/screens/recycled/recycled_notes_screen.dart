import 'package:flutter/material.dart';
import '../../services/hive_service.dart';
import '../../models/note.dart';
import '../edit/edit_screen.dart';

class RecycledNotesScreen extends StatefulWidget {
  @override
  _RecycledNotesScreenState createState() => _RecycledNotesScreenState();
}

class _RecycledNotesScreenState extends State<RecycledNotesScreen> {
  List<Note> _recycledNotes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecycledNotes();
  }

  Future<void> _loadRecycledNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = HiveService.getRecycledNotes();
      setState(() {
        _recycledNotes = notes;
        _isLoading = false;
      });
    } catch (e) {
      print('加载回收站笔记失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreNote(Note note) async {
    try {
      await HiveService.restoreNote(note);
      _loadRecycledNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('笔记已恢复')),
      );
      // 返回时传递参数，通知笔记页面刷新
      Navigator.of(context).pop(true);
    } catch (e) {
      print('恢复笔记失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('恢复笔记失败: $e')),
      );
    }
  }

  Future<void> _permanentlyDeleteNote(Note note) async {
    try {
      await HiveService.permanentlyDeleteNote(note);
      _loadRecycledNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('笔记已永久删除')),
      );
    } catch (e) {
      print('永久删除笔记失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('永久删除笔记失败: $e')),
      );
    }
  }

  Future<void> _emptyRecycled() async {
    try {
      await HiveService.clearRecycledNotes();
      _loadRecycledNotes();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('回收站已清空')),
      );
    } catch (e) {
      print('清空回收站失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清空回收站失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('笔记回收站'),
        actions: [
          TextButton(
            onPressed: _emptyRecycled,
            child: Text('清空回收站', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _recycledNotes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.delete_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('回收站为空', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _recycledNotes.length,
                  itemBuilder: (context, index) {
                    final note = _recycledNotes[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          note.title,
                          style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '创建于: ${note.createdAt.year}-${note.createdAt.month}-${note.createdAt.day}',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              '更新于: ${note.updatedAt.year}-${note.updatedAt.month}-${note.updatedAt.day}',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.restore),
                              onPressed: () => _restoreNote(note),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_forever, color: Colors.red),
                              onPressed: () => _permanentlyDeleteNote(note),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
