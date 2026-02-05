
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_config_provider.dart';
import '../../services/hive_service.dart';
import 'data_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: '笔记'),
            Tab(text: '待办事项'),
            Tab(text: '数据'),
            Tab(text: '系统'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 笔记设置
          ListView(
            children: [
              // 主题设置
              ListTile(
                title: Text('主题模式'),
                subtitle: Text(appConfig.isDarkMode ? '暗黑模式' : '浅色模式'),
                trailing: Switch(
                  value: appConfig.isDarkMode,
                  onChanged: (_) => appConfig.toggleTheme(),
                ),
              ),

              // 时间轴视图设置
              ListTile(
                title: Text('时间轴视图'),
                subtitle: Text(appConfig.timelineMode ? '已开启' : '已关闭'),
                trailing: Switch(
                  value: appConfig.timelineMode,
                  onChanged: (_) => appConfig.toggleTimelineMode(),
                ),
              ),

              // 数据分析页面
              ListTile(
                title: Text('数据分析页面'),
                subtitle: Text(appConfig.analyticsMode ? '已开启' : '已关闭'),
                trailing: Switch(
                  value: appConfig.analyticsMode,
                  onChanged: (_) => appConfig.toggleAnalyticsMode(),
                ),
              ),
            ],
          ),

          // 待办事项设置
          ListView(
            children: [
              // 待办事项功能
              ListTile(
                title: Text('待办事项功能'),
                subtitle: Text(appConfig.todoMode ? '已开启' : '已关闭'),
                trailing: Switch(
                  value: appConfig.todoMode,
                  onChanged: (_) => appConfig.toggleTodoMode(),
                ),
              ),
            ],
          ),

          // 数据管理
          ListView(
            children: [
              // 清理缓存
              ListTile(
                title: Text('清理缓存'),
                subtitle: Text('清理所有草稿和临时数据'),
                trailing: Icon(Icons.delete_sweep),
                onTap: () => _clearCache(context),
              ),

              // 数据导入导出
              ListTile(
                title: Text('数据导入导出'),
                subtitle: Text('导出和导入笔记、配置和分类'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () => _navigateToDataManagement(context),
              ),
            ],
          ),

          // 系统设置
          ListView(
            children: [
              // 日志监控
              ListTile(
                title: Text('日志监控'),
                subtitle: Text('查看应用运行日志'),
                trailing: Icon(Icons.arrow_forward),
                onTap: () => _navigateToLogMonitor(context),
              ),

              // 关于应用
              ListTile(
                title: Text('关于应用'),
                trailing: Icon(Icons.info),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 清理缓存
  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('清理缓存'),
          content: Text('确定要清理所有草稿和临时数据吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                await HiveService.clearCache();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('缓存清理成功')),
                );
              },
              child: Text('清理', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('关于 Notemind'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('版本: 1.0.0'),
              SizedBox(height: 8),
              Text('Notemind 是一款简单、高效的笔记应用，帮助你记录生活和工作中的重要信息。'),
              SizedBox(height: 8),
              Text('功能特点:'),
              Text('- 富文本编辑'),
              Text('- 笔记分类管理'),
              Text('- 暗黑模式支持'),
              Text('- 自动保存草稿'),
              Text('- 笔记置顶功能'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 导航到数据管理页面
  void _navigateToDataManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DataManagementScreen()),
    );
  }

  // 导航到日志监控页面
  void _navigateToLogMonitor(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LogMonitorScreen()),
    );
  }


}

class LogMonitorScreen extends StatefulWidget {
  @override
  _LogMonitorScreenState createState() => _LogMonitorScreenState();
}

class _LogMonitorScreenState extends State<LogMonitorScreen> {
  List<String> _logs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    try {
      // 这里我们模拟加载日志，实际应用中可能需要从文件或其他来源读取
      // 由于是演示，我们只显示最近的一些日志
      _logs = [
        '${DateTime.now().toString()} - 应用启动',
        '${DateTime.now().toString()} - 加载笔记数据: 15 条笔记',
        '${DateTime.now().toString()} - 主题模式: 浅色模式',
        '${DateTime.now().toString()} - 时间轴模式: 已关闭',
        '${DateTime.now().toString()} - 权限检查: 存储权限已授予',
        '${DateTime.now().toString()} - 数据库连接: 成功',
      ];
    } catch (e) {
      _logs = ['加载日志失败: $e'];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearLogs() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('清空日志'),
          content: Text('确定要清空所有日志吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _logs.clear();
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('日志已清空')),
                );
              },
              child: Text('清空', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('日志监控'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadLogs,
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? Center(child: Text('暂无日志'))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_logs[index]),
                      subtitle: Text(''),
                    );
                  },
                ),
    );
  }
}
