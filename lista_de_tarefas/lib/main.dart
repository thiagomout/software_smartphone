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
        if (responseData.containsKey('token') &&
            responseData['token'] != null) {
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

  Future<String> registrarUsuario(
      String email, String senha, String nome, String celular) async {
    final url = Uri.https('barra.cos.ufrj.br:443', 'rest/rpc/registra_usuario');
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
        // Retorna "ok" se o registro foi bem-sucedido
        return 'ok';
      } else if (response.statusCode == 400) {
        // Exibe a mensagem de erro retornada pela API
        final responseData = json.decode(response.body);
        return responseData['message'] ?? 'Erro desconhecido ao registrar';
      } else {
        return 'Erro inesperado. Código: ${response.statusCode}';
      }
    } catch (e) {
      return 'Ocorreu um erro: ${e.toString()}';
    } finally {
      client.close();
    }
  }

  final String baseUrl = 'https://barra.cos.ufrj.br/rest';

  Future<List<Task>> carregarTarefas(
      String token, String email, BuildContext context) async {
    final url = Uri.parse('$baseUrl/tarefas?email=eq.$email');
    final headers = {
      'Authorization': 'Bearer $token',
      'accept': 'application/json',
    };

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData is List && responseData.isEmpty) {
          if (kDebugMode) print('Nenhuma tarefa encontrada.');
          return [];
        }

        if (responseData is List && responseData.isNotEmpty) {
          final tasksJson = responseData[0]['valor'];
          if (tasksJson is List) {
            return tasksJson
                .map((taskJson) => Task.fromJson(taskJson))
                .toList();
          } else {
            if (kDebugMode) print('Erro: "valor" não é uma lista.');
            return [];
          }
        } else {
          if (kDebugMode) {
            print('Estrutura inesperada na resposta da API ao carregar tarefas.');
          }
          return [];
        }
      } else {
        final responseData = json.decode(response.body);
        if (responseData['message'] == "JWT expired") {
          if (kDebugMode) {
            print('Token expirado. Redirecionando para a tela de login.');
          }
          if (context.mounted) _redirectToLogin(context);
          return [];
        } else {
          if (kDebugMode) {
            print('Erro ao carregar tarefas: ${response.statusCode} - ${response.body}');
          }
          return [];
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar tarefas: $e');
      return [];
    }
  }

  Future<void> salvarTarefas(String token, String email, List<Task> tasks,
      BuildContext context) async {
    final url = Uri.parse('$baseUrl/tarefas');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final body = json.encode({
      'email': email,
      'valor': tasks.map((task) => task.toJson()).toList(),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        if (kDebugMode) print('Tarefas criadas com sucesso.');
      } else if (response.statusCode == 409) {
        final patchResponse =
            await http.patch(url, headers: headers, body: body);
        if (patchResponse.statusCode == 204) {
          if (kDebugMode) print('Tarefas atualizadas com sucesso.');
        }
      } else {
        final responseData = json.decode(response.body);
        if (responseData['message'] == "JWT expired") {
          if (kDebugMode) {
            print('Token expirado. Redirecionando para a tela de login.');
          }
          if (context.mounted) _redirectToLogin(context);
        } else {
          if (kDebugMode) {
            print('Erro ao salvar tarefas com PATCH: ${response.statusCode} - ${response.body}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao salvar tarefas: $e');
    }
  }

  Future<void> deletarTarefas(
      String token, String email, BuildContext context) async {
    final url = Uri.parse('$baseUrl/tarefas?email=eq.$email');
    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 204) {
        if (kDebugMode) print('Todas as tarefas foram deletadas com sucesso.');
      } else {
        final responseData = json.decode(response.body);
        if (responseData['message'] == "JWT expired") {
          if (kDebugMode) {
            print('Token expirado. Redirecionando para a tela de login.');
          }
          if (context.mounted) _redirectToLogin(context);
        } else {
          if (kDebugMode) {
            print('Erro ao deletar tarefas: ${response.statusCode} - ${response.body}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao deletar tarefas: $e');
    }
  }

  void _redirectToLogin(BuildContext context) {
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const LoginPage(title: 'Login')),
      );
    }
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required String title});

  @override
  State<LoginPage> createState() {
    return _LoginPageState();
  }
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FocusNode _passwordFocusNode = FocusNode();
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
      if (kDebugMode) {
        print('Token de acesso: $token');
      }
      if (token.isNotEmpty) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => TaskScreen(
                  token: token, email: _emailController.text.trim())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Falha no login. Verifique suas credenciais.')),
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
              textInputAction:
                  TextInputAction.next, // Ação para o próximo campo
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(
                    _passwordFocusNode); // Move o foco para o campo de senha
              },
            ),
            TextField(
              controller: _passwordController,
              focusNode:
                  _passwordFocusNode, // Associa o FocusNode ao campo de senha
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
              onSubmitted: (_) =>
                  _login(), // Login ao pressionar Enter no campo de senha
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
  final _phoneNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _phoneNumberFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _isLoading = false;

  void _register() async {
    // Validar campos obrigatórios
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _phoneNumberController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _confirmPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos.')),
      );
      return;
    }

    // Validação de comprimento do nome
    if (_nameController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('O nome deve ter no mínimo 3 caracteres.')),
      );
      return;
    }

    // Validação do formato de email
    if (!_emailController.text.trim().contains('@') ||
        !_emailController.text.trim().contains('.')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email inválido.')),
      );
      return;
    }

    // Validação do número de celular
    if (_phoneNumberController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Celular inválido.')),
      );
      return;
    }

    // Validação de senha
    if (_passwordController.text.trim().length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('A senha deve ter no mínimo 8 caracteres.')),
      );
      return;
    }

    // Verificar se as senhas coincidem
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas devem ser iguais.')),
      );
      return;
    }

    // Exibir indicador de carregamento
    setState(() {
      _isLoading = true;
    });

    // Registrar usuário e obter token
    String result = await _authService.registrarUsuario(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _nameController.text.trim(),
      _phoneNumberController.text.trim(),
    );

    setState(() {
      _isLoading = false;
    });

    // Verificar resultado do registro
    if (mounted) {
      if (result == 'ok') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro bem-sucedido!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage(title: '')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_emailFocusNode);
              },
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              focusNode: _emailFocusNode,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_phoneNumberFocusNode);
              },
            ),
            TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(labelText: 'Celular'),
              focusNode: _phoneNumberFocusNode,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_passwordFocusNode);
              },
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Senha'),
              focusNode: _passwordFocusNode,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
              },
            ),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirme a senha'),
              focusNode: _confirmPasswordFocusNode,
              onSubmitted: (_) => _register(),
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
  String title;
  bool isCompleted;
  int order;
  bool isMarkedForDeletion = false;

  Task(this.title, {this.isCompleted = false, this.order = 0});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      json['titulo'],
      isCompleted: json['concluida'] ?? false,
      order: json['ordem'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titulo': title,
      'concluida': isCompleted,
      'ordem': order,
    };
  }
}

class TaskScreen extends StatefulWidget {
  final String token;
  final String email;

  const TaskScreen({super.key, required this.token, required this.email});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> with TickerProviderStateMixin {
  late final AnimationController _slideController;
  final AuthService _authService = AuthService();
  List<Task> taskList = [];
  final textController = TextEditingController();
  bool _isLoading = true;
  Task? _taskMarkedForDeletion;
  bool _isUndoVisible = false;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey();

  @override
  void initState() {
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    super.initState();
    _loadTasks();
  }

  // Função de logout
  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage(title: 'Login')),
    );
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });
    taskList =
        await _authService.carregarTarefas(widget.token, widget.email, context);
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveTasks() async {
    await _authService.salvarTarefas(
        widget.token, widget.email, taskList, context);
  }

  Future<void> _updateTasks() async {
    await _authService.salvarTarefas(
        widget.token, widget.email, taskList, context);
  }

  Future<void> _deleteTasks() async {
    await _authService.deletarTarefas(widget.token, widget.email, context);
        for (int i = taskList.length - 1; i >= 0; i--) {
          _listKey.currentState?.removeItem(i, (context, animation) => Container());
        }
    await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        taskList.clear();
    });
  }

  void _addTask(String taskName) {
    setState(() {
      if (taskName.trim().isNotEmpty &&
          !taskList.any((task) => task.title == taskName.trim())) {
        taskList.insert(0, Task(taskName.trim(), order: taskList.length + 1));
        _listKey.currentState?.insertItem(0);
        textController.clear();
        _saveTasks();
      }
    });
  }

  void _toggleTaskCompletion(Task task, int index) {
    if (index >= 0 && index < taskList.length) {
      setState(() {
        task.isCompleted = !task.isCompleted;
        if (task.isCompleted) {
          // Start slide animation
          _slideController.forward(from: 0.0).then((_) {
            _slideController.reverse();
          });

          // Remove and reinsert at top of list
          _listKey.currentState?.removeItem(
            index,
            (context, animation) => _buildTaskItem(context, index, animation),
          );

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                taskList.removeAt(index);
                int lastUncompletedIndex =
                    taskList.lastIndexWhere((t) => !t.isCompleted);
                taskList.insert(lastUncompletedIndex + 1, task);
                _listKey.currentState?.insertItem(lastUncompletedIndex + 1);
                _updateTasks();
              });
            }
          });
        } else {
          // Remove and reinsert at the correct position
          _listKey.currentState?.removeItem(
            index,
            (context, animation) => _buildTaskItem(context, index, animation),
          );

          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                taskList.removeAt(index);
                taskList.insert(0, task);
                _listKey.currentState?.insertItem(0);
                _updateTasks();
              });
            }
          });
        }
      });
    }
  }

  void _markTaskForDeletion(Task task) {
    if (kDebugMode) {
      print("Tarefa marcada para exclusão: ${task.title}");
    }
    setState(() {
      _taskMarkedForDeletion = task;
      _isUndoVisible = true;
      task.isMarkedForDeletion = true;

      Future.delayed(const Duration(seconds: 3), () {
        // Só excluir a tarefa se o usuário não pressionou "Desfazer"
        if (_isUndoVisible && _taskMarkedForDeletion == task) {
          if (kDebugMode) {
            print("Tarefa excluída: ${task.title}");
          }
          final index = taskList.indexOf(task);
          if (index >= 0) {
            setState(() {
              taskList.remove(task);
              _listKey.currentState
                  ?.removeItem(index, (context, animation) => Container());
              _isUndoVisible =
                  false; // Reseta a visibilidade do botão "Desfazer"
              _updateTasks();
            });
          }
        }
      });
    });
  }

  void _undoDeletion() {
    setState(() {
      if (_taskMarkedForDeletion != null) {
        _taskMarkedForDeletion!.isMarkedForDeletion = false;
        _isUndoVisible = false;
        _taskMarkedForDeletion = null;
      }
    });
  }

  Widget _buildTaskItem(
    BuildContext context,
    int index,
    Animation<double> animation,
  ) {
    final task = taskList[index];

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: const Offset(0, 0),
      ).animate(animation),
      child: RotationTransition(
        turns: Tween<double>(
          begin: task.isCompleted ? -0.015 : 0.0,
          end: 0.0, // Adjust the tilt angle as needed
        ).animate(animation),
        child: Dismissible(
          key: Key(taskList[index].title), // Use the correct key
          onDismissed: (direction) => _markTaskForDeletion(taskList[index]),
          confirmDismiss: (direction) async {
            if (direction == DismissDirection.endToStart) {
              _markTaskForDeletion(taskList[index]);
              return false;
            }
            if (direction == DismissDirection.startToEnd) {
              _toggleTaskCompletion(taskList[index], index);
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
            color: taskList[index].isMarkedForDeletion
                ? Colors.red[100]
                : (index % 2 == 0 ? Colors.grey[200] : Colors.grey[300]),
            child: ListTile(
                title: Text(
                  taskList[index].title,
                  style: TextStyle(
                    decoration: taskList[index].isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                trailing: taskList[index].isMarkedForDeletion
                    ? ElevatedButton(
                        onPressed: _undoDeletion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Desfazer'),
                      )
                    : IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _markTaskForDeletion(taskList[index]),
                      ),
                leading: Checkbox(
                    value: taskList[index].isCompleted,
                    onChanged: (value) {
                      _toggleTaskCompletion(taskList[index], index);
                    })),
          ),
        ),
      ),
    );
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
        title: const Text('Lista de Tarefas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTasks,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // Chama a função de logout ao clicar
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: textController,
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
                  child: AnimatedList(
                    key: _listKey,
                    initialItemCount: taskList.length,
                    itemBuilder: (context, index, animation) {
                      return _buildTaskItem(context, index, animation);
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
