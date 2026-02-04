import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../services/hive_service.dart';
import '../../models/note.dart';
import '../../services/log_service.dart';

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
      appBar: AppBar(
        title: Text('数据管理'),
      ),
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
                    future: getApplicationDocumentsDirectory().then((dir) => dir.path),
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('选择目录失败: $e')),
            );
            return;
          }
        }
        
        // 保存选择的存储位置
        log.debug('保存选择的存储位置: $finalLocation');
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_storageLocationKey, finalLocation);

        // 显示成功提示
        log.info('存储位置设置成功: $finalLocation');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('存储位置已设置为: $finalLocation')),
        );
      } else {
        log.debug('用户取消了存储位置选择');
      }
    } catch (e, stackTrace) {
      log.error('选择存储位置失败', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择存储位置失败: $e')),
      );
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
        storageDir.createSync(recursive: true);
        log.debug('存储目录创建成功: $storageLocation');
      }
      
      // 获取所有笔记
      final notes = HiveService.getAllNotes();
      log.debug('获取到 ${notes.length} 条笔记');
      
      // 生成导出目录
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportDir = Directory('$storageLocation/notemind_export_$timestamp');
      if (!exportDir.existsSync()) {
        exportDir.createSync(recursive: true);
        log.debug('导出目录创建成功: ${exportDir.path}');
      } else {
        log.debug('导出目录已存在: ${exportDir.path}');
      }
      
      // 创建images目录
      final imagesDir = Directory('${exportDir.path}/images');
      if (!imagesDir.existsSync()) {
        imagesDir.createSync(recursive: true);
        log.debug('图片目录创建成功: ${imagesDir.path}');
      } else {
        log.debug('图片目录已存在: ${imagesDir.path}');
      }
      
      // 转换为JSON格式，同时导出图片
      final notesJson = [];
      
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
          final exportedImagePaths = [];
          
          for (int i = 0; i < note.imagePaths!.length; i++) {
            final originalPath = note.imagePaths![i];
            final originalFile = File(originalPath);
            
            if (originalFile.existsSync()) {
              // 生成新的文件名
              final fileName = '${note.id}_image_$i.jpg';
              final newPath = '${imagesDir.path}/$fileName';
              
              // 复制图片文件
              await originalFile.copy(newPath);
              
              // 保存相对路径
              exportedImagePaths.add('images/$fileName');
              log.debug('图片导出成功: $fileName');
            }
          }
          
          noteData['imagePaths'] = exportedImagePaths;
        }
        
        notesJson.add(noteData);
      }
      
      final jsonString = jsonEncode(notesJson);
      
      // 生成JSON文件名
      final filePath = '${exportDir.path}/notes.json';
      
      // 写入文件
      final file = File(filePath);
      await file.writeAsString(jsonString);
      log.info('数据导出成功: $filePath');
      
      // 显示成功提示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据导出成功，保存到: ${exportDir.path}')),
      );
    } catch (e, stackTrace) {
      log.error('导出数据失败', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出数据失败: $e')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件不存在')),
        );
        return;
      }
      
      // 读取文件内容
      log.debug('开始读取文件内容');
      final jsonString = await file.readAsString();
      final notesJson = jsonDecode(jsonString) as List;
      log.debug('读取到 ${notesJson.length} 条笔记');
      
      // 导入笔记
      log.debug('开始导入笔记');
      int importedCount = 0;
      
      for (final noteJson in notesJson) {
        List<String>? imagePaths;
        
        // 处理图片路径
        if (noteJson['imagePaths'] != null) {
          final relativePaths = List<String>.from(noteJson['imagePaths']);
          imagePaths = [];
          
          for (final relativePath in relativePaths) {
            // 转换为绝对路径
            final directoryPath = file.parent.path;
            final absolutePath = '$directoryPath/$relativePath';
            final imageFile = File(absolutePath);
            
            if (imageFile.existsSync()) {
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
        
        // 直接添加笔记
        HiveService.addNote(note);
        importedCount++;
      }
      
      // 显示成功提示
      log.info('数据导入成功，共导入 $importedCount 条笔记');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据导入成功，共导入 $importedCount 条笔记')),
      );
    } catch (e, stackTrace) {
      log.error('导入数据失败', e, stackTrace);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('数据导入失败: $e')),
      );
    }
  }
}
