
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/note.dart';
import '../../services/hive_service.dart';

class EditScreen extends StatefulWidget {
  final Note? note;

  const EditScreen({Key? key, this.note}) : super(key: key);

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();
  String _category = '未分类';
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  bool _isDirty = false;
  List<String> _imagePaths = [];
  bool _isEditMode = true; // true: 编辑模式, false: 渲染模式
  int _cursorPosition = 0; // 记录编辑模式下的光标位置
  ScrollController _scrollController = ScrollController(); // 预览页面的滚动控制器

  @override
  void initState() {
    super.initState();
    // 根据是否是新建笔记设置默认模式
    _isEditMode = widget.note == null; // 新建笔记时进入编辑模式，编辑现有笔记时进入渲染模式
    _initializeEditor();
    _startAutoSaveTimer();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 初始化编辑器
  void _initializeEditor() {
    if (widget.note != null) {
      // 加载现有笔记
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _category = widget.note!.category;
      if (widget.note!.imagePaths != null) {
        _imagePaths = widget.note!.imagePaths!;
      }
    } else {
      // 检查是否有草稿
      _loadDraft();
    }
  }

  // 加载草稿
  void _loadDraft() {
    final draft = HiveService.getDraft('new_note');
    if (draft != null) {
      _titleController.text = draft['title'] ?? '';
      _contentController.text = draft['content'] ?? '';
    }
  }

  // 启动自动保存计时器
  void _startAutoSaveTimer() {
    _autoSaveTimer = Timer.periodic(Duration(seconds: 3), (_) {
      if (_isDirty) {
        _autoSaveDraft();
      }
    });
  }

  // 自动保存草稿
  void _autoSaveDraft() {
    setState(() {
      _isSaving = true;
    });

    try {
      final content = _contentController.text;
      HiveService.saveDraft('new_note', _titleController.text, content);
      _isDirty = false;
    } catch (e) {
      print('保存草稿失败: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 手动保存正式数据
  Future<void> _saveNote() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final content = _contentController.text;
      final now = DateTime.now();

      if (widget.note != null) {
        // 更新现有笔记
        widget.note!.title = _titleController.text;
        widget.note!.content = content;
        widget.note!.updatedAt = now;
        widget.note!.category = _category;
        widget.note!.imagePaths = _imagePaths;
        await HiveService.updateNote(widget.note!);
      } else {
        // 创建新笔记
        final note = Note(
          id: Uuid().v4(),
          title: _titleController.text,
          content: content,
          createdAt: now,
          updatedAt: now,
          category: _category,
          isPinned: false,
          imagePaths: _imagePaths,
        );
        await HiveService.addNote(note);
        // 清除草稿
        HiveService.deleteDraft('new_note');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存成功')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print('保存笔记失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 导航到分类选择
  Future<void> _selectCategory() async {
    final categories = HiveService.getAllCategories();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('选择分类'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category),
                  trailing: _category == category ? Icon(Icons.check) : null,
                  onTap: () => Navigator.pop(context, category),
                );
              },
            ),
          ),
        );
      },
    );

    if (result != null) {
      setState(() {
        _category = result;
        _isDirty = true;
      });
    }
  }

  // 处理内容变化
  void _onContentChanged() {
    setState(() {
      _isDirty = true;
    });
  }

  // 选择并插入图片
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // 复制图片到应用的本地存储目录
      final imagePath = await _copyImageToLocal(pickedFile.path);
      
      // 获取当前光标位置
      final cursorPosition = _contentController.selection.baseOffset;
      // 获取当前文本
      final currentText = _contentController.text;
      // 构建新文本，在光标位置插入图片标记
      final imageTag = ' [图片${_imagePaths.length + 1}] ';
      final newText = currentText.substring(0, cursorPosition) +
          imageTag +
          currentText.substring(cursorPosition);
      // 更新文本控制器
      _contentController.text = newText;
      // 将光标移动到图片插入位置之后
      _contentController.selection = TextSelection.fromPosition(
        TextPosition(offset: cursorPosition + imageTag.length),
      );
      // 添加到图片路径列表
      setState(() {
        _imagePaths.add(imagePath);
      });
      // 标记为 dirty
      _isDirty = true;
    }
  }

  // 复制图片到应用的本地存储目录
  Future<String> _copyImageToLocal(String originalPath) async {
    try {
      // 获取应用的文档目录
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/images');
      
      // 创建目录（如果不存在）
      if (!imagesDir.existsSync()) {
        imagesDir.createSync(recursive: true);
      }
      
      // 生成唯一的文件名
      final fileName = '${Uuid().v4()}.jpg';
      final newPath = '${imagesDir.path}/$fileName';
      
      // 复制文件
      final originalFile = File(originalPath);
      final newFile = await originalFile.copy(newPath);
      
      return newFile.path;
    } catch (e) {
      print('复制图片失败: $e');
      return originalPath; // 如果复制失败，返回原始路径
    }
  }

  // 构建图文混排的内容
  Widget _buildMixedContent() {
    final content = _contentController.text;
    final widgets = <Widget>[];
    
    // 分割文本，识别图片标记
    final parts = content.split(RegExp(r'\[图片\d+\]'));
    int imageIndex = 0;
    
    for (int i = 0; i < parts.length; i++) {
      final part = parts[i];
      
      // 添加文本部分
      if (part.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(part),
          ),
        );
      }
      
      // 添加图片部分
      if (i < parts.length - 1 && imageIndex < _imagePaths.length) {
        final imagePath = _imagePaths[imageIndex];
        final file = File(imagePath);
        
        if (file.existsSync()) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          );
        } else {
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2.0),
              child: Text(
                '图片不存在: $imagePath',
                style: TextStyle(color: Colors.red),
              ),
            ),
          );
        }
        
        imageIndex++;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // 检查是否删除了图片标记
  void _checkAndRemoveImages() {
    final content = _contentController.text;
    final imageTags = RegExp(r'\[图片\d+\]').allMatches(content);
    final remainingImageCount = imageTags.length;
    
    if (remainingImageCount < _imagePaths.length) {
      // 删除多余的图片路径
      setState(() {
        _imagePaths = _imagePaths.take(remainingImageCount).toList();
      });
    }
  }

  // 根据光标位置滚动到对应位置
  void _scrollToPosition(int cursorPosition) {
    // 简化处理，根据光标位置估算滚动位置
    // 实际应用中需要实现更复杂的位置映射
    final scrollOffset = cursorPosition * 0.1; // 假设每个字符对应一定的滚动偏移
    _scrollController.animateTo(
      scrollOffset,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // 构建包含图片的内容
  List<Widget> _buildContentWithImages(String content) {
    final parts = content.split('\n');
    final widgets = <Widget>[];

    for (var part in parts) {
      if (part.startsWith('[图片]')) {
        // 提取图片路径
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
        // 普通文本
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

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode
              ? (widget.note != null ? '编辑笔记' : '新建笔记')
              : '预览笔记',
        ),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: Icon(Icons.category),
              onPressed: _selectCategory,
            ),
          IconButton(
            icon: _isSaving ? CircularProgressIndicator() : Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          // 标题输入（仅编辑模式显示）
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: '输入标题',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _isDirty = true,
              ),
            ),

          // 分类显示（仅编辑模式显示）
          if (_isEditMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Text('分类: '),
                  Chip(label: Text(_category)),
                ],
              ),
            ),

          // 页面切换区域
          Expanded(
            child:
              GestureDetector(
                onHorizontalDragEnd: (details) {
                  // 左滑切换到渲染模式
                  if (details.primaryVelocity! < -1000 && _isEditMode) {
                    // 记录光标位置
                    _cursorPosition = _contentController.selection.baseOffset;
                    // 切换到渲染模式
                    setState(() {
                      _isEditMode = false;
                    });
                    // 延迟滚动，确保 UI 已经更新
                    Future.delayed(Duration(milliseconds: 100), () {
                      _scrollToPosition(_cursorPosition);
                    });
                  }
                  // 右滑切换到编辑模式
                  else if (details.primaryVelocity! > 1000 && !_isEditMode) {
                    setState(() {
                      _isEditMode = true;
                    });
                  }
                },
                child:
                  Container(
                    child:
                      _isEditMode
                        ?
                          // 编辑模式
                          Column(
                            children:
                              [
                                // 工具栏
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child:
                                    Row(
                                      children:
                                        [
                                          IconButton(icon: Icon(Icons.format_bold), onPressed: () {}),
                                          IconButton(icon: Icon(Icons.format_italic), onPressed: () {}),
                                          IconButton(icon: Icon(Icons.format_list_bulleted), onPressed: () {}),
                                          IconButton(icon: Icon(Icons.format_list_numbered), onPressed: () {}),
                                          IconButton(
                                            icon: Icon(Icons.image),
                                            onPressed: _pickImage,
                                            tooltip: '插入图片',
                                          ),
                                        ],
                                    ),
                                ),
                                
                                // 编辑区域
                                Expanded(
                                  child:
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child:
                                        Container(
                                          decoration:
                                            BoxDecoration(
                                              border: Border.all(color: Colors.grey[200]!),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          padding: EdgeInsets.all(16),
                                          child:
                                            SingleChildScrollView(
                                              child:
                                                TextField(
                                                  controller: _contentController,
                                                  maxLines: null,
                                                  decoration:
                                                    InputDecoration(
                                                      hintText: '输入内容，插入图片后会显示在对应位置',
                                                      border: InputBorder.none,
                                                    ),
                                                  onChanged: (_) {
                                                    _isDirty = true;
                                                    // 检查是否删除了图片标记
                                                    _checkAndRemoveImages();
                                                  },
                                                ),
                                            ),
                                        ),
                                    ),
                                ),
                              ],
                          )
                        :
                          // 渲染模式
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child:
                              Container(
                                decoration:
                                  BoxDecoration(
                                    border: Border.all(color: Colors.grey[200]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                padding: EdgeInsets.all(16),
                                child:
                                  SingleChildScrollView(
                                    controller: _scrollController,
                                    child:
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children:
                                          [
                                            // 标题
                                            Text(
                                              _titleController.text.isNotEmpty ? _titleController.text : '无标题',
                                              style:
                                                TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                            ),
                                            SizedBox(height: 16),
                                            
                                            // 内容
                                            _buildMixedContent(),
                                          ],
                                      ),
                                  ),
                              ),
                          ),
                  ),
              ),
          ),

          // 自动保存提示
          if (_isSaving)
            Container(
              padding: EdgeInsets.all(8),
              color: Colors.blue[100],
              child: Text('正在保存...'),
            ),
        ],
      ),
    );
  }
}
