import 'package:flutter/material.dart';
import '../../models/note.dart';
import '../../services/hive_service.dart';
import 'dart:convert';
import 'dart:io' as io show Directory, File;
import 'package:flutter/foundation.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:path/path.dart' as path;

class EditScreen extends StatefulWidget {
  final Note? note;

  const EditScreen({Key? key, this.note}) : super(key: key);

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  late final QuillController _controller;
  final FocusNode _editorFocusNode = FocusNode();
  final ScrollController _editorScrollController = ScrollController();
  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  List<String> _categories = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // 初始化标题控制器
    _titleController.text = widget.note?.title ?? '新笔记';

    // 加载分类列表
    _loadCategories();

    // 初始化空文档，确保无任何格式，避免工具栏默认选中状态
    const emptyDocument = [
      {"insert": "\n"},
    ];
    final defaultDocument = Document.fromJson(emptyDocument);

    // 初始化 QuillController
    _controller = QuillController(
      document: defaultDocument,
      selection: const TextSelection.collapsed(offset: 0),
      config: QuillControllerConfig(
        clipboardConfig: QuillClipboardConfig(
          enableExternalRichPaste: true,
          onImagePaste: (imageBytes) async {
            if (kIsWeb) {
              return null;
            }
            // 保存图片并返回路径
            final newFileName =
                'image-file-${DateTime.now().toIso8601String()}.png';
            final newPath = path.join(
              io.Directory.systemTemp.path,
              newFileName,
            );
            final file = await io.File(
              newPath,
            ).writeAsBytes(imageBytes, flush: true);
            return file.path;
          },
        ),
      ),
    );

    // 加载文档内容
    if (widget.note?.content != null) {
      try {
        final contentJson = jsonDecode(widget.note!.content!);
        final loadedDocument = Document.fromJson(contentJson);
        // 确保文档不为空
        if (loadedDocument.isEmpty()) {
          // 如果文档为空，使用空文档
          _controller.document = defaultDocument;
        } else {
          _controller.document = loadedDocument;
        }
      } catch (e) {
        // 保持空文档
      }
    }

    // 监听文档变化，确保文档始终不为空
    _controller.document.changes.listen((event) {
      // 延迟处理，确保在用户删除操作完成后再检查
      Future.delayed(const Duration(milliseconds: 10), () {
        if (_controller.document.isEmpty()) {
          // 如果文档变为空，添加一个空行
          _controller.document.insert(0, '\n');
          // 更新选择到正确位置
          _controller.updateSelection(
            const TextSelection.collapsed(offset: 0),
            ChangeSource.local,
          );
        }
      });
    });
  }

  // 加载分类列表
  void _loadCategories() {
    setState(() {
      _categories = HiveService.getAllCategories();
      // 确保至少有一个默认分类
      if (_categories.isEmpty) {
        _categories = ['未分类'];
      }
    });
  }

  // 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final year = dateTime.year;
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final second = dateTime.second.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute:$second';
  }

  // 从内容中提取图片路径
  List<String> _extractImagePaths(String content) {
    final imagePaths = <String>[];
    try {
      final contentJson = jsonDecode(content);
      if (contentJson is List) {
        for (final item in contentJson) {
          if (item is Map && item.containsKey('insert')) {
            final insert = item['insert'];
            if (insert is Map && insert.containsKey('image')) {
              final imagePath = insert['image'];
              if (imagePath is String) {
                imagePaths.add(imagePath);
              }
            }
          }
        }
      }
    } catch (e) {
      print('提取图片路径失败: $e');
    }
    return imagePaths;
  }

  void _saveNote() async {
    final content = jsonEncode(_controller.document.toDelta().toJson());
    final title = _titleController.text.trim();
    final imagePaths = _extractImagePaths(content);

    try {
      // 设置保存状态，防止用户在保存过程中点击返回按钮
      setState(() {
        _isSaving = true;
      });

      if (widget.note != null) {
        // 更新现有笔记 - 直接修改原始对象属性
        widget.note!.title = title.isEmpty ? '无标题' : title;
        widget.note!.content = content;
        widget.note!.imagePaths = imagePaths;
        widget.note!.updatedAt = DateTime.now();
        await HiveService.updateNote(widget.note!);
        // 显示更新成功提示
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('笔记更新成功')));
      } else {
        // 创建新笔记
        final newNote = Note(
          id: 'note_${DateTime.now().millisecondsSinceEpoch}',
          title: title.isEmpty ? '新笔记' : title,
          content: content,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          category: '未分类',
          isPinned: false,
          imagePaths: imagePaths,
        );
        await HiveService.addNote(newNote);
        // 显示创建成功提示
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('笔记创建成功')));
      }

      // 修复保存后黑屏问题
      // 延迟导航，确保SnackBar完全显示且UI操作完成
      Future.delayed(const Duration(milliseconds: 1500), () {
        Navigator.of(context).pop(true);
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('保存失败: $e')));
    } finally {
      // 保存完成后，恢复可返回状态
      setState(() {
        _isSaving = false;
      });
    }
  }

  // 分享笔记
  void _shareNote(String format) {
    try {
      final title = _titleController.text.trim();
      final content = _controller.document.toPlainText();

      switch (format) {
        case 'image':
          // 分享为图片
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('分享为图片功能开发中')),
          );
          break;
        case 'html':
          // 分享为HTML
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('分享为HTML功能开发中')),
          );
          break;
        case 'pdf':
          // 分享为PDF
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('分享为PDF功能开发中')),
          );
          break;
        case 'text':
          // 分享为文本
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('分享为文本功能开发中')),
          );
          break;
        default:
          break;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 计算总字数
    final contentText = _controller.document.toPlainText();
    final wordCount = contentText.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: '返回',
          onPressed: () {
            if (!_isSaving) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Row(
          children: [
            // 前进、后退按钮 - 靠左侧
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: '撤销',
              onPressed: () {
                _controller.undo();
              },
            ),
            IconButton(
              icon: const Icon(Icons.redo),
              tooltip: '重做',
              onPressed: () {
                _controller.redo();
              },
            ),
          ],
        ),
        actions: [
          // 分享按钮
          PopupMenuButton<String>(
            onSelected: (format) {
              _shareNote(format);
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(value: 'image', child: Text('分享为图片')),
                PopupMenuItem(value: 'html', child: Text('分享为HTML')),
                PopupMenuItem(value: 'pdf', child: Text('分享为PDF')),
                PopupMenuItem(value: 'text', child: Text('分享为文本')),
              ];
            },
            icon: const Icon(Icons.share),
            tooltip: '分享笔记',
          ),
          // 分组选择操作
          PopupMenuButton<String>(
            onSelected: (category) {
              if (widget.note != null) {
                widget.note!.category = category;
              }
              // 这里可以添加保存分组的逻辑
            },
            itemBuilder: (context) => _categories.map((category) {
              return PopupMenuItem(value: category, child: Text(category));
            }).toList(),
            icon: const Icon(Icons.category),
            tooltip: '选择分组',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '保存笔记',
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // 标题和信息行
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题输入
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '输入标题',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    onSubmitted: (_) {
                      // 提交标题后将焦点移到编辑器
                      _editorFocusNode.requestFocus();
                    },
                  ),
                  // 时间和字数信息
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '创建: ${widget.note?.formattedCreatedAt ?? _formatDateTime(DateTime.now())}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '更新: ${widget.note?.formattedUpdatedAt ?? _formatDateTime(DateTime.now())}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '字数: $wordCount',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 编辑器配置
            Expanded(
              child: QuillEditor(
                controller: _controller,
                focusNode: _editorFocusNode,
                scrollController: _editorScrollController,
                config: QuillEditorConfig(
                  placeholder: '开始编写你的笔记...',
                  padding: const EdgeInsets.all(16),
                  embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                ),
              ),
            ),
            // 工具栏配置 - 移到下方，实现横向滑动
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: QuillSimpleToolbar(
                  controller: _controller,
                  config: QuillSimpleToolbarConfig(
                    embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                    showClipboardPaste: true,
                    // 移除字体相关选项
                    showFontFamily: false,
                    showFontSize: false,
                    // 显示查找替换功能
                    showSearchButton: true,
                    // 将常用文字编辑功能放到二级菜单
                    customButtons: [
                      QuillToolbarCustomButtonOptions(
                        icon: Icon(Icons.format_list_bulleted),
                        tooltip: '文字编辑',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: Text('文字编辑'),
                                content: Container(
                                  width: 300,
                                  child: QuillSimpleToolbar(
                                    controller: _controller,
                                    config: QuillSimpleToolbarConfig(
                                      showBoldButton: true,
                                      showItalicButton: true,
                                      showUnderLineButton: true,
                                      showStrikeThrough: true,
                                      showInlineCode: true,
                                      showColorButton: true,
                                      showBackgroundColorButton: true,
                                      showAlignmentButtons: true,
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('关闭'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                    buttonOptions: QuillSimpleToolbarButtonOptions(
                      base: QuillToolbarBaseButtonOptions(
                        afterButtonPressed: () {
                          final isDesktop = {
                            TargetPlatform.linux,
                            TargetPlatform.windows,
                            TargetPlatform.macOS,
                          }.contains(defaultTargetPlatform);
                          if (isDesktop) {
                            _editorFocusNode.requestFocus();
                          }
                        },
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
  }

  @override
  void dispose() {
    _controller.dispose();
    _editorScrollController.dispose();
    _editorFocusNode.dispose();
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }
}