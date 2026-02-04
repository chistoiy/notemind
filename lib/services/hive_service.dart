
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import './log_service.dart';

class HiveService {
  static const String _notesBox = 'notes';
  static const String _categoriesBox = 'categories';
  static const String _draftsBox = 'drafts';

  // 初始化Hive
  static Future<void> initialize() async {
    try {
      log.info('开始初始化Hive数据库');
      
      // 获取应用文档目录
      log.debug('获取应用文档目录');
      Directory directory = await getApplicationDocumentsDirectory();
      log.debug('应用文档目录: ${directory.path}');
      
      Hive.init(directory.path);
      log.debug('Hive初始化完成');

      // 注册适配器
      log.debug('注册Note适配器');
      Hive.registerAdapter(NoteAdapter());
      log.debug('Note适配器注册成功');

      // 打开所有需要的Box
      log.debug('打开notes Box');
      await Hive.openBox<Note>(_notesBox);
      log.debug('notes Box打开成功');
      
      log.debug('打开categories Box');
      await Hive.openBox<String>(_categoriesBox);
      log.debug('categories Box打开成功');
      
      log.debug('打开drafts Box');
      await Hive.openBox<Map>(_draftsBox);
      log.debug('drafts Box打开成功');

      // 初始化默认分类
      log.debug('初始化默认分类');
      await _initializeDefaultCategories();
      log.debug('默认分类初始化完成');
      
      log.info('Hive数据库初始化成功');
    } catch (e, stackTrace) {
      log.error('Hive初始化失败', e, stackTrace);
    }
  }

  // 初始化默认分类
  static Future<void> _initializeDefaultCategories() async {
    final categoriesBox = Hive.box<String>(_categoriesBox);
    if (categoriesBox.isEmpty) {
      await categoriesBox.add('未分类');
    }
  }

  // 笔记CRUD操作
  
  // 获取所有笔记
  static List<Note> getAllNotes() {
    try {
      log.debug('获取所有笔记');
      final notesBox = Hive.box<Note>(_notesBox);
      final notes = notesBox.values.toList();
      log.debug('获取到 ${notes.length} 条笔记');
      return notes;
    } catch (e, stackTrace) {
      log.error('获取所有笔记失败', e, stackTrace);
      return [];
    }
  }

  // 根据ID获取笔记
  static Note? getNoteById(String id) {
    try {
      log.debug('根据ID获取笔记: $id');
      final notesBox = Hive.box<Note>(_notesBox);
      final note = notesBox.values.firstWhere((note) => note.id == id);
      log.debug('获取笔记成功: ${note.title}');
      return note;
    } catch (e, stackTrace) {
      log.error('根据ID获取笔记失败: $id', e, stackTrace);
      return null;
    }
  }

  // 添加笔记
  static Future<void> addNote(Note note) async {
    try {
      log.info('添加笔记: ${note.title}');
      final notesBox = Hive.box<Note>(_notesBox);
      await notesBox.add(note);
      log.info('笔记添加成功: ${note.id}');
    } catch (e, stackTrace) {
      log.error('添加笔记失败: ${note.title}', e, stackTrace);
    }
  }

  // 更新笔记
  static Future<void> updateNote(Note note) async {
    try {
      log.info('更新笔记: ${note.title}');
      await note.save();
      log.info('笔记更新成功: ${note.id}');
    } catch (e, stackTrace) {
      log.error('更新笔记失败: ${note.title}', e, stackTrace);
    }
  }

  // 删除笔记
  static Future<void> deleteNote(Note note) async {
    try {
      log.info('删除笔记: ${note.title}');
      await note.delete();
      log.info('笔记删除成功: ${note.id}');
    } catch (e, stackTrace) {
      log.error('删除笔记失败: ${note.title}', e, stackTrace);
    }
  }

  // 按分类获取笔记
  static List<Note> getNotesByCategory(String category) {
    try {
      log.debug('按分类获取笔记: $category');
      final notesBox = Hive.box<Note>(_notesBox);
      final notes = notesBox.values.where((note) => note.category == category).toList();
      log.debug('获取到 ${notes.length} 条笔记');
      return notes;
    } catch (e, stackTrace) {
      log.error('按分类获取笔记失败: $category', e, stackTrace);
      return [];
    }
  }

  // 搜索笔记
  static List<Note> searchNotes(String keyword) {
    try {
      log.debug('搜索笔记: $keyword');
      final notesBox = Hive.box<Note>(_notesBox);
      final lowercaseKeyword = keyword.toLowerCase();
      final notes = notesBox.values.where((note) {
        return note.title.toLowerCase().contains(lowercaseKeyword) ||
            note.content.toLowerCase().contains(lowercaseKeyword);
      }).toList();
      log.debug('搜索到 ${notes.length} 条笔记');
      return notes;
    } catch (e, stackTrace) {
      log.error('搜索笔记失败: $keyword', e, stackTrace);
      return [];
    }
  }

  // 分类管理
  
  // 获取所有分类
  static List<String> getAllCategories() {
    try {
      log.debug('获取所有分类');
      final categoriesBox = Hive.box<String>(_categoriesBox);
      final categories = categoriesBox.values.toList();
      log.debug('获取到 ${categories.length} 个分类');
      return categories;
    } catch (e, stackTrace) {
      log.error('获取所有分类失败', e, stackTrace);
      return [];
    }
  }

  // 添加分类
  static Future<void> addCategory(String category) async {
    try {
      log.info('添加分类: $category');
      final categoriesBox = Hive.box<String>(_categoriesBox);
      if (!categoriesBox.values.contains(category)) {
        await categoriesBox.add(category);
        log.info('分类添加成功: $category');
      } else {
        log.debug('分类已存在: $category');
      }
    } catch (e, stackTrace) {
      log.error('添加分类失败: $category', e, stackTrace);
    }
  }

  // 删除分类
  static Future<void> deleteCategory(String category) async {
    try {
      log.info('删除分类: $category');
      final categoriesBox = Hive.box<String>(_categoriesBox);
      final index = categoriesBox.values.toList().indexOf(category);
      if (index != -1) {
        await categoriesBox.deleteAt(index);
        log.info('分类删除成功: $category');
      } else {
        log.debug('分类不存在: $category');
      }
    } catch (e, stackTrace) {
      log.error('删除分类失败: $category', e, stackTrace);
    }
  }

  // 草稿管理
  
  // 保存草稿
  static Future<void> saveDraft(String noteId, String title, String content) async {
    try {
      log.debug('保存草稿: $noteId');
      final draftsBox = Hive.box<Map>(_draftsBox);
      await draftsBox.put(noteId, {'title': title, 'content': content});
      log.debug('草稿保存成功: $noteId');
    } catch (e, stackTrace) {
      log.error('保存草稿失败: $noteId', e, stackTrace);
    }
  }

  // 获取草稿
  static Map<dynamic, dynamic>? getDraft(String noteId) {
    try {
      log.debug('获取草稿: $noteId');
      final draftsBox = Hive.box<Map>(_draftsBox);
      final draft = draftsBox.get(noteId);
      if (draft != null) {
        log.debug('获取草稿成功: $noteId');
      } else {
        log.debug('草稿不存在: $noteId');
      }
      return draft;
    } catch (e, stackTrace) {
      log.error('获取草稿失败: $noteId', e, stackTrace);
      return null;
    }
  }

  // 删除草稿
  static Future<void> deleteDraft(String noteId) async {
    try {
      log.debug('删除草稿: $noteId');
      final draftsBox = Hive.box<Map>(_draftsBox);
      await draftsBox.delete(noteId);
      log.debug('草稿删除成功: $noteId');
    } catch (e, stackTrace) {
      log.error('删除草稿失败: $noteId', e, stackTrace);
    }
  }

  // 清除所有草稿
  static Future<void> clearAllDrafts() async {
    try {
      log.info('清除所有草稿');
      final draftsBox = Hive.box<Map>(_draftsBox);
      await draftsBox.clear();
      log.info('所有草稿清除成功');
    } catch (e, stackTrace) {
      log.error('清除所有草稿失败', e, stackTrace);
    }
  }

  // 清理缓存
  static Future<void> clearCache() async {
    try {
      log.info('开始清理缓存');
      await clearAllDrafts();
      log.info('缓存清理成功');
    } catch (e, stackTrace) {
      log.error('缓存清理失败', e, stackTrace);
    }
  }

  // 关闭Hive
  static Future<void> close() async {
    try {
      log.info('开始关闭Hive');
      await Hive.close();
      log.info('Hive关闭成功');
    } catch (e, stackTrace) {
      log.error('Hive关闭失败', e, stackTrace);
    }
  }
}
