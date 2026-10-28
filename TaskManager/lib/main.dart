
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const TaskManagerApp());
}

// ==================== API SERVICE ====================

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        final message = data['message'];

        if (message != null) {
          return message.toString();
        }

        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.first['msg']?.toString() ??
              'Du lieu khong hop le';
        }
      }
    } catch (_) {
      // Phản hồi không phải JSON hợp lệ.
    }

    return 'Yeu cau that bai (${response.statusCode})';
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
    }

    throw Exception(_errorMessage(response));
  }

  static Future<void> register(
    String fullName,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(_errorMessage(response));
    }
  }

  static Future<List<Map<String, dynamic>>> getTasks(
    String token,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['tasks'] as List? ?? [];

    return items
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<Map<String, dynamic>> getTaskDetail(
    String token,
    String id,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response));
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    return Map<String, dynamic>.from(data['task'] as Map);
  }
}

// ==================== APPLICATION ====================

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  String? _token;
  Map<String, dynamic> _user = {};

  void _onLoginSuccess(
    String token,
    Map<String, dynamic> user,
  ) {
    setState(() {
      _token = token;
      _user = user;
    });
  }

  void _logout() {
    setState(() {
      _token = null;
      _user = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF287D5A),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: _token == null
          ? AuthScreen(onLoginSuccess: _onLoginSuccess)
          : TaskListScreen(
              token: _token!,
              user: _user,
              onLogout: _logout,
            ),
    );
  }
}

// ==================== LOGIN AND REGISTER ====================

class AuthScreen extends StatefulWidget {
  final void Function(String, Map<String, dynamic>) onLoginSuccess;

  const AuthScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegister = false;
  bool _isLoading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _readError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isRegister) {
        await ApiService.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );

        if (!mounted) return;

        setState(() {
          _isRegister = false;
          _passwordController.clear();
          _nameController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dang ky thanh cong. Hay dang nhap tai khoan.',
            ),
          ),
        );
      } else {
        final result = await ApiService.login(
          _emailController.text,
          _passwordController.text,
        );

        final token = result['token']?.toString();
        final user = Map<String, dynamic>.from(
          (result['user'] as Map?) ?? {},
        );

        if (token == null || token.isEmpty) {
          throw Exception('May chu khong tra ve token');
        }

        if (!mounted) return;

        widget.onLoginSuccess(token, user);
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_readError(error)),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Color(0xFF287D5A),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'TASK MANAGER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegister
                            ? 'Tao tai khoan moi'
                            : 'Dang nhap de xem cong viec',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      if (_isRegister) ...[
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ho va ten',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().length < 2) {
                              return 'Nhap ho ten it nhat 2 ky tu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';

                          if (!email.contains('@') ||
                              !email.contains('.')) {
                            return 'Vui long nhap email hop le';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: _hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Mat khau',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _hidePassword = !_hidePassword;
                              });
                            },
                            icon: Icon(
                              _hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final password = value ?? '';

                          if (_isRegister &&
                              (password.length < 8 ||
                                  password.length > 72)) {
                            return 'Mat khau phai tu 8 den 72 ky tu';
                          }

                          if (password.isEmpty) {
                            return 'Vui long nhap mat khau';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: 24),

                      FilledButton(
                        onPressed: _isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isRegister ? 'DANG KY' : 'DANG NHAP',
                              ),
                      ),
                      const SizedBox(height: 8),

                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                setState(() {
                                  _isRegister = !_isRegister;
                                });
                              },
                        child: Text(
                          _isRegister
                              ? 'Da co tai khoan? Dang nhap'
                              : 'Chua co tai khoan? Dang ky',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== TASK LIST ====================

class TaskListScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  final VoidCallback onLogout;

  const TaskListScreen({
    super.key,
    required this.token,
    required this.user,
    required this.onLogout,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tasks = await ApiService.getTasks(widget.token);

      if (!mounted) return;

      setState(() {
        _tasks = tasks;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['fullName']?.toString() ?? 'Nguoi dung';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cong viec cua toi'),
        actions: [
          IconButton(
            tooltip: 'Dang xuat',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
                title: Text('Xin chao, $name'),
                subtitle: Text(
                  widget.user['email']?.toString() ?? '',
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  FilledButton(
                                    onPressed: _loadTasks,
                                    child: const Text('Thu lai'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTasks,
                            child: _tasks.isEmpty
                                ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: const [
                                      SizedBox(height: 100),
                                      Icon(
                                        Icons.inbox_outlined,
                                        size: 64,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 12),
                                      Center(
                                        child: Text(
                                          'Chua co cong viec nao',
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Center(
                                        child: Text(
                                          'Keo xuong de tai lai',
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _tasks.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final task = _tasks[index];

                                      return Card(
                                        child: ListTile(
                                          leading: const CircleAvatar(
                                            child: Icon(Icons.task_alt),
                                          ),
                                          title: Text(
                                            task['title']?.toString() ??
                                                'Cong viec',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  task['description']
                                                          ?.toString() ??
                                                      '',
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 8),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 4,
                                                  children: [
                                                    Chip(
                                                      label: Text(
                                                        _statusLabel(
                                                          task['status']
                                                              ?.toString(),
                                                        ),
                                                      ),
                                                    ),
                                                    Chip(
                                                      label: Text(
                                                        'Uu tien: ${_priorityLabel(task['priority']?.toString())}',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Text(
                                                  'Han: ${_formatDate(task['dueDate'])}',
                                                ),
                                              ],
                                            ),
                                          ),
                                          isThreeLine: true,
                                          trailing: const Icon(
                                            Icons.chevron_right,
                                          ),
                                          onTap: () {
                                            final id =
                                                task['_id']?.toString() ?? '';

                                            if (id.isEmpty) return;

                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    TaskDetailScreen(
                                                  token: widget.token,
                                                  taskId: id,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== TASK DETAIL ====================

class TaskDetailScreen extends StatefulWidget {
  final String token;
  final String taskId;

  const TaskDetailScreen({
    super.key,
    required this.token,
    required this.taskId,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? _task;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final task = await ApiService.getTaskDetail(
        widget.token,
        widget.taskId,
      );

      if (!mounted) return;

      setState(() => _task = task);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiet cong viec'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _loadDetail,
                              child: const Text('Thu lai'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _buildDetail(_task!),
        ),
      ),
    );
  }

  Widget _buildDetail(Map<String, dynamic> task) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(
          Icons.task_alt,
          size: 64,
          color: Color(0xFF287D5A),
        ),
        const SizedBox(height: 16),
        Text(
          task['title']?.toString() ?? 'Cong viec',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        _detailRow(
          Icons.description_outlined,
          'Mo ta',
          task['description']?.toString().isNotEmpty == true
              ? task['description'].toString()
              : 'Khong co mo ta',
        ),
        _detailRow(
          Icons.flag_outlined,
          'Trang thai',
          _statusLabel(task['status']?.toString()),
        ),
        _detailRow(
          Icons.priority_high,
          'Muc do uu tien',
          _priorityLabel(task['priority']?.toString()),
        ),
        _detailRow(
          Icons.calendar_today_outlined,
          'Ngay bat dau',
          _formatDate(task['startDate']),
        ),
        _detailRow(
          Icons.event_outlined,
          'Han hoan thanh',
          _formatDate(task['dueDate']),
        ),
        _detailRow(
          Icons.person_outline,
          'Ma nguoi tao',
          task['createdBy']?.toString() ?? '',
        ),
        _detailRow(
          Icons.people_outline,
          'So nguoi duoc giao',
          ((task['assigneeIds'] as List?) ?? []).length.toString(),
        ),
      ],
    );
  }

  Widget _detailRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value),
        ),
      ),
    );
  }
}

// ==================== DISPLAY HELPERS ====================

String _statusLabel(String? status) {
  switch (status) {
    case 'todo':
      return 'Chua thuc hien';
    case 'in_progress':
      return 'Dang thuc hien';
    case 'completed':
      return 'Da hoan thanh';
    default:
      return status ?? 'Chua ro';
  }
}

String _priorityLabel(String? priority) {
  switch (priority) {
    case 'low':
      return 'Thap';
    case 'medium':
      return 'Trung binh';
    case 'high':
      return 'Cao';
    default:
      return priority ?? 'Chua ro';
  }
}

String _formatDate(dynamic value) {
  if (value == null || value.toString().isEmpty) {
    return 'Chua thiet lap';
  }

  final date = DateTime.tryParse(value.toString());

  if (date == null) return value.toString();

  final localDate = date.toLocal();

  return '${localDate.day.toString().padLeft(2, '0')}/'
      '${localDate.month.toString().padLeft(2, '0')}/'
      '${localDate.year}';
}
