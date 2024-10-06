import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de Tarefas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
      ),
      home: const MyHomePage(title: 'Minha Lista de Tarefas'),
    );
  }
}

class Task {
  String name;
  bool isCompleted;
  bool isMarkedForDeletion;

  Task(this.name, {this.isCompleted = false, this.isMarkedForDeletion = false});
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<Task> taskList = [];
  final textController = TextEditingController();
  Task? _taskMarkedForDeletion;
  bool _isUndoVisible = false;

  void _addTask(String taskName) {
    setState(() {
      if (taskName.trim().isNotEmpty &&
          !taskList.any((task) => task.name == taskName)) {
        taskList.insert(0, Task(taskName.trim()));
        textController.clear();
      }
    });
  }

  void _markTaskForDeletion(Task task) {
    setState(() {
      task.isMarkedForDeletion = true;
      _isUndoVisible = true;
      _taskMarkedForDeletion = task;
      Future.delayed(const Duration(seconds: 3), () {
        if (_isUndoVisible && task.isMarkedForDeletion) {
          _deleteTask(task);
        }
      });
    });
  }

  void _deleteTask(Task task) {
    setState(() {
      taskList.remove(task);
      _isUndoVisible = false;
    });
  }

  void _undoDeletion() {
    setState(() {
      if (_taskMarkedForDeletion != null) {
        _taskMarkedForDeletion!.isMarkedForDeletion = false;
        _isUndoVisible = false;
      }
    });
  }

  void _toggleTaskCompletion(Task task) {
    setState(() {
      task.isCompleted = !task.isCompleted;
      taskList.remove(task);
      if (task.isCompleted) {
        // Move to the beginning of completed tasks
        int lastUncompletedIndex =
            taskList.lastIndexWhere((t) => !t.isCompleted);
        // Add right after the last uncompleted task
        taskList.insert(lastUncompletedIndex + 1, task);
      } else {
        // Move to the top of the list if uncompleted
        taskList.insert(0, task);
      }
    });
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: textController,
              autofocus: true,
              onSubmitted: _addTask,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Digite uma tarefa',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => _addTask(textController.text),
            child: const Text('Incluir Tarefa'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: taskList.length,
              itemBuilder: (context, index) {
                final task = taskList[index];
                return Dismissible(
                  key: Key(task.name),
                  confirmDismiss: (direction) async {
                    if (direction == DismissDirection.startToEnd) {
                      _toggleTaskCompletion(task);
                      return false;
                    } else if (direction == DismissDirection.endToStart) {
                      _markTaskForDeletion(task);
                      return false;
                    }
                    return false;
                  },
                  background: Container(
                    color: Colors.green,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.check, color: Colors.white),
                  ),
                  secondaryBackground: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    color: task.isMarkedForDeletion
                        ? Colors.red[100]
                        : index % 2 == 0 ? Colors.grey[200] : Colors.grey[400],
                    child: ListTile(
                      title: Text(
                        task.name,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      trailing: task.isMarkedForDeletion
                          ? ElevatedButton(
                              onPressed: _undoDeletion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Desfazer'),
                            )
                          : IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _markTaskForDeletion(task),
                            ),
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (value) {
                          _toggleTaskCompletion(task);
                        },
                      ),
                    ),
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