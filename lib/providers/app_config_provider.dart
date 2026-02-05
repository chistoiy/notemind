
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/log_service.dart';

class AppConfigProvider extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';
  static const String _sortByKey = 'sort_by';
  static const String _viewModeKey = 'view_mode';
  static const String _timelineModeKey = 'timeline_mode';
  static const String _todoModeKey = 'todo_mode';
  static const String _analyticsModeKey = 'analytics_mode';

  // 主题模式
  bool _isDarkMode = false;

  // 排序方式：'date' 或 'title'
  String _sortBy = 'date';

  // 视图模式：'grid' 或 'list'
  String _viewMode = 'list';

  // 时间轴模式：true 或 false
  bool _timelineMode = false;

  // 待办事项模式：true 或 false
  bool _todoMode = false;

  // 数据分析模式：true 或 false
  bool _analyticsMode = false;

  bool get isDarkMode => _isDarkMode;
  String get sortBy => _sortBy;
  String get viewMode => _viewMode;
  bool get timelineMode => _timelineMode;
  bool get todoMode => _todoMode;
  bool get analyticsMode => _analyticsMode;

  // 获取主题
  ThemeData get themeData {
    return _isDarkMode ? ThemeData.dark() : ThemeData.light();
  }

  // 初始化配置
  Future<void> initialize() async {
    try {
      log.debug('开始初始化应用配置');
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      _sortBy = prefs.getString(_sortByKey) ?? 'date';
      _viewMode = prefs.getString(_viewModeKey) ?? 'list';
      _timelineMode = prefs.getBool(_timelineModeKey) ?? false;
      _todoMode = prefs.getBool(_todoModeKey) ?? false;
      _analyticsMode = prefs.getBool(_analyticsModeKey) ?? false;
      notifyListeners();
      log.info('应用配置初始化成功');
      log.debug('主题模式: ${_isDarkMode ? '暗黑模式' : '浅色模式'}');
      log.debug('排序方式: $_sortBy');
      log.debug('视图模式: $_viewMode');
      log.debug('时间轴模式: ${_timelineMode ? '已开启' : '已关闭'}');
      log.debug('待办事项模式: ${_todoMode ? '已开启' : '已关闭'}');
      log.debug('数据分析模式: ${_analyticsMode ? '已开启' : '已关闭'}');
    } catch (e, stackTrace) {
      log.error('配置初始化失败', e, stackTrace);
    }
  }

  // 切换主题模式
  Future<void> toggleTheme() async {
    try {
      log.info('切换主题模式');
      _isDarkMode = !_isDarkMode;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
      log.info('主题模式切换成功: ${_isDarkMode ? '暗黑模式' : '浅色模式'}');
    } catch (e, stackTrace) {
      log.error('主题模式切换失败', e, stackTrace);
    }
  }

  // 设置排序方式
  Future<void> setSortBy(String sortBy) async {
    try {
      log.info('设置排序方式: $sortBy');
      _sortBy = sortBy;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sortByKey, sortBy);
      log.info('排序方式设置成功: $sortBy');
    } catch (e, stackTrace) {
      log.error('排序方式设置失败', e, stackTrace);
    }
  }

  // 切换视图模式
  Future<void> toggleViewMode() async {
    try {
      log.info('切换视图模式');
      _viewMode = _viewMode == 'list' ? 'grid' : 'list';
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_viewModeKey, _viewMode);
      log.info('视图模式切换成功: $_viewMode');
    } catch (e, stackTrace) {
      log.error('视图模式切换失败', e, stackTrace);
    }
  }

  // 切换时间轴模式
  Future<void> toggleTimelineMode() async {
    try {
      log.info('切换时间轴模式');
      _timelineMode = !_timelineMode;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_timelineModeKey, _timelineMode);
      log.info('时间轴模式切换成功: ${_timelineMode ? '已开启' : '已关闭'}');
    } catch (e, stackTrace) {
      log.error('时间轴模式切换失败', e, stackTrace);
    }
  }

  // 切换待办事项模式
  Future<void> toggleTodoMode() async {
    try {
      log.info('切换待办事项模式');
      _todoMode = !_todoMode;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_todoModeKey, _todoMode);
      log.info('待办事项模式切换成功: ${_todoMode ? '已开启' : '已关闭'}');
    } catch (e, stackTrace) {
      log.error('待办事项模式切换失败', e, stackTrace);
    }
  }

  // 切换数据分析模式
  Future<void> toggleAnalyticsMode() async {
    try {
      log.info('切换数据分析模式');
      _analyticsMode = !_analyticsMode;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_analyticsModeKey, _analyticsMode);
      log.info('数据分析模式切换成功: ${_analyticsMode ? '已开启' : '已关闭'}');
    } catch (e, stackTrace) {
      log.error('数据分析模式切换失败', e, stackTrace);
    }
  }
}

// 扩展方法，方便在Widget中获取配置
extension AppConfigExtension on BuildContext {
  AppConfigProvider get appConfig => read<AppConfigProvider>();
}
