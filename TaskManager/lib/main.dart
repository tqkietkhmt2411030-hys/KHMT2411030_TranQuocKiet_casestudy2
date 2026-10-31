import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

// Tuong thich voi widget_test.dart duoc tao boi Flutter.
// MyApp giu cung ung dung TaskManagerApp, khong thay doi luong dang nhap/CRUD.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const TaskManagerApp();
  }
}

// ================= API SERVICE =================

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  static String getError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        if (data['message'] != null) {
          return data['message'].toString();
        }
        if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
          return data['errors'][0]['msg'].toString();
        }
      }
    } catch (_) {}
    return 'Yeu cau that bai: ${response.statusCode}';
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim(), 'password': password}),
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
    return Map<String, dynamic>.from(jsonDecode(response.body));
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
      throw Exception(getError(response));
    }
  }

  static Future<List<Map<String, dynamic>>> getTasks(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
    final data = jsonDecode(response.body);
    final items = data['tasks'] as List? ?? [];
    return items.map((item) => Map<String, dynamic>.from(item)).toList();
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
      throw Exception(getError(response));
    }
    final data = Map<String, dynamic>.from(jsonDecode(response.body));
    final task = Map<String, dynamic>.from(data['task']);
    task['_permission'] = data['permission'] ?? 'assignee';
    return task;
  }

  static Future<void> createTask(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 201) {
      throw Exception(getError(response));
    }
  }

  static Future<void> updateTask(
    String token,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
  }

  static Future<void> deleteTask(String token, String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
  }

  // ================= USER SEARCH =================

  static Future<List<Map<String, dynamic>>> searchUsers(
    String token,
    String query,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/search?q=${Uri.encodeQueryComponent(query)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
    final data = jsonDecode(response.body);
    final users = data['users'] as List? ?? [];
    return users.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  // ================= ASSIGNEES =================

  static Future<Map<String, dynamic>> getAssignees(
    String token,
    String taskId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$taskId/assignees'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  static Future<void> assignUsers(
    String token,
    String taskId,
    List<String> userIds, {
    String? primaryAssigneeId,
  }) async {
    final body = <String, dynamic>{
      'userIds': userIds,
      if (primaryAssigneeId != null) 'primaryAssigneeId': primaryAssigneeId,
    };
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/assignees'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
  }

  static Future<void> updatePrimaryAssignee(
    String token,
    String taskId,
    String userId,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId/assignees/$userId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'isPrimary': true}),
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
  }

  static Future<void> removeAssignee(
    String token,
    String taskId,
    String userId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId/assignees/$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
  }

  // ================= TASK SHARING =================

  static Future<Map<String, dynamic>> getShares(
    String token,
    String taskId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$taskId/shares'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  static Future<void> addShare(
    String token,
    String taskId,
    String userId,
    String permission,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/shares'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userIds': [userId],
        'permission': permission,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
  }

  static Future<void> updateShare(
    String token,
    String taskId,
    String shareId,
    String permission,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$taskId/shares/$shareId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'permission': permission}),
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
  }

  static Future<void> removeShare(
    String token,
    String taskId,
    String shareId,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId/shares/$shareId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception(getError(response));
    }
  }
}

// ================= APPLICATION =================

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  String? token;
  Map<String, dynamic> user = {};

  void onLoginSuccess(String newToken, Map<String, dynamic> newUser) {
    setState(() {
      token = newToken;
      user = newUser;
    });
  }

  void logout() {
    setState(() {
      token = null;
      user = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF287D5A)),
        scaffoldBackgroundColor: const Color(0xFFF5F7F6),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: token == null
          ? AuthScreen(onLoginSuccess: onLoginSuccess)
          : TaskListScreen(token: token!, user: user, onLogout: logout),
    );
  }
}

// ================= LOGIN / REGISTER =================

class AuthScreen extends StatefulWidget {
  final void Function(String, Map<String, dynamic>) onLoginSuccess;

  const AuthScreen({super.key, required this.onLoginSuccess});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isRegister = false;
  bool isLoading = false;
  bool hidePassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      if (isRegister) {
        await ApiService.register(
          nameController.text,
          emailController.text,
          passwordController.text,
        );
        if (!mounted) return;
        setState(() {
          isRegister = false;
          nameController.clear();
          passwordController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dang ky thanh cong. Hay dang nhap.')),
        );
      } else {
        final result = await ApiService.login(
          emailController.text,
          passwordController.text,
        );
        final newToken = result['token']?.toString();
        if (newToken == null || newToken.isEmpty) {
          throw Exception('Khong nhan duoc JWT');
        }
        final newUser = Map<String, dynamic>.from(result['user'] as Map);
        if (!mounted) return;
        widget.onLoginSuccess(newToken, newUser);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
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
                  key: formKey,
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
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isRegister
                            ? 'Tao tai khoan moi'
                            : 'Dang nhap de xem cong viec',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      if (isRegister) ...[
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Ho va ten',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().length < 2) {
                              return 'Nhap ho ten it nhat 2 ky tu';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!email.contains('@') || !email.contains('.')) {
                            return 'Email khong hop le';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        obscureText: hidePassword,
                        decoration: InputDecoration(
                          labelText: 'Mat khau',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() => hidePassword = !hidePassword);
                            },
                            icon: Icon(
                              hidePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                        validator: (value) {
                          final password = value ?? '';
                          if (password.isEmpty) {
                            return 'Vui long nhap mat khau';
                          }
                          if (isRegister &&
                              (password.length < 8 || password.length > 72)) {
                            return 'Mat khau phai tu 8 den 72 ky tu';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => submit(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: isLoading ? null : submit,
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isRegister ? 'DANG KY' : 'DANG NHAP'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => setState(() => isRegister = !isRegister),
                        child: Text(
                          isRegister
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

// ================= TASK LIST =================

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
  List<Map<String, dynamic>> tasks = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final result = await ApiService.getTasks(widget.token);
      if (!mounted) return;
      setState(() => tasks = result);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> openCreateTask() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TaskFormScreen(token: widget.token)),
    );
    if (result == true) await loadTasks();
  }

  Future<void> openTaskDetail(String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskDetailScreen(
          token: widget.token,
          taskId: id,
          onChanged: loadTasks,
        ),
      ),
    );
    if (mounted) await loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.user['fullName']?.toString() ?? 'Nguoi dung';
    final email = widget.user['email']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cong viec cua toi'),
        actions: [
          IconButton(
            tooltip: 'Tai lai',
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Dang xuat',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateTask,
        icon: const Icon(Icons.add),
        label: const Text('Them cong viec'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('Xin chao, $name'),
                subtitle: Text(email),
              ),
              const Divider(height: 1),
              Expanded(child: buildTaskBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildTaskBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: loadTasks, child: const Text('Thu lai')),
            ],
          ),
        ),
      );
    }
    if (tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 100),
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Center(child: Text('Chua co cong viec nao')),
            SizedBox(height: 8),
            Center(child: Text('Nhan Them cong viec de bat dau')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: loadTasks,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final task = tasks[index];
          final assigneeCount = (task['assigneeIds'] as List?)?.length ?? 0;
          return Card(
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.task_alt)),
              title: Text(
                task['title']?.toString() ?? 'Cong viec',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['description']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(statusLabel(task['status']?.toString())),
                        ),
                        Chip(
                          label: Text(
                            'Uu tien: ${priorityLabel(task['priority']?.toString())}',
                          ),
                        ),
                        if (assigneeCount > 0)
                          Chip(
                            avatar: const Icon(Icons.people, size: 16),
                            label: Text('$assigneeCount nguoi duoc giao'),
                          ),
                      ],
                    ),
                    Text('Han: ${formatDate(task['dueDate'])}'),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                final id = task['_id']?.toString() ?? '';
                if (id.isNotEmpty) openTaskDetail(id);
              },
            ),
          );
        },
      ),
    );
  }
}

// ================= CREATE / EDIT TASK =================

class TaskFormScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic>? task;

  const TaskFormScreen({super.key, required this.token, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController titleController;
  late final TextEditingController descriptionController;
  late String priority;
  late String status;
  DateTime? startDate;
  DateTime? dueDate;
  bool isSaving = false;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    titleController = TextEditingController(
      text: task?['title']?.toString() ?? '',
    );
    descriptionController = TextEditingController(
      text: task?['description']?.toString() ?? '',
    );
    priority = task?['priority']?.toString() ?? 'medium';
    status = task?['status']?.toString() ?? 'todo';
    startDate = parseDate(task?['startDate']);
    dueDate = parseDate(task?['dueDate']);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> chooseDate(bool isStart) async {
    final initialDate = isStart ? startDate : dueDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null) return;
    setState(() {
      if (isStart) {
        startDate = selected;
      } else {
        dueDate = selected;
      }
    });
  }

  Future<void> saveTask() async {
    if (!formKey.currentState!.validate()) return;
    if (startDate != null && dueDate != null && dueDate!.isBefore(startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Han hoan thanh khong duoc truoc ngay bat dau'),
        ),
      );
      return;
    }
    setState(() => isSaving = true);
    final body = <String, dynamic>{
      'title': titleController.text.trim(),
      'description': descriptionController.text.trim(),
      'startDate': startDate?.toUtc().toIso8601String(),
      'dueDate': dueDate?.toUtc().toIso8601String(),
      'priority': priority,
      'status': status,
    };
    try {
      if (isEditing) {
        await ApiService.updateTask(
          widget.token,
          widget.task!['_id'].toString(),
          body,
        );
      } else {
        await ApiService.createTask(widget.token, body);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Cap nhat cong viec thanh cong'
                : 'Tao cong viec thanh cong',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chinh sua cong viec' : 'Them cong viec'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Form(
            key: formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: titleController,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Ten cong viec',
                    prefixIcon: Icon(Icons.task_alt),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui long nhap ten cong viec';
                    }
                    if (value.trim().length > 200) {
                      return 'Ten cong viec toi da 200 ky tu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Mo ta cong viec',
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ngay bat dau',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                    startDate == null
                        ? 'Chua chon ngay bat dau'
                        : formatDate(startDate!.toIso8601String()),
                  ),
                  trailing: IconButton(
                    onPressed: () => chooseDate(true),
                    icon: const Icon(Icons.edit_calendar),
                  ),
                  onTap: () => chooseDate(true),
                ),
                const Divider(),
                const Text(
                  'Han hoan thanh',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(
                    dueDate == null
                        ? 'Chua chon han hoan thanh'
                        : formatDate(dueDate!.toIso8601String()),
                  ),
                  trailing: IconButton(
                    onPressed: () => chooseDate(false),
                    icon: const Icon(Icons.edit_calendar),
                  ),
                  onTap: () => chooseDate(false),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Muc do uu tien',
                    prefixIcon: Icon(Icons.flag_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Thap')),
                    DropdownMenuItem(
                      value: 'medium',
                      child: Text('Trung binh'),
                    ),
                    DropdownMenuItem(value: 'high', child: Text('Cao')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => priority = value);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Trang thai',
                    prefixIcon: Icon(Icons.sync),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'todo',
                      child: Text('Chua thuc hien'),
                    ),
                    DropdownMenuItem(
                      value: 'in_progress',
                      child: Text('Dang thuc hien'),
                    ),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Da hoan thanh'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => status = value);
                  },
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: isSaving ? null : saveTask,
                  icon: const Icon(Icons.save),
                  label: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Luu thay doi' : 'Tao cong viec'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= TASK DETAIL =================

class TaskDetailScreen extends StatefulWidget {
  final String token;
  final String taskId;
  final Future<void> Function() onChanged;

  const TaskDetailScreen({
    super.key,
    required this.token,
    required this.taskId,
    required this.onChanged,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? task;
  List<Map<String, dynamic>> assignees = [];
  List<Map<String, dynamic>> shares = [];
  String? primaryAssigneeId;
  bool isLoading = true;
  String? error;

  String get permission => task?['_permission']?.toString() ?? 'assignee';
  bool get isOwner => permission == 'owner';
  bool get canEdit => isOwner || permission == 'editor';

  @override
  void initState() {
    super.initState();
    loadDetail();
  }

  Future<void> loadDetail() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final detail = await ApiService.getTaskDetail(
        widget.token,
        widget.taskId,
      );
      final assignmentData = await ApiService.getAssignees(
        widget.token,
        widget.taskId,
      );
      final shareData = await ApiService.getShares(widget.token, widget.taskId);
      if (!mounted) return;
      setState(() {
        task = detail;
        assignees = ((assignmentData['assignees'] as List?) ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        final primary = assignmentData['primaryAssignee'];
        primaryAssigneeId = primary is Map
            ? primary['_id']?.toString()
            : primary?.toString();
        shares = ((shareData['shares'] as List?) ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> editTask() async {
    if (task == null || !canEdit) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(token: widget.token, task: task),
      ),
    );
    if (result == true) {
      await loadDetail();
      await widget.onChanged();
    }
  }

  Future<void> deleteTask() async {
    if (!isOwner) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xac nhan xoa'),
        content: const Text('Ban co chac chan muon xoa cong viec nay khong?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xoa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.deleteTask(widget.token, widget.taskId);
      if (!mounted) return;
      await widget.onChanged();
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showMessage(e.toString().replaceFirst('Exception: ', ''), isError: true);
    }
  }

  Future<void> openAssignmentManagement() async {
    if (!isOwner) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignmentManagementScreen(
          token: widget.token,
          taskId: widget.taskId,
        ),
      ),
    );
    await loadDetail();
  }

  Future<void> openShareManagement() async {
    if (!isOwner) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ShareManagementScreen(token: widget.token, taskId: widget.taskId),
      ),
    );
    await loadDetail();
  }

  void showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiet cong viec'),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'Chinh sua',
              onPressed: editTask,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (isOwner)
            IconButton(
              tooltip: 'Xoa cong viec',
              onPressed: deleteTask,
              icon: const Icon(Icons.delete_outline),
            ),
          IconButton(
            tooltip: 'Tai lai',
            onPressed: loadDetail,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 850),
          child: buildBody(),
        ),
      ),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: loadDetail, child: const Text('Thu lai')),
            ],
          ),
        ),
      );
    }
    if (task == null) {
      return const Center(child: Text('Khong tim thay cong viec'));
    }

    final data = task!;
    return RefreshIndicator(
      onRefresh: loadDetail,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.task_alt, size: 64, color: Color(0xFF287D5A)),
          const SizedBox(height: 16),
          Text(
            data['title']?.toString() ?? 'Cong viec',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Center(child: permissionChip(permission)),
          const SizedBox(height: 24),
          detailRow(
            Icons.description_outlined,
            'Mo ta',
            data['description']?.toString().isNotEmpty == true
                ? data['description'].toString()
                : 'Khong co mo ta',
          ),
          detailRow(
            Icons.flag_outlined,
            'Trang thai',
            statusLabel(data['status']?.toString()),
          ),
          detailRow(
            Icons.priority_high,
            'Muc do uu tien',
            priorityLabel(data['priority']?.toString()),
          ),
          detailRow(
            Icons.calendar_today_outlined,
            'Ngay bat dau',
            formatDate(data['startDate']),
          ),
          detailRow(
            Icons.event_outlined,
            'Han hoan thanh',
            formatDate(data['dueDate']),
          ),
          detailRow(
            Icons.person_outline,
            'Ma nguoi tao',
            data['createdBy']?.toString() ?? '',
          ),
          const SizedBox(height: 20),
          _buildAssigneeSection(),
          const SizedBox(height: 16),
          _buildShareSection(),
          if (canEdit) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: editTask,
              icon: const Icon(Icons.edit),
              label: const Text('Chinh sua cong viec'),
            ),
          ],
          if (isOwner) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: deleteTask,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Xoa cong viec'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssigneeSection() {
    final primary = assignees.where((user) {
      return user['_id']?.toString() == primaryAssigneeId;
    }).toList();
    final primaryName = primary.isNotEmpty
        ? primary.first['fullName']?.toString() ?? ''
        : 'Chua chon';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people_outline),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Nguoi duoc giao',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (isOwner)
                  IconButton(
                    tooltip: 'Quan ly nguoi duoc giao',
                    onPressed: openAssignmentManagement,
                    icon: const Icon(Icons.manage_accounts_outlined),
                  ),
              ],
            ),
            if (assignees.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Chua co nguoi duoc giao'),
              )
            else ...[
              ...assignees.map((user) {
                final id = user['_id']?.toString();
                final name = user['fullName']?.toString() ?? 'Nguoi dung';
                final email = user['email']?.toString() ?? '';
                final isPrimary = id != null && id == primaryAssigneeId;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: isPrimary
                      ? const Chip(
                          avatar: Icon(Icons.star, size: 16),
                          label: Text('Phu trach chinh'),
                        )
                      : null,
                );
              }),
              const Divider(),
              Text('Nguoi phu trach chinh: $primaryName'),
            ],
            if (isOwner) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: openAssignmentManagement,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Quan ly nguoi duoc giao'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShareSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.share_outlined),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chia se va phan quyen',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                if (isOwner)
                  IconButton(
                    tooltip: 'Quan ly chia se',
                    onPressed: openShareManagement,
                    icon: const Icon(Icons.settings_outlined),
                  ),
              ],
            ),
            if (shares.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Chua chia se cong viec nay'),
              )
            else
              ...shares.map((share) {
                final user = share['userId'] is Map
                    ? Map<String, dynamic>.from(share['userId'])
                    : <String, dynamic>{};
                final name = user['fullName']?.toString() ?? 'Nguoi dung';
                final email = user['email']?.toString() ?? '';
                final role = share['permission']?.toString() ?? 'viewer';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(child: Icon(Icons.share)),
                  title: Text(name),
                  subtitle: Text(email),
                  trailing: permissionChip(role),
                );
              }),
            if (isOwner) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: openShareManagement,
                icon: const Icon(Icons.share),
                label: const Text('Quan ly chia se'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget detailRow(IconData icon, String title, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(value),
        ),
      ),
    );
  }
}

// ================= ASSIGNMENT MANAGEMENT =================

class AssignmentManagementScreen extends StatefulWidget {
  final String token;
  final String taskId;

  const AssignmentManagementScreen({
    super.key,
    required this.token,
    required this.taskId,
  });

  @override
  State<AssignmentManagementScreen> createState() =>
      _AssignmentManagementScreenState();
}

class _AssignmentManagementScreenState
    extends State<AssignmentManagementScreen> {
  List<Map<String, dynamic>> assignees = [];
  String? primaryId;
  bool isLoading = true;
  bool isSaving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    loadAssignees();
  }

  Future<void> loadAssignees() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await ApiService.getAssignees(widget.token, widget.taskId);
      if (!mounted) return;
      final primary = data['primaryAssignee'];
      setState(() {
        assignees = ((data['assignees'] as List?) ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        primaryId = primary is Map
            ? primary['_id']?.toString()
            : primary?.toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> addAssignees() async {
    final selected = await showDialog<List<Map<String, dynamic>>>(
      context: context,
      builder: (_) => UserMultiSelectDialog(token: widget.token),
    );
    if (selected == null || selected.isEmpty) return;

    final ids = selected.map((user) => user['_id'].toString()).toList();
    setState(() => isSaving = true);
    try {
      await ApiService.assignUsers(widget.token, widget.taskId, ids);
      await loadAssignees();
      if (!mounted) return;
      _showMessage('Giao cong viec thanh cong');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> setPrimary(String userId) async {
    setState(() => isSaving = true);
    try {
      await ApiService.updatePrimaryAssignee(
        widget.token,
        widget.taskId,
        userId,
      );
      await loadAssignees();
      if (!mounted) return;
      _showMessage('Da cap nhat nguoi phu trach chinh');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> removeUser(Map<String, dynamic> user) async {
    final id = user['_id']?.toString();
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xac nhan huy giao viec'),
        content: Text(
          'Ban muon huy giao viec cho ${user['fullName'] ?? 'nguoi dung'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xac nhan'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => isSaving = true);
    try {
      await ApiService.removeAssignee(widget.token, widget.taskId, id);
      await loadAssignees();
      if (!mounted) return;
      _showMessage('Da huy giao viec');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quan ly nguoi duoc giao')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isSaving ? null : addAssignees,
        icon: const Icon(Icons.person_add),
        label: const Text('Them nguoi'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : RefreshIndicator(
              onRefresh: loadAssignees,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                children: [
                  const Text(
                    'Danh sach thanh vien',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (assignees.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Chua co nguoi duoc giao'),
                      ),
                    ),
                  ...assignees.map((user) {
                    final id = user['_id'].toString();
                    final isPrimary = id == primaryId;
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(
                          user['fullName']?.toString() ?? 'Nguoi dung',
                        ),
                        subtitle: Text(user['email']?.toString() ?? ''),
                        trailing: PopupMenuButton<String>(
                          enabled: !isSaving,
                          onSelected: (value) {
                            if (value == 'primary') setPrimary(id);
                            if (value == 'remove') removeUser(user);
                          },
                          itemBuilder: (_) => [
                            if (!isPrimary)
                              const PopupMenuItem(
                                value: 'primary',
                                child: Text('Chon lam phu trach chinh'),
                              ),
                            const PopupMenuItem(
                              value: 'remove',
                              child: Text('Huy giao viec'),
                            ),
                          ],
                        ),
                        isThreeLine: false,
                      ),
                    );
                  }),
                  if (primaryId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Nguoi phu trach chinh: ${assignees.firstWhere((user) => user['_id'].toString() == primaryId, orElse: () => <String, dynamic>{'fullName': 'Khong xac dinh'})['fullName']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ================= USER MULTI SELECT DIALOG =================

class UserMultiSelectDialog extends StatefulWidget {
  final String token;

  const UserMultiSelectDialog({super.key, required this.token});

  @override
  State<UserMultiSelectDialog> createState() => _UserMultiSelectDialogState();
}

class _UserMultiSelectDialogState extends State<UserMultiSelectDialog> {
  final queryController = TextEditingController();
  List<Map<String, dynamic>> results = [];
  final Map<String, Map<String, dynamic>> selected = {};
  bool isSearching = false;
  String? error;

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final query = queryController.text.trim();
    if (query.length < 2) {
      setState(() => error = 'Nhap it nhat 2 ky tu de tim kiem');
      return;
    }
    setState(() {
      isSearching = true;
      error = null;
    });
    try {
      final users = await ApiService.searchUsers(widget.token, query);
      if (!mounted) return;
      setState(() => results = users);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tim nguoi de giao viec'),
      content: SizedBox(
        width: 460,
        height: 420,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: queryController,
                    decoration: const InputDecoration(
                      labelText: 'Nhap email hoac ho ten',
                    ),
                    onSubmitted: (_) => search(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: isSearching ? null : search,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            if (isSearching)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: results.map((user) {
                  final id = user['_id'].toString();
                  final isSelected = selected.containsKey(id);
                  return CheckboxListTile(
                    value: isSelected,
                    title: Text(user['fullName']?.toString() ?? ''),
                    subtitle: Text(user['email']?.toString() ?? ''),
                    onChanged: (checked) {
                      setState(() {
                        if (checked == true) {
                          selected[id] = user;
                        } else {
                          selected.remove(id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            if (results.isEmpty && !isSearching && error == null)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text('Nhap tu khoa va bam tim kiem'),
              ),
            if (selected.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Da chon ${selected.length} nguoi'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huy'),
        ),
        FilledButton(
          onPressed: selected.isEmpty
              ? null
              : () => Navigator.pop(context, selected.values.toList()),
          child: const Text('Them nguoi duoc chon'),
        ),
      ],
    );
  }
}

// ================= SHARE MANAGEMENT =================

class ShareManagementScreen extends StatefulWidget {
  final String token;
  final String taskId;

  const ShareManagementScreen({
    super.key,
    required this.token,
    required this.taskId,
  });

  @override
  State<ShareManagementScreen> createState() => _ShareManagementScreenState();
}

class _ShareManagementScreenState extends State<ShareManagementScreen> {
  List<Map<String, dynamic>> shares = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadShares();
  }

  Future<void> loadShares() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final data = await ApiService.getShares(widget.token, widget.taskId);
      if (!mounted) return;
      setState(() {
        shares = ((data['shares'] as List?) ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> addNewShare() async {
    final result = await showDialog<ShareSelection>(
      context: context,
      builder: (_) => ShareUserDialog(token: widget.token),
    );
    if (result == null) return;
    try {
      await ApiService.addShare(
        widget.token,
        widget.taskId,
        result.user['_id'].toString(),
        result.permission,
      );
      await loadShares();
      if (!mounted) return;
      _showMessage('Chia se cong viec thanh cong');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> changePermission(
    Map<String, dynamic> share,
    String permission,
  ) async {
    try {
      await ApiService.updateShare(
        widget.token,
        widget.taskId,
        share['_id'].toString(),
        permission,
      );
      await loadShares();
      if (!mounted) return;
      _showMessage('Da cap nhat quyen chia se');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  Future<void> revokeShare(Map<String, dynamic> share) async {
    final user = share['userId'] is Map
        ? Map<String, dynamic>.from(share['userId'])
        : <String, dynamic>{};
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Thu hoi quyen chia se'),
        content: Text(
          'Ban co chac muon thu hoi quyen cua ${user['fullName'] ?? 'nguoi dung'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Thu hoi'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.removeShare(
        widget.token,
        widget.taskId,
        share['_id'].toString(),
      );
      await loadShares();
      if (!mounted) return;
      _showMessage('Da thu hoi quyen chia se');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString().replaceFirst('Exception: ', ''), error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quan ly chia se')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addNewShare,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Chia se'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!))
          : RefreshIndicator(
              onRefresh: loadShares,
              child: shares.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        Icon(
                          Icons.share_outlined,
                          size: 56,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Center(child: Text('Chua chia se cong viec')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: shares.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final share = shares[index];
                        final user = share['userId'] is Map
                            ? Map<String, dynamic>.from(share['userId'])
                            : <String, dynamic>{};
                        final permission =
                            share['permission']?.toString() ?? 'viewer';
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.person),
                                  ),
                                  title: Text(
                                    user['fullName']?.toString() ??
                                        'Nguoi dung',
                                  ),
                                  subtitle: Text(
                                    user['email']?.toString() ?? '',
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Text('Quyen truy cap:'),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: DropdownButtonFormField<String>(
                                        value: permission,
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                        ),
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'viewer',
                                            child: Text('Viewer - Chi xem'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'editor',
                                            child: Text('Editor - Duoc sua'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          if (value != null &&
                                              value != permission) {
                                            changePermission(share, value);
                                          }
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Thu hoi quyen',
                                      onPressed: () => revokeShare(share),
                                      icon: const Icon(
                                        Icons.person_remove_outlined,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}

class ShareSelection {
  final Map<String, dynamic> user;
  final String permission;

  ShareSelection({required this.user, required this.permission});
}

class ShareUserDialog extends StatefulWidget {
  final String token;

  const ShareUserDialog({super.key, required this.token});

  @override
  State<ShareUserDialog> createState() => _ShareUserDialogState();
}

class _ShareUserDialogState extends State<ShareUserDialog> {
  final queryController = TextEditingController();
  List<Map<String, dynamic>> results = [];
  Map<String, dynamic>? selectedUser;
  String permission = 'viewer';
  bool isSearching = false;
  String? error;

  @override
  void dispose() {
    queryController.dispose();
    super.dispose();
  }

  Future<void> search() async {
    final query = queryController.text.trim();
    if (query.length < 2) {
      setState(() => error = 'Nhap it nhat 2 ky tu de tim kiem');
      return;
    }
    setState(() {
      isSearching = true;
      error = null;
      selectedUser = null;
    });
    try {
      final users = await ApiService.searchUsers(widget.token, query);
      if (!mounted) return;
      setState(() => results = users);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chia se cong viec'),
      content: SizedBox(
        width: 460,
        height: 420,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: queryController,
                    decoration: const InputDecoration(
                      labelText: 'Tim bang email hoac ho ten',
                    ),
                    onSubmitted: (_) => search(),
                  ),
                ),
                IconButton(
                  onPressed: isSearching ? null : search,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            if (isSearching)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: results.map((user) {
                  final id = user['_id'].toString();
                  return RadioListTile<String>(
                    value: id,
                    groupValue: selectedUser?['_id']?.toString(),
                    title: Text(user['fullName']?.toString() ?? ''),
                    subtitle: Text(user['email']?.toString() ?? ''),
                    onChanged: (_) => setState(() => selectedUser = user),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: permission,
              decoration: const InputDecoration(labelText: 'Quyen chia se'),
              items: const [
                DropdownMenuItem(
                  value: 'viewer',
                  child: Text('Viewer - Chi xem'),
                ),
                DropdownMenuItem(
                  value: 'editor',
                  child: Text('Editor - Duoc sua'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => permission = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Huy'),
        ),
        FilledButton(
          onPressed: selectedUser == null
              ? null
              : () => Navigator.pop(
                  context,
                  ShareSelection(user: selectedUser!, permission: permission),
                ),
          child: const Text('Xac nhan chia se'),
        ),
      ],
    );
  }
}

// ================= HELPER FUNCTIONS =================

DateTime? parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}

String formatDate(dynamic value) {
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

String statusLabel(String? status) {
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

String priorityLabel(String? priority) {
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

Widget permissionChip(String permission) {
  switch (permission) {
    case 'owner':
      return const Chip(
        avatar: Icon(Icons.verified_user, size: 16),
        label: Text('Chu so huu'),
      );
    case 'editor':
      return const Chip(
        avatar: Icon(Icons.edit, size: 16),
        label: Text('Editor'),
      );
    case 'viewer':
      return const Chip(
        avatar: Icon(Icons.visibility, size: 16),
        label: Text('Viewer'),
      );
    default:
      return const Chip(
        avatar: Icon(Icons.assignment_ind, size: 16),
        label: Text('Nguoi duoc giao'),
      );
  }
}
