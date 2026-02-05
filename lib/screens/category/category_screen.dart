
import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../../services/hive_service.dart';

class CategoryScreen extends StatefulWidget {
  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<String> _categories = [];
  List<String> _selectedCategories = [];
  TextEditingController _categoryController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  // 加载分类
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final categories = HiveService.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('加载分类失败: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 添加分类
  Future<void> _addCategory() async {
    final category = _categoryController.text.trim();
    if (category.isNotEmpty && !_categories.contains(category)) {
      try {
        await HiveService.addCategory(category);
        _categoryController.clear();
        await _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分类添加成功')),
        );
      } catch (e) {
        print('添加分类失败: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分类添加失败')),
        );
      }
    }
  }

  // 删除分类
  Future<void> _deleteCategory(String category) async {
    if (category == '未分类') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('默认分类不能删除')),
      );
      return;
    }

    try {
      await HiveService.deleteCategory(category);
      await _loadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分类删除成功')),
      );
    } catch (e) {
      print('删除分类失败: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分类删除失败')),
      );
    }
  }

  // 选择分类
  void _selectCategory(String category) {
    Navigator.pop(context, category);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('分类管理'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _selectedCategories),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () => Navigator.pop(context, _selectedCategories),
          ),
        ],
      ),
      body: Column(
        children: [
          // 添加分类
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      hintText: '输入新分类名称',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _addCategory,
                  child: Text('添加'),
                ),
              ],
            ),
          ),

          // 分类列表
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: EdgeInsets.all(8),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Card(
                        elevation: 2,
                        child: ListTile(
                          leading: Checkbox(
                            value: _selectedCategories.contains(category),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedCategories.add(category);
                                } else {
                                  _selectedCategories.remove(category);
                                }
                              });
                            },
                          ),
                          title: Text(category),
                          trailing: category != '未分类'
                              ? IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteCategory(category),
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              if (_selectedCategories.contains(category)) {
                                _selectedCategories.remove(category);
                              } else {
                                _selectedCategories.add(category);
                              }
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
