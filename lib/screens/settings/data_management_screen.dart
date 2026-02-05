import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hive/hive.dart';
import '../../services/hive_service.dart';
import '../../models/note.dart';
import '../../screens/todo/todo_screen.dart';
import '../../services/log_service.dart';
import '../../providers/app_config_provider.dart';
import 'package:provider/provider.dart';

class DataManagementScreen extends StatefulWidget {
  @override
  _DataManagementScreenState createState() => _DataManagementScreenState();
}

class _DataManagementScreenState extends State<DataManagementScreen> {
  @override
  void initState() {
    super.initState();
    // 初始化时检查并申请存储权限
    _checkStoragePermission();
  }

  // 检查并申请存储权限
  Future<void> _checkStoragePermission() async {
    try {
      log.debug('开始检查存储权限');
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        log.warning('存储权限被拒绝');
        // 显示一个提示，告诉用户需要存储权限才能使用导出和导入功能
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('需要存储权限才能使用导出和导入功能'),
            action: SnackBarAction(
              label: '去设置',
              onPressed: () async {
                // 打开应用设置页面
                await openAppSettings();
              },
            ),
          ),
        );
      } else {
        log.debug('存储权限已授予');
      }
    } catch (e, stackTrace) {
      log.error('检查存储权限失败', e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('数据管理')),
      body: ListView(
        children: [
          // 存储位置设置
          ListTile(
            title: Text('存储位置'),
            subtitle: FutureBuilder<String>(
              future: _getStorageLocation(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Text(snapshot.data!);
                } else {
                  return Text('获取中...');
                }
              },
            ),
            trailing: Icon(Icons.arrow_forward),
            onTap: () => _selectStorageLocation(context),
          ),

          Divider(),

          // 导出数据
          ListTile(
            title: Text('导出数据'),
            subtitle: Text('将所有笔记和图片导出为JSON文件'),
            trailing: Icon(Icons.arrow_forward),
            onTap: () => _exportData(context),
          ),

          Divider(),

          // 导入数据
          ListTile(
            title: Text('导入数据'),
            subtitle: Text('从JSON文件导入笔记和图片'),
            trailing: Icon(Icons.import_export),
            onTap: () => _importData(context),
          ),
        ],
      ),
    );
  }

  static const String _storageLocationKey = 'storage_location';

  // 获取存储位置
  Future<String> _getStorageLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customLocation = prefs.getString(_storageLocationKey);
      if (customLocation != null && Directory(customLocation).existsSync()) {
        return customLocation;
      }
    } catch (e) {
      print('获取存储位置失败: $e');
    }

    // 默认存储位置
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // 请求存储权限
  Future<bool> _requestStoragePermission() async {
    try {
      log.debug('开始请求存储权限');
      if (Platform.isAndroid) {
        // 检查设备的安卓版本
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final androidVersion = androidInfo.version.sdkInt;
        log.debug('安卓版本: $androidVersion');

        if (androidVersion >= 33) {
          // 安卓13及以上，使用新的存储权限
          log.debug('使用新的存储权限模型');
          final status = await Permission.manageExternalStorage.status;
          log.debug('管理外部存储权限状态: $status');
          if (!status.isGranted) {
            log.debug('请求管理外部存储权限');
            final result = await Permission.manageExternalStorage.request();
            log.debug('管理外部存储权限请求结果: $result');
            return result.isGranted;
          } else if (status.isGranted) {
            log.debug('管理外部存储权限已授予');
            return true;
          }
        } else {
          // 安卓12及以下，使用旧的存储权限
          log.debug('使用旧的存储权限');
          final storageStatus = await Permission.storage.status;
          log.debug('存储权限状态: $storageStatus');
          if (storageStatus.isDenied) {
            log.debug('请求存储权限');
            final storageResult = await Permission.storage.request();
            log.debug('存储权限请求结果: $storageResult');
            return storageResult.isGranted;
          } else if (storageStatus.isGranted) {
            log.debug('存储权限已授予');
            return true;
          }
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        log.debug('桌面平台不需要存储权限');
        return true; // 桌面平台不需要存储权限
      }
      log.debug('iOS不需要存储权限');
      return true; // iOS 不需要存储权限
    } catch (e, stackTrace) {
      log.error('请求存储权限失败', e, stackTrace);
      return false;
    }
  }

  // 选择存储位置
  Future<void> _selectStorageLocation(BuildContext context) async {
    try {
      log.info('开始选择存储位置');
      // 请求存储权限
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        log.warning('存储权限被拒绝，无法选择存储位置');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('需要存储权限才能选择存储位置'),
            action: SnackBarAction(
              label: '去设置',
              onPressed: () async {
                // 打开应用设置页面
                await openAppSettings();
              },
            ),
          ),
        );
        return;
      }

      // 显示存储位置选择对话框
      log.debug('显示存储位置选择对话框');
      final selectedLocation = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('选择存储位置'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text('默认存储位置'),
                  subtitle: FutureBuilder<String>(
                    future: getApplicationDocumentsDirectory().then(
                      (dir) => dir.path,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(snapshot.data!);
                      } else {
                        return Text('获取中...');
                      }
                    },
                  ),
                  onTap: () async {
                    final directory = await getApplicationDocumentsDirectory();
                    Navigator.pop(context, directory.path);
                  },
                ),
                Divider(),
                ListTile(
                  title: Text('公共存储位置'),
                  subtitle: FutureBuilder<String>(
                    future: _getPublicStorageLocation(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(snapshot.data!);
                      } else {
                        return Text('获取中...');
                      }
                    },
                  ),
                  onTap: () async {
                    final publicLocation = await _getPublicStorageLocation();
                    Navigator.pop(context, publicLocation);
                  },
                ),
                Divider(),
                ListTile(
                  title: Text('自定义存储位置'),
                  subtitle: Text('选择一个自定义的存储目录'),
                  onTap: () async {
                    Navigator.pop(context, 'custom');
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('取消'),
              ),
            ],
          );
        },
      );

      if (selectedLocation != null) {
        log.debug('选择的存储位置: $selectedLocation');
        String finalLocation = selectedLocation;

        // 如果选择了自定义存储位置，使用 file_picker 让用户选择目录
        if (selectedLocation == 'custom') {
          try {
            log.debug('开始选择自定义存储目录');
            final result = await FilePicker.platform.getDirectoryPath();
            if (result != null) {
              finalLocation = result;
              log.debug('自定义存储目录选择成功: $finalLocation');
            } else {
              log.debug('用户取消了选择自定义存储目录');
              return; // 用户取消了选择
            }
          } catch (e, stackTrace) {
            log.error('选择目录失败', e, stackTrace);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('选择目录失败: $e')));
            return;
          }
        }

        // 保存选择的存储位置
        log.debug('保存选择的存储位置: $finalLocation');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageLocationKey, finalLocation);

        // 显示成功提示
        log.info('存储位置设置成功: $finalLocation');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('存储位置已设置为: $finalLocation')));
      } else {
        log.debug('用户取消了存储位置选择');
      }
    } catch (e, stackTrace) {
      log.error('选择存储位置失败', e, stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选择存储位置失败: $e')));
    }
  }

  // 获取公共存储位置
  Future<String> _getPublicStorageLocation() async {
    try {
      log.debug('开始获取公共存储位置');
      if (Platform.isAndroid) {
        // 参考timejourney项目，使用固定的公共目录路径
        final directory = Directory('/storage/emulated/0/Documents/Notemind');
        if (!directory.existsSync()) {
          log.debug('创建Notemind文件夹: ${directory.path}');
          try {
            directory.createSync(recursive: true);
            log.debug('Notemind文件夹创建成功');
          } catch (e) {
            log.error('创建Notemind文件夹失败', e);
            // 如果创建失败，返回应用的内部存储目录
            log.debug('创建Notemind文件夹失败，使用默认存储位置');
            final defaultDir = await getApplicationDocumentsDirectory();
            log.debug('默认存储位置: ${defaultDir.path}');
            return defaultDir.path;
          }
        }
        log.debug('公共存储位置获取成功: ${directory.path}');
        return directory.path;
      } else if (Platform.isIOS) {
        // iOS平台，使用应用的文档目录
        final directory = await getApplicationDocumentsDirectory();
        log.debug('iOS存储位置: ${directory.path}');
        return directory.path;
      }
    } catch (e, stackTrace) {
      log.error('获取公共存储位置失败', e, stackTrace);
    }

    // 如果获取公共存储位置失败，返回默认存储位置
    log.debug('获取公共存储位置失败，使用默认存储位置');
    final defaultDir = await getApplicationDocumentsDirectory();
    log.debug('默认存储位置: ${defaultDir.path}');
    return defaultDir.path;
  }

  // 导出数据
  Future<void> _exportData(BuildContext context) async {
    try {
      // 请求存储权限
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        log.warning('存储权限被拒绝');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('需要存储权限才能导出数据'),
            action: SnackBarAction(
              label: '去设置',
              onPressed: () async {
                // 打开应用设置页面
                await openAppSettings();
              },
            ),
          ),
        );
        return;
      }

      // 获取存储位置
      final storageLocation = await _getStorageLocation();
      log.debug('使用存储位置: $storageLocation');

      // 检查并创建存储目录
      final storageDir = Directory(storageLocation);
      if (!storageDir.existsSync()) {
        try {
          storageDir.createSync(recursive: true);
          log.debug('存储目录创建成功: $storageLocation');
        } catch (e) {
          log.error('创建存储目录失败: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('创建存储目录失败: $e')));
          return;
        }
      }

      // 获取所有笔记
      final notes = HiveService.getAllNotes();
      log.debug('获取到 ${notes.length} 条笔记');

      // 获取所有待办事项
      final todos = HiveService.getAllTodos();
      log.debug('获取到 ${todos.length} 个待办事项');

      // 获取所有回收站待办事项
      final recycledTodos = HiveService.getAllRecycledTodos();
      log.debug('获取到 ${recycledTodos.length} 个回收站待办事项');

      // 生成导出目录
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportDir = Directory(
        '$storageLocation/notemind_export_$timestamp',
      );
      if (!exportDir.existsSync()) {
        try {
          exportDir.createSync(recursive: true);
          log.debug('导出目录创建成功: ${exportDir.path}');
        } catch (e) {
          log.error('创建导出目录失败: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('创建导出目录失败: $e')));
          return;
        }
      } else {
        log.debug('导出目录已存在: ${exportDir.path}');
      }

      // 创建images目录
      final imagesDir = Directory('${exportDir.path}/images');
      if (!imagesDir.existsSync()) {
        try {
          imagesDir.createSync(recursive: true);
          log.debug('图片目录创建成功: ${imagesDir.path}');
        } catch (e) {
          log.error('创建图片目录失败: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('创建图片目录失败: $e')));
          return;
        }
      } else {
        log.debug('图片目录已存在: ${imagesDir.path}');
      }

      // 获取应用配置
      final appConfig = Provider.of<AppConfigProvider>(context, listen: false);

      // 获取所有分类
      final categories = HiveService.getAllCategories();

      // 转换为JSON格式，同时导出图片
      final notesList = [];
      final todosList = [];
      final recycledTodosList = [];
      final exportData = {
        'notes': notesList,
        'todos': todosList,
        'recycledTodos': recycledTodosList,
        'appConfig': {
          'isDarkMode': appConfig.isDarkMode,
          'sortBy': appConfig.sortBy,
          'viewMode': appConfig.viewMode,
          'timelineMode': appConfig.timelineMode,
          'todoMode': appConfig.todoMode,
          'analyticsMode': appConfig.analyticsMode,
        },
        'categories': categories,
      };

      for (final note in notes) {
        final noteData = {
          'id': note.id,
          'title': note.title,
          'content': note.content,
          'createdAt': note.createdAt.toIso8601String(),
          'updatedAt': note.updatedAt.toIso8601String(),
          'category': note.category,
          'isPinned': note.isPinned,
          'imagePaths': [],
        };

        // 导出图片
        if (note.imagePaths != null) {
          final List<String> exportedImagePaths = [];

          for (int i = 0; i < note.imagePaths!.length; i++) {
            final originalPath = note.imagePaths![i];
            final originalFile = File(originalPath);

            if (originalFile.existsSync()) {
              try {
                // 生成新的文件名
                final fileName = '${note.id}_image_$i.jpg';
                final newPath = '${imagesDir.path}/$fileName';

                // 复制图片文件
                await originalFile.copy(newPath);

                // 保存相对路径
                exportedImagePaths.add('images/$fileName');
                log.debug('图片导出成功: $fileName');
              } catch (e) {
                log.error('导出图片失败: $e');
                // 继续导出其他图片，不中断整个导出过程
              }
            }
          }

          noteData['imagePaths'] = exportedImagePaths;
        }

        notesList.add(noteData);
      }

      // 处理待办事项数据
      for (final todo in todos) {
        final todoData = {
          'title': todo.title,
          'isCompleted': todo.isCompleted,
          'createdAt': todo.createdAt.toIso8601String(),
          'dueDate': todo.dueDate?.toIso8601String(),
          'isExpired': todo.isExpired,
        };
        todosList.add(todoData);
      }

      // 处理回收站待办事项数据
      for (final recycledTodo in recycledTodos) {
        final recycledTodoData = {
          'todo': {
            'title': recycledTodo.todo.title,
            'isCompleted': recycledTodo.todo.isCompleted,
            'createdAt': recycledTodo.todo.createdAt.toIso8601String(),
            'dueDate': recycledTodo.todo.dueDate?.toIso8601String(),
            'isExpired': recycledTodo.todo.isExpired,
          },
          'deletedAt': recycledTodo.deletedAt.toIso8601String(),
        };
        recycledTodosList.add(recycledTodoData);
      }

      final jsonString = jsonEncode(exportData);

      // 生成JSON文件名
      final filePath = '${exportDir.path}/notes.json';

      // 写入文件
      try {
        final file = File(filePath);
        await file.writeAsString(jsonString);
        log.info('数据导出成功: $filePath');

        // 显示成功提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据导出成功，保存到: ${exportDir.path}')),
        );
      } catch (e) {
        log.error('写入导出文件失败: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('写入导出文件失败: $e')));
        return;
      }
    } catch (e, stackTrace) {
      log.error('导出数据失败', e, stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('导出数据失败: $e')));
    }
  }

  // 导入数据
  Future<void> _importData(BuildContext context) async {
    try {
      // 请求存储权限
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('需要存储权限才能导入数据'),
            action: SnackBarAction(
              label: '去设置',
              onPressed: () async {
                // 打开应用设置页面
                await openAppSettings();
              },
            ),
          ),
        );
        return;
      }

      // 使用目录选择器让用户选择要导入的目录
      log.debug('开始选择导入目录');
      final result = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择包含笔记数据的目录',
      );

      if (result == null) {
        log.debug('用户取消了目录选择');
        return;
      }

      // 查找目录中的notes.json文件
      final file = File('$result/notes.json');
      log.debug('查找的文件: ${file.path}');

      if (!file.existsSync()) {
        log.error('文件不存在: ${file.path}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('文件不存在')));
        return;
      }

      // 读取文件内容
      log.debug('开始读取文件内容');
      final jsonString = await file.readAsString();
      final importData = jsonDecode(jsonString) as Map<String, dynamic>;
      final notesJson = importData['notes'] as List;
      log.debug('读取到 ${notesJson.length} 条笔记');

      // 读取应用配置
      final appConfigJson = importData['appConfig'] as Map<String, dynamic>?;
      // 读取分类配置
      List<String>? categoriesJson;
      if (importData['categories'] != null) {
        final dynamic categories = importData['categories'];
        if (categories is List) {
          categoriesJson = categories
              .map((category) => category.toString())
              .toList();
        }
      }

      // 显示导入方式选择对话框
      final importMode = await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('选择导入方式'),
            content: Text('请选择如何导入笔记数据:'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'incremental'),
                child: Text('增量导入'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'clear'),
                child: Text('清空导入'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: Text('取消'),
              ),
            ],
          );
        },
      );

      if (importMode == 'cancel' || importMode == null) {
        log.debug('用户取消了导入操作');
        return;
      }

      // 如果选择了清空导入，先清空现有笔记
      if (importMode == 'clear') {
        try {
          log.debug('开始清空现有笔记');
          // 使用 HiveService 清空现有笔记
          final notesBox = HiveService.getNotesBox();
          await notesBox.clear();
          log.debug('清空现有笔记成功');
        } catch (e) {
          log.error('清空现有笔记失败: $e');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('清空现有笔记失败: $e')));
          return;
        }
      }

      // 导入笔记
      log.debug('开始导入笔记');
      int importedCount = 0;

      for (final noteJson in notesJson) {
        List<String>? imagePaths;

        // 处理图片路径
        if (noteJson['imagePaths'] != null) {
          final dynamic paths = noteJson['imagePaths'];
          if (paths is List) {
            final relativePaths = paths.map((path) => path.toString()).toList();
            imagePaths = [];

            for (final relativePath in relativePaths) {
              // 转换为绝对路径
              final directoryPath = file.parent.path;
              final absolutePath = '$directoryPath/$relativePath';
              final imageFile = File(absolutePath);

              if (imageFile.existsSync()) {
                try {
                  // 复制图片到应用的本地存储目录
                  final appDir = await getApplicationDocumentsDirectory();
                  final imagesDir = Directory('${appDir.path}/images');

                  if (!imagesDir.existsSync()) {
                    imagesDir.createSync(recursive: true);
                  }

                  // 生成新的文件名
                  final fileName = absolutePath.split('/').last;
                  final newPath = '${imagesDir.path}/$fileName';

                  // 复制图片文件
                  await imageFile.copy(newPath);

                  // 保存新的路径
                  imagePaths!.add(newPath);
                  log.debug('图片导入成功: $fileName');
                } catch (e) {
                  log.error('导入图片失败: $e');
                  // 继续导入其他图片，不中断整个导入过程
                }
              }
            }
          }
        }

        final note = Note(
          id: noteJson['id'],
          title: noteJson['title'],
          content: noteJson['content'],
          createdAt: DateTime.parse(noteJson['createdAt']),
          updatedAt: DateTime.parse(noteJson['updatedAt']),
          category: noteJson['category'],
          isPinned: noteJson['isPinned'],
          imagePaths: imagePaths,
        );

        // 检查是否已存在相同id的笔记
        try {
          final existingNote = HiveService.getNoteById(note.id);
          if (existingNote != null) {
            // 更新现有笔记
            HiveService.updateNote(note);
            log.debug('更新现有笔记: ${note.title}');
          } else {
            // 添加新笔记
            HiveService.addNote(note);
            log.debug('添加新笔记: ${note.title}');
          }
          importedCount++;
        } catch (e) {
          log.error('导入笔记失败: $e');
          // 继续导入其他笔记，不中断整个导入过程
        }
      }

      // 导入待办事项
      log.debug('开始导入待办事项');
      final todosJson = importData['todos'] as List?;
      if (todosJson != null) {
        for (final todoJson in todosJson) {
          try {
            final todo = TodoItem(
              todoJson['title'] as String,
              todoJson['isCompleted'] as bool,
            );
            todo.createdAt = DateTime.parse(todoJson['createdAt'] as String);
            if (todoJson['dueDate'] != null) {
              todo.dueDate = DateTime.parse(todoJson['dueDate'] as String);
            }
            todo.isExpired = todoJson['isExpired'] as bool;

            final todosBox = Hive.box<TodoItem>('todos');
            await todosBox.add(todo);
            log.debug('待办事项导入成功: ${todo.title}');
          } catch (e) {
            log.error('导入待办事项失败: $e');
            // 继续导入其他待办事项，不中断整个导入过程
          }
        }
      }

      // 导入回收站待办事项
      log.debug('开始导入回收站待办事项');
      final recycledTodosJson = importData['recycledTodos'] as List?;
      if (recycledTodosJson != null) {
        for (final recycledTodoJson in recycledTodosJson) {
          try {
            final todoData = recycledTodoJson['todo'] as Map;
            final todo = TodoItem(
              todoData['title'] as String,
              todoData['isCompleted'] as bool,
            );
            todo.createdAt = DateTime.parse(todoData['createdAt'] as String);
            if (todoData['dueDate'] != null) {
              todo.dueDate = DateTime.parse(todoData['dueDate'] as String);
            }
            todo.isExpired = todoData['isExpired'] as bool;

            final deletedTodo = DeletedTodoItem(todo);
            deletedTodo.deletedAt = DateTime.parse(
              recycledTodoJson['deletedAt'] as String,
            );

            final recycledTodosBox = Hive.box<DeletedTodoItem>(
              'recycled_todos',
            );
            await recycledTodosBox.add(deletedTodo);
            log.debug('回收站待办事项导入成功');
          } catch (e) {
            log.error('导入回收站待办事项失败: $e');
            // 继续导入其他回收站待办事项，不中断整个导入过程
          }
        }
      }

      // 还原应用配置
      if (appConfigJson != null) {
        try {
          final appConfig = Provider.of<AppConfigProvider>(
            context,
            listen: false,
          );

          // 还原主题模式
          if (appConfigJson.containsKey('isDarkMode')) {
            final isDarkMode = appConfigJson['isDarkMode'] as bool;
            if (appConfig.isDarkMode != isDarkMode) {
              await appConfig.toggleTheme();
            }
          }

          // 还原排序方式
          if (appConfigJson.containsKey('sortBy')) {
            final sortBy = appConfigJson['sortBy'] as String;
            await appConfig.setSortBy(sortBy);
          }

          // 还原视图模式
          if (appConfigJson.containsKey('viewMode')) {
            final viewMode = appConfigJson['viewMode'] as String;
            while (appConfig.viewMode != viewMode) {
              await appConfig.toggleViewMode();
            }
          }

          // 还原时间轴模式
          if (appConfigJson.containsKey('timelineMode')) {
            final timelineMode = appConfigJson['timelineMode'] as bool;
            if (appConfig.timelineMode != timelineMode) {
              await appConfig.toggleTimelineMode();
            }
          }

          // 还原待办事项模式
          if (appConfigJson.containsKey('todoMode')) {
            final todoMode = appConfigJson['todoMode'] as bool;
            if (appConfig.todoMode != todoMode) {
              await appConfig.toggleTodoMode();
            }
          }

          // 还原数据分析模式
          if (appConfigJson.containsKey('analyticsMode')) {
            final analyticsMode = appConfigJson['analyticsMode'] as bool;
            if (appConfig.analyticsMode != analyticsMode) {
              await appConfig.toggleAnalyticsMode();
            }
          }

          log.info('应用配置还原成功');
        } catch (e) {
          log.error('还原应用配置失败: $e');
        }
      }

      // 还原分类配置
      if (categoriesJson != null) {
        try {
          // 清空现有分类
          await HiveService.clearCategories();

          // 添加导入的分类
          for (final category in categoriesJson) {
            await HiveService.addCategory(category);
          }

          log.info('分类配置还原成功，共还原 ${categoriesJson.length} 个分类');
        } catch (e) {
          log.error('还原分类配置失败: $e');
        }
      }

      // 显示成功提示
      log.info('数据导入成功，共导入 $importedCount 条笔记');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('数据导入成功，共导入 $importedCount 条笔记')));
    } catch (e, stackTrace) {
      log.error('导入数据失败', e, stackTrace);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('数据导入失败: $e')));
    }
  }
}
