import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../services/hive_service.dart';
import '../settings/settings_screen.dart';
part 'todo_item.g.dart';

class TodoScreen extends StatefulWidget {
  @override
  _TodoScreenState createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  Box<TodoItem>? _todosBox;
  Box<DeletedTodoItem>? _recycledTodosBox;
  TextEditingController _controller = TextEditingController();
  DateTime? _selectedDueDate;
  bool _showRecycled = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  // 初始化Hive
  Future<void> _initializeHive() async {
    try {
      // 打开待办事项Box
      _todosBox = await Hive.openBox<TodoItem>('todos');
      // 打开回收站Box
      _recycledTodosBox = await Hive.openBox<DeletedTodoItem>('recycled_todos');
      
      // 如果待办事项Box为空，添加一些示例待办事项
      if (_todosBox!.isEmpty) {
        await _todosBox!.add(TodoItem('完成项目报告', false));
        await _todosBox!.add(TodoItem('回复客户邮件', true));
      }
      
      // 检查过期事项
      _checkExpiredTodos();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('初始化Hive失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 获取所有待办事项
  List<TodoItem> get _todos => _todosBox?.values.toList() ?? [];
  
  // 获取所有回收站待办事项
  List<DeletedTodoItem> get _recycledTodos => _recycledTodosBox?.values.toList() ?? [];

  // 检查过期事项
  void _checkExpiredTodos() async {
    try {
      for (var todo in _todos) {
        if (todo.checkExpired()) {
          await todo.save();
        }
      }
      setState(() {});
    } catch (e) {
      print('检查过期事项失败: $e');
    }
  }

  // 计算统计信息
  Map<String, int> _getStatistics() {
    int total = _todos.length;
    int completed = _todos.where((todo) => todo.isCompleted).length;
    int pending = total - completed;
    int expired = _todos.where((todo) => todo.isExpired).length;
    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'expired': expired,
    };
  }

  // 显示日期选择器
  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDueDate = picked;
      });
    }
  }

  // 恢复回收站中的待办事项
  void _restoreTodo(int index) async {
    try {
      final recycledTodo = _recycledTodos[index];
      await _todosBox?.add(recycledTodo.todo);
      await recycledTodo.delete();
      setState(() {});
      _checkExpiredTodos();
    } catch (e) {
      print('恢复待办事项失败: $e');
    }
  }

  // 永久删除回收站中的待办事项
  void _permanentlyDeleteTodo(int index) async {
    try {
      final recycledTodo = _recycledTodos[index];
      await recycledTodo.delete();
      setState(() {});
    } catch (e) {
      print('永久删除待办事项失败: $e');
    }
  }

  // 清空回收站
  void _emptyRecycled() async {
    try {
      await _recycledTodosBox?.clear();
      setState(() {});
    } catch (e) {
      print('清空回收站失败: $e');
    }
  }

  void _addTodo() async {
    if (_controller.text.trim().isNotEmpty) {
      try {
        final todo = TodoItem(_controller.text.trim(), false);
        todo.dueDate = _selectedDueDate;
        await _todosBox?.add(todo);
        setState(() {
          _controller.clear();
          _selectedDueDate = null;
        });
      } catch (e) {
        print('添加待办事项失败: $e');
      }
    }
  }

  void _toggleTodo(int index) async {
    try {
      final todo = _todos[index];
      todo.isCompleted = !todo.isCompleted;
      await todo.save();
      setState(() {});
    } catch (e) {
      print('更新待办事项失败: $e');
    }
  }

  void _deleteTodo(int index) async {
    try {
      final deletedTodo = _todos[index];
      await _recycledTodosBox?.add(DeletedTodoItem(deletedTodo));
      await deletedTodo.delete();
      setState(() {});
    } catch (e) {
      print('删除待办事项失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: SizedBox.shrink(),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 检查过期事项
    _checkExpiredTodos();
    // 获取统计信息
    final stats = _getStatistics();

    return WillPopScope(
      onWillPop: () async {
        if (_showRecycled) {
          setState(() {
            _showRecycled = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_showRecycled ? '回收站' : '待办事项'),
          leading: _showRecycled ? IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _showRecycled = false;
              });
            },
          ) : null,
          actions: [
            if (!_showRecycled) IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: () {
                setState(() {
                  _showRecycled = !_showRecycled;
                });
              },
            ),
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
      body: Column(
        children: [
          // 统计信息
          if (!_showRecycled) 
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('总数', stats['total']!),
                  _buildStatItem('已完成', stats['completed']!),
                  _buildStatItem('待处理', stats['pending']!),
                  _buildStatItem('已过期', stats['expired']!, isWarning: true),
                ],
              ),
            ),

          // 回收站标题
          if (_showRecycled) 
            Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('回收站', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: _emptyRecycled,
                    child: Text('清空回收站', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),

          // 添加待办事项输入框
          if (!_showRecycled) 
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: '输入待办事项...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _selectDueDate,
                        child: Text(_selectedDueDate != null 
                          ? '截止: ${_selectedDueDate!.month}/${_selectedDueDate!.day}' 
                          : '截止日期'
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addTodo,
                        child: Text('添加'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 待办事项列表
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    ),
    );
  }

  // 构建统计项
  Widget _buildStatItem(String label, int value, {bool isWarning = false}) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isWarning ? Colors.red : Colors.black,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // 构建内容
  Widget _buildContent() {
    if (_showRecycled) {
      return _buildRecycledList();
    } else {
      if (_todos.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('暂无待办事项', style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 8),
              Text('点击上方输入框添加新的待办事项', style: TextStyle(color: Colors.grey)),
            ],
          ),
        );
      } else {
        return ListView.builder(
          itemCount: _todos.length,
          itemBuilder: (context, index) {
            final todo = _todos[index];
            return ListTile(
              leading: Checkbox(
                value: todo.isCompleted,
                onChanged: (_) => _toggleTodo(index),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    todo.title,
                    style: TextStyle(
                      decoration: todo.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                      color: todo.isExpired ? Colors.red : (todo.isCompleted ? Colors.grey : null),
                    ),
                  ),
                  if (todo.dueDate != null) 
                    Text(
                      '截止: ${todo.dueDate!.year}-${todo.dueDate!.month}-${todo.dueDate!.day}',
                      style: TextStyle(
                        fontSize: 12,
                        color: todo.isExpired ? Colors.red : Colors.grey,
                      ),
                    ),
                ],
              ),
              subtitle: Text(
                '创建: ${todo.createdAt.year}-${todo.createdAt.month}-${todo.createdAt.day}',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _deleteTodo(index),
              ),
            );
          },
        );
      }
    }
  }

  // 构建回收站列表
  Widget _buildRecycledList() {
    if (_recycledTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('回收站为空', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _recycledTodos.length,
      itemBuilder: (context, index) {
        final recycledTodo = _recycledTodos[index];
        final todo = recycledTodo.todo;
        return ListTile(
          title: Text(
            todo.title,
            style: TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey),
          ),
          subtitle: Text(
            '删除于: ${recycledTodo.deletedAt.year}-${recycledTodo.deletedAt.month}-${recycledTodo.deletedAt.day}',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.restore),
                onPressed: () => _restoreTodo(index),
              ),
              IconButton(
                icon: Icon(Icons.delete_forever, color: Colors.red),
                onPressed: () => _permanentlyDeleteTodo(index),
              ),
            ],
          ),
        );
      },
    );
  }
}

@HiveType(typeId: 3)
class TodoItem extends HiveObject {
  @HiveField(0)
  String title;
  @HiveField(1)
  bool isCompleted;
  @HiveField(2)
  DateTime createdAt;
  @HiveField(3)
  DateTime? dueDate;
  @HiveField(4)
  bool isExpired;

  TodoItem(this.title, this.isCompleted) 
    : createdAt = DateTime.now(),
      isExpired = false;

  // 检查是否过期
  bool checkExpired() {
    if (dueDate != null && !isCompleted) {
      isExpired = dueDate!.isBefore(DateTime.now());
      return isExpired;
    }
    return false;
  }
}

// 回收站中的待办事项
@HiveType(typeId: 4)
class DeletedTodoItem extends HiveObject {
  @HiveField(0)
  TodoItem todo;
  @HiveField(1)
  DateTime deletedAt;

  DeletedTodoItem(this.todo) : deletedAt = DateTime.now();
}

