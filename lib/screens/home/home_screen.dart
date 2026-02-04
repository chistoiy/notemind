
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../../providers/app_config_provider.dart';
import '../../services/hive_service.dart';
import '../../models/note.dart';
import '../edit/edit_screen.dart';
import '../detail/detail_screen.dart';
import '../category/category_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/note_item.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = '全部';
  RefreshController _refreshController = RefreshController(initialRefresh: false);
  bool _isTimelineMode = false; // true: 时间轴模式, false: 普通模式
  String _timelineSortBy = 'updatedAt'; // 'createdAt' 或 'updatedAt'

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  // 加载笔记
  Future<void> _loadNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notes = HiveService.getAllNotes();
      _sortNotes(notes);
      setState(() {
        _notes = notes;
        _filterNotes();
        _isLoading = false;
      });
    } catch (e) {
      print('加载笔记失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 排序笔记
  void _sortNotes(List<Note> notes) {
    final sortBy = context.read<AppConfigProvider>().sortBy;
    
    notes.sort((a, b) {
      // 置顶笔记优先
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      
      // 然后按排序方式
      if (sortBy == 'date') {
        return b.updatedAt.compareTo(a.updatedAt);
      } else {
        return a.title.compareTo(b.title);
      }
    });
  }

  // 筛选笔记
  void _filterNotes() {
    if (_searchQuery.isEmpty && _selectedCategory == '全部') {
      _filteredNotes = _notes;
    } else {
      _filteredNotes = _notes.where((note) {
        final matchesSearch = note.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            note.content.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesCategory = _selectedCategory == '全部' || note.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    }
    // 时间轴模式下需要根据时间排序
    if (_isTimelineMode) {
      _sortTimelineNotes();
    }
  }

  // 时间轴笔记排序
  void _sortTimelineNotes() {
    _filteredNotes.sort((a, b) {
      if (_timelineSortBy == 'createdAt') {
        return b.createdAt.compareTo(a.createdAt);
      } else {
        return b.updatedAt.compareTo(a.updatedAt);
      }
    });
  }

  // 下拉刷新
  void _onRefresh() async {
    await _loadNotes();
    _refreshController.refreshCompleted();
  }

  // 导航到编辑页面
  void _navigateToEdit([Note? note]) async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => EditScreen(note: note)),
    );
    if (result == true) {
      _loadNotes();
    }
  }

  // 导航到详情页面（直接进入编辑页面的预览模式）
  void _navigateToDetail(Note note) async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => EditScreen(note: note)),
    );
    if (result == true) {
      _loadNotes();
    }
  }

  // 导航到分类页面
  void _navigateToCategory() async {
    final result = await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => CategoryScreen()),
    );
    if (result != null) {
      setState(() {
        _selectedCategory = result;
        _filterNotes();
      });
    }
  }

  // 导航到设置页面
  void _navigateToSettings() async {
    await Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    );
    // 从设置页面返回时重新加载笔记，确保导入的笔记可见
    _loadNotes();
  }

  // 切换排序方式
  void _toggleSortBy() {
    final provider = context.read<AppConfigProvider>();
    final newSortBy = provider.sortBy == 'date' ? 'title' : 'date';
    provider.setSortBy(newSortBy);
    _loadNotes();
  }

  // 切换视图模式
  void _toggleViewMode() {
    context.read<AppConfigProvider>().toggleViewMode();
  }

  // 切换时间轴模式
  void _toggleTimelineMode() {
    setState(() {
      _isTimelineMode = !_isTimelineMode;
      if (_isTimelineMode) {
        _sortNotesByTimeline();
      } else {
        _loadNotes();
      }
    });
  }

  // 切换时间轴排序方式
  void _toggleTimelineSortBy() {
    setState(() {
      _timelineSortBy = _timelineSortBy == 'updatedAt' ? 'createdAt' : 'updatedAt';
      _sortNotesByTimeline();
    });
  }

  // 按时间轴排序笔记
  void _sortNotesByTimeline() {
    _filteredNotes.sort((a, b) {
      if (_timelineSortBy == 'createdAt') {
        return b.createdAt.compareTo(a.createdAt);
      } else {
        return b.updatedAt.compareTo(a.updatedAt);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appConfig = context.watch<AppConfigProvider>();

    // 当设置中时间轴模式变化时，自动切换时间轴视图
    if (appConfig.timelineMode != _isTimelineMode) {
      setState(() {
        _isTimelineMode = appConfig.timelineMode;
        if (_isTimelineMode) {
          _sortNotesByTimeline();
        } else {
          _loadNotes();
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Notemind'),
        actions: [
          if (!_isTimelineMode)
            IconButton(
              icon: Icon(appConfig.viewMode == 'grid' ? Icons.view_list : Icons.grid_view),
              onPressed: _toggleViewMode,
            ),
          if (!_isTimelineMode)
            IconButton(
              icon: Icon(Icons.sort),
              onPressed: _toggleSortBy,
            ),
          if (!_isTimelineMode && appConfig.timelineMode)
            IconButton(
              icon: Icon(Icons.timeline),
              onPressed: _toggleTimelineMode,
            ),
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: _navigateToSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索笔记...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterNotes();
                });
              },
            ),
          ),

          // 分类筛选
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('分类: $_selectedCategory'),
                ElevatedButton(
                  onPressed: _navigateToCategory,
                  child: Text('管理分类'),
                ),
              ],
            ),
          ),

          // 时间轴排序方式切换（仅时间轴模式显示）
          if (_isTimelineMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _toggleTimelineSortBy,
                    child: Text(
                      _timelineSortBy == 'updatedAt' ? '按修改时间排序' : '按创建时间排序',
                    ),
                  ),
                ],
              ),
            ),

          // 笔记列表
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredNotes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_add, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('暂无笔记', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            SizedBox(height: 8),
                            Text('点击右下角按钮创建新笔记', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : appConfig.timelineMode && _isTimelineMode
                        ? _buildTimelineView()
                        : appConfig.viewMode == 'grid'
                            ? _buildGridView()
                            : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToEdit(),
        child: Icon(Icons.add),
      ),
    );
  }

  // 网格视图
  Widget _buildGridView() {
    return GridView.builder(
      padding: EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return NoteItem(
          note: note,
          onTap: () => _navigateToDetail(note),
          onEdit: () => _navigateToEdit(note),
          onDelete: () {
            HiveService.deleteNote(note);
            _loadNotes();
          },
          onPin: () {
            note.isPinned = !note.isPinned;
            HiveService.updateNote(note);
            _loadNotes();
          },
        );
      },
    );
  }

  // 列表视图
  Widget _buildListView() {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        return NoteItem(
          note: note,
          onTap: () => _navigateToDetail(note),
          onEdit: () => _navigateToEdit(note),
          onDelete: () {
            HiveService.deleteNote(note);
            _loadNotes();
          },
          onPin: () {
            note.isPinned = !note.isPinned;
            HiveService.updateNote(note);
            _loadNotes();
          },
        );
      },
    );
  }

  // 时间轴视图
  Widget _buildTimelineView() {
    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: _filteredNotes.length,
      itemBuilder: (context, index) {
        final note = _filteredNotes[index];
        final dateTime = _timelineSortBy == 'createdAt' ? note.createdAt : note.updatedAt;
        final formattedDate = '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
        final formattedTime = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

        return Container(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 左侧时间线
              Container(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 时间点
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    // 时间线
                    if (index < _filteredNotes.length - 1)
                      Container(
                        width: 2,
                        height: 80,
                        color: Colors.grey[300],
                      ),
                    // 时间
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        children: [
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            formattedTime,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 右侧笔记内容
              Expanded(
                child:
                  NoteItem(
                    note: note,
                    onTap: () => _navigateToDetail(note),
                    onEdit: () => _navigateToEdit(note),
                    onDelete: () {
                      HiveService.deleteNote(note);
                      _loadNotes();
                    },
                    onPin: () {
                      note.isPinned = !note.isPinned;
                      HiveService.updateNote(note);
                      _loadNotes();
                    },
                  ),
              ),
            ],
          ),
        );
      },
    );
  }
}
