import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(TodoApp());
}

class Todo {
  final String id;
  final String title;
  bool isDone;

  Todo({
    required this.id,
    required this.title,
    this.isDone = false,
  });

  Todo.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        title = json['title'],
        isDone = json['isDone'];

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isDone': isDone,
      };
}

class TodoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: TodoListScreen(),
    );
  }
}

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late List<Todo> _todos;
  late TextEditingController _textEditingController;
  late SharedPreferences _preferences;
  late bool _isLoading;
  late String _currentFilter;
  late Map<String, dynamic> _currentTheme;

  List<Map<String, dynamic>> _colorThemes = [
    {
      'name': 'Blue',
      'primaryColor': Colors.blue,
      'accentColor': Colors.blueAccent,
    },
    {
      'name': 'Green',
      'primaryColor': Colors.green,
      'accentColor': Colors.greenAccent,
    },
    {
      'name': 'Red',
      'primaryColor': Colors.red,
      'accentColor': Colors.redAccent,
    },
    {
      'name': 'purple',
      'primaryColor': Colors.purple,
      'accentColor': Colors.purple,
    },
  ];

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
    _isLoading = true;
    _currentFilter = 'All';
    _currentTheme = _colorThemes[0];
    _initializeTodos();
  }

  Future<void> _initializeTodos() async {
    _preferences = await SharedPreferences.getInstance();
    final todosString = _preferences.getString('todos');
    final themeString = _preferences.getString('theme');
    if (todosString != null) {
      final todosJson = json.decode(todosString) as List;
      _todos = todosJson.map((json) => Todo.fromJson(json)).toList();
    } else {
      _todos = [];
    }
    if (themeString != null) {
      _currentTheme =
          _colorThemes.firstWhere((theme) => theme['name'] == themeString);
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveTodos() async {
    final todosJson = json.encode(_todos);
    await _preferences.setString('todos', todosJson);
    await _preferences.setString('theme', _currentTheme['name']);
  }

  void _addTodo() {
    final title = _textEditingController.text.trim();
    if (title.isNotEmpty) {
      final newTodo = Todo(
        id: DateTime.now().toString(),
        title: title,
      );
      setState(() {
        _todos.add(newTodo);
      });
      _saveTodos();
      _textEditingController.clear();
    }
  }

  void _updateTodoStatus(int index, bool isDone) {
    setState(() {
      _todos[index].isDone = isDone;
    });
    _saveTodos();
  }

  void _deleteTodoAt(int index) {
    setState(() {
      _todos.removeAt(index);
    });
    _saveTodos();
  }

  void _filterTodos(String filter) {
    setState(() {
      _currentFilter = filter;
      final todosString = _preferences.getString('todos');
      if (todosString != null) {
        final todosJson = json.decode(todosString) as List;
        _todos = todosJson.map((json) => Todo.fromJson(json)).toList();
      } else {
        _todos = [];
      }
      switch (filter) {
        case 'Done':
          _todos = _todos.where((todo) => todo.isDone).toList();
          break;
        case 'Undone':
          _todos = _todos.where((todo) => !todo.isDone).toList();
          break;
        case 'Progress':
          // Filter for tasks in progress, modify the condition as needed
          _todos = _todos.where((todo) => !todo.isDone).toList();
          break;
        case 'Cancel':
          // Filter for canceled tasks, modify the condition as needed
          _todos = _todos.where((todo) => todo.isDone).toList();
          break;
        default:
          // No filter applied, show all todos
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return MaterialApp(
      title: 'Todo App',
      theme: ThemeData(
        primarySwatch: _currentTheme['primaryColor'],
        // accentColor: _currentTheme['accentColor'],
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('Todo List'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _textEditingController,
                decoration: InputDecoration(
                  labelText: 'Add Todo',
                ),
                onSubmitted: (_) => _addTodo(),
              ),
            ),
            DropdownButton<Map<String, dynamic>>(
              value: _currentTheme,
              items: _colorThemes
                  .map<DropdownMenuItem<Map<String, dynamic>>>((theme) {
                return DropdownMenuItem<Map<String, dynamic>>(
                  value: theme,
                  child: Text(theme['name']),
                );
              }).toList(),
              onChanged: (Map<String, dynamic>? value) {
                if (value != null) {
                  setState(() {
                    _currentTheme = value;
                  });
                }
              },
            ),
            DropdownButton<String>(
              value: _currentFilter,
              items: ['All', 'Done', 'Undone', 'Progress', 'Cancel']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? value) {
                if (value != null) {
                  _filterTodos(value);
                }
              },
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _todos.length,
                itemBuilder: (context, index) {
                  final todo = _todos[index];
                  return ListTile(
                    leading: Checkbox(
                      value: todo.isDone,
                      onChanged: (bool? value) {
                        if (value != null) {
                          _updateTodoStatus(index, value);
                        }
                      },
                    ),
                    title: Text(todo.title),
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () => _deleteTodoAt(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
