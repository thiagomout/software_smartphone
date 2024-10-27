import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
      home: const LoginPage(title: 'Minha Lista de Tarefas'),
    );
  }
}

class AuthService {
  Future<String> fazerLogin(String email, String senha) async {
    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/fazer_login');
    final client = http.Client();

    final headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final body = {
      'email': email,
      'senha': senha,
    };

    try {
      final jsonBody = json.encode(body);
      final response = await client.post(url, headers: headers, body: jsonBody);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('token') && responseData['token'] != null) {
          String token = responseData['token'];
          return token;
        } else {
          return '';
        }
      } else {
        return '';
      }
    } catch (e) {
      return '';
    } finally {
      client.close();
    }
  }
  Future<String> registrarUsuario(String email, String senha, String nome, String celular) async {
    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/registra_usuario');
    final client = http.Client();

    final headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final body = {
      'nome': nome,
      'email': email,
      'celular': celular,
      'senha': senha
    };

    try {
      final jsonBody = json.encode(body);
      final response = await client.post(url, headers: headers, body: jsonBody);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData.containsKey('token') && responseData['token'] != null) {
          String token = responseData['token'];
          return token;
        } else {
          return '';
        }
      } else {
        return '';
      }
    } catch (e) {
      return '';
      }
      finally {
      client.close();
    }
  }

  Future<void> criarListaVazia(String token, String email) async {
    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/tarefas');
    final client = http.Client();

    final headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = json.encode({
      'email': email,
      'valor': [],
    });

    try {
      final response = await client.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
      } else {
      }
    } catch (e) {
      if (kDebugMode) {
        print('Ocorreu um erro: ${e.toString()}');
      }
    } finally {
      client.close();
    }
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required String title});

  @override
  State<LoginPage> createState(){
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _login() async {
    setState(() {
      _isLoading = true;
    });
    String token = await _authService.fazerLogin(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    setState(() {
      _isLoading = false;
    });
    if (mounted) {
      if (token.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TaskScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha no login. Verifique suas credenciais.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Entrar'),
                  ),
            TextButton(
              onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RegisterPage()),
              );
              },
              child: const Text('Registrar-se'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
    const RegisterPage({super.key});

    @override
    State<RegisterPage> createState() {
      return _RegisterPageState();
    }
  }
  class _RegisterPageState extends State<RegisterPage> {
    final _emailController = TextEditingController();
    final _nameController = TextEditingController();
    final _phonenunberController = TextEditingController();
    final _passwordController = TextEditingController();
    final _confirmpasswordController = TextEditingController();
    final AuthService _authService = AuthService();
    bool _isLoading = false;

    void _register() async {
      setState(() {
        _isLoading = true;
      });

      setState(() {
        _isLoading = false;
      });

      if (mounted){
        if (_nameController.text.trim().isEmpty || 
        _emailController.text.trim().isEmpty || 
        _phonenunberController.text.trim().isEmpty || 
        _passwordController.text.trim().isEmpty || 
        _confirmpasswordController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preencha todos os campos.')),
          );
          return;
        }
      }
      if (mounted){
        if(_nameController.text.trim().length < 3){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('O nome deve ter no mínimo 3 caracteres.')),
          );
          return;
        }
      }
      // Validação do email
      if (mounted){
        if (!_emailController.text.trim().contains('@') || !_emailController.text.trim().contains('.')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email inválido.')),
          );
          return;
        }
      }
      // Validação do celular
      if (mounted){
        if (_phonenunberController.text.trim().length < 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Celular inválido.')),
          );
          return;
        }
      }
      if (mounted){
        if (_passwordController.text.trim().length < 8) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('A senha deve ter no mínimo 8 caracteres.')),
          );return;
        }
      }
      if (mounted) {
        if (_passwordController.text.trim() != _confirmpasswordController.text.trim()) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('As senhas devem ser iguais.'))
          );
          return;
        } 
        String token = await _authService.registrarUsuario(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _phonenunberController.text.trim(),
      );
      if (mounted && token.isNotEmpty) {
            Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage(title: '',)),
          );
        }
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email já registrado.')),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Registrar-se'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _phonenunberController,
                decoration: const InputDecoration(labelText: 'Celular'),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha'),
              ),
              TextField(
                controller: _confirmpasswordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirme a senha'),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      child: const Text('Registrar'),
                    ),
            ],
          ),
        ),
      );
    }
  }

class Task {
  String name;
  bool isCompleted;
  bool isMarkedForDeletion;

  Task(this.name, {this.isCompleted = false, this.isMarkedForDeletion = false});
}

class TaskScreen extends StatefulWidget {
  final String title;

  const TaskScreen({super.key, this.title = 'Lista de Tarefas'});

  @override
  State <TaskScreen> createState() {
    return _TaskScreenState();
  }
}

class _TaskScreenState extends State<TaskScreen> {
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