import 'package:flutter/material.dart';
import '../../services/hive_service.dart';
import '../../models/note.dart';
import '../settings/settings_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  @override
  _AnalyticsScreenState createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<Note> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = HiveService.getAllNotes();
      setState(() {
        _notes = notes;
        _isLoading = false;
      });
    } catch (e) {
      print('加载笔记失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 生成热力图数据
  List<List<double>> _generateHeatmapData() {
    // 生成7x12的热力图数据，表示7天（周一到周日），12个月
    List<List<double>> data = [];

    // 纵向：周一到周日（0-6）
    for (int i = 0; i < 7; i++) {
      List<double> row = [];
      // 横向：1-12月
      for (int j = 0; j < 12; j++) {
        // 计算这个时间点的笔记活跃度
        double activity = 0.0;
        for (final note in _notes) {
          // 检查创建时间
          if (note.createdAt.weekday - 1 == i &&
              note.createdAt.month - 1 == j) {
            activity += 1.0;
          }
          // 检查更新时间
          if (note.updatedAt.weekday - 1 == i &&
              note.updatedAt.month - 1 == j) {
            activity += 0.5;
          }
        }
        row.add(activity);
      }
      data.add(row);
    }

    return data;
  }

  // 构建热力图
  Widget _buildHeatmap() {
    final data = _generateHeatmapData();
    final totalNotes = _notes.length;
    final totalWords = _calculateTotalWords();

    // 星期几的中文名称（只显示首字，参考GitHub样式）
    final weekdays = ['一', '二', '三', '四', '五', '六', '日'];
    // 月份名称
    final months = [
      '1',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      '11',
      '12',
    ];

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 月份标签（在网格上方）
          Container(
            padding: EdgeInsets.only(left: 30), // 与星期几标签对齐
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(12, (index) {
                return Container(
                  width: 24,
                  alignment: Alignment.center,
                  child: Text(
                    months[index],
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 4),
          // 热力图容器
          Container(
            child: Row(
              children: [
                // 纵向坐标（星期几）
                Container(
                  width: 30,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (index) {
                      return Container(
                        height: 24,
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${weekdays[index]}',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(width: 4),
                // 热力图网格
                Container(
                  width: 12 * 26, // 12个月 * (24px + 2px间距)
                  height: 7 * 26, // 7天 * (24px + 2px间距)
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 12,
                      childAspectRatio: 1.0,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                    ),
                    itemCount: 7 * 12,
                    itemBuilder: (context, index) {
                      int weekday = index ~/ 12;
                      int month = index % 12;
                      double value = data[weekday][month];

                      // 根据活跃度值计算颜色
                      Color color = _getHeatmapColor(value);

                      return GestureDetector(
                        onTap: () {
                          // 显示具体信息
                          _showHeatmapInfo(weekday, month, value);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildHeatmapLegend(0.0, Colors.white),
              _buildHeatmapLegend(1.0, Colors.blue[100]!),
              _buildHeatmapLegend(2.0, Colors.blue[300]!),
              _buildHeatmapLegend(3.0, Colors.blue[500]!),
              _buildHeatmapLegend(4.0, Colors.blue[700]!),
              _buildHeatmapLegend(5.0, Colors.blue[900]!),
            ],
          ),
          SizedBox(height: 24),
          // 统计信息
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '笔记统计信息',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('总笔记数', totalNotes),
                    _buildStatItem('总字数', totalWords),
                    _buildStatItem(
                      '平均字数',
                      totalNotes > 0 ? totalWords ~/ totalNotes : 0,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 计算总字数
  int _calculateTotalWords() {
    int total = 0;
    for (final note in _notes) {
      // 简单计算字数，实际应用中可以根据需要调整计算逻辑
      total += note.title.length + note.content.length;
    }
    return total;
  }

  // 显示热力图信息
  void _showHeatmapInfo(int weekday, int month, double value) {
    // 星期几的中文名称
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('笔记活跃度'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('时间: ${weekdays[weekday]} · ${month + 1}月'),
              Text('活跃度: $value'),
              Text('活跃度说明: 活跃度基于笔记的创建和更新时间计算，创建笔记贡献1.0，更新笔记贡献0.5。'),
              Text('具体统计: 在${weekdays[weekday]} · ${month + 1}月期间的笔记活动情况。'),
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

  // 获取热力图颜色
  Color _getHeatmapColor(double value) {
    if (value == 0) return Colors.white;
    if (value <= 1) return Colors.blue[100]!;
    if (value <= 2) return Colors.blue[300]!;
    if (value <= 3) return Colors.blue[500]!;
    if (value <= 4) return Colors.blue[700]!;
    return Colors.blue[900]!;
  }

  // 构建热力图图例
  Widget _buildHeatmapLegend(double value, Color color) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Text(value.toString(), style: TextStyle(fontSize: 12)),
      ],
    );
  }

  // 构建统计信息
  Widget _buildStatistics() {
    int totalNotes = _notes.length;
    int pinnedNotes = _notes.where((note) => note.isPinned).length;
    int completedNotes = _notes
        .where((note) => note.isPinned)
        .length; // 这里假设isPinned表示已完成

    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            '笔记统计',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('总笔记数', totalNotes),
              _buildStatItem('置顶笔记', pinnedNotes),
              _buildStatItem('已完成', completedNotes),
            ],
          ),
        ],
      ),
    );
  }

  // 构建统计项
  Widget _buildStatItem(String label, int value) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('分析'),
        actions: [
          // 添加设置按钮
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(children: [_buildStatistics(), _buildHeatmap()]),
            ),
    );
  }
}
