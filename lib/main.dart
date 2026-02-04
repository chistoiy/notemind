import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home/home_screen.dart';
import 'providers/app_config_provider.dart';
import 'services/hive_service.dart';
import 'services/log_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  log.info('应用启动');

  try {
    // 初始化Hive数据库
    log.info('开始初始化Hive数据库');
    await HiveService.initialize();
    log.info('Hive数据库初始化成功');

    // 初始化应用配置
    log.info('开始初始化应用配置');
    final appConfig = AppConfigProvider();
    await appConfig.initialize();
    log.info('应用配置初始化成功');
    log.info('主题模式: ${appConfig.isDarkMode ? '暗黑模式' : '浅色模式'}');
    log.info('时间轴模式: ${appConfig.timelineMode ? '已开启' : '已关闭'}');

    runApp(ChangeNotifierProvider.value(value: appConfig, child: MyApp()));

    log.info('应用启动成功');
  } catch (e, stackTrace) {
    log.error('应用启动失败', e, stackTrace);
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigProvider>();

    return MaterialApp(
      title: 'Notemind',
      theme: appConfig.themeData,
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

