import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.light,
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Models
class User {
  final String id;
  final String name;
  final String email;
  final String employeeId;
  final String department;
  final String position;
  final String phone;
  final String hireDate;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.employeeId,
    required this.department,
    required this.position,
    required this.phone,
    required this.hireDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      employeeId: json['employee_id'] ?? '',
      department: json['department'] ?? '',
      position: json['position'] ?? '',
      phone: json['phone'] ?? '',
      hireDate: json['hire_date'] ?? '',
    );
  }
}

class Task {
  final String id;
  final String title;
  final String description;
  final String dueDate;
  final String priority;
  final String status;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['due_date'] ?? '',
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
    );
  }
}

class Leave {
  final String id;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String reason;
  final String status;

  Leave({
    required this.id,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    required this.status,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['id'].toString(),
      leaveType: json['leave_type'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      reason: json['reason'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }
}

class Attendance {
  final String id;
  final String checkIn;
  final String checkOut;
  final String hoursWorked;
  final String date;

  Attendance({
    required this.id,
    required this.checkIn,
    required this.checkOut,
    required this.hoursWorked,
    required this.date,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'].toString(),
      checkIn: json['check_in'] ?? '',
      checkOut: json['check_out'] ?? '',
      hoursWorked: json['hours_worked']?.toString() ?? '0',
      date: json['date'] ?? '',
    );
  }
}

// Services
class ApiService {
  static const String baseUrl = 'https://yourdomain.com/wp-json/ems/v1/mobile';
  static String? _token;

  static Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    if (_token == null) {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
    }
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
      body: json.encode(data),
    );

    return _handleResponse(response);
  }

  static Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: await _getHeaders(),
    );

    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('API call failed: ${response.statusCode}');
    }
  }

  // Specific API methods
  static Future<dynamic> login(String username, String password) async {
    return await post('login', {
      'username': username,
      'password': password,
    });
  }

  static Future<dynamic> checkIn(Map<String, dynamic> data) async {
    return await post('attendance/checkin', data);
  }

  static Future<dynamic> checkOut(Map<String, dynamic> data) async {
    return await post('attendance/checkout', data);
  }

  static Future<dynamic> getTasks() async {
    return await get('tasks');
  }

  static Future<dynamic> updateTaskStatus(String taskId, String status) async {
    return await post('tasks/update', {
      'task_id': taskId,
      'status': status,
    });
  }

  static Future<dynamic> applyLeave(Map<String, dynamic> data) async {
    return await post('leaves/apply', data);
  }

  static Future<dynamic> getLeaveHistory() async {
    return await get('leaves/history');
  }

  static Future<dynamic> getSalaryInfo() async {
    return await get('salary');
  }

  static Future<dynamic> getProfile() async {
    return await get('profile');
  }
}

// Providers
class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoggedIn = false;

  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;

  Future<void> checkLoginStatus() async {
    final token = await ApiService.getToken();
    if (token != null) {
      try {
        final response = await ApiService.getProfile();
        if (response['success']) {
          _user = User.fromJson(response['profile']);
          _isLoggedIn = true;
          notifyListeners();
        }
      } catch (e) {
        await ApiService.clearToken();
      }
    }
  }

  Future<void> login(String username, String password) async {
    try {
      final response = await ApiService.login(username, password);
      if (response['success']) {
        await ApiService.setToken(response['token']);
        _user = User.fromJson(response['user']);
        _isLoggedIn = true;
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _user = null;
    _isLoggedIn = false;
    await ApiService.clearToken();
    notifyListeners();
  }
}

class EmployeeProvider with ChangeNotifier {
  List<Task> _tasks = [];
  List<Leave> _leaves = [];
  List<Attendance> _attendance = [];
  bool _isCheckedIn = false;

  List<Task> get tasks => _tasks;
  List<Leave> get leaves => _leaves;
  List<Attendance> get attendance => _attendance;
  bool get isCheckedIn => _isCheckedIn;

  Future<void> loadTasks() async {
    try {
      final response = await ApiService.getTasks();
      if (response['success']) {
        _tasks = (response['tasks'] as List)
            .map((task) => Task.fromJson(task))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }

  Future<void> loadLeaves() async {
    try {
      final response = await ApiService.getLeaveHistory();
      if (response['success']) {
        _leaves = (response['leaves'] as List)
            .map((leave) => Leave.fromJson(leave))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading leaves: $e');
    }
  }

  Future<void> checkIn(String location, String notes) async {
    try {
      final response = await ApiService.checkIn({
        'location': location,
        'notes': notes,
      });
      if (response['success']) {
        _isCheckedIn = true;
        notifyListeners();
      }
    } catch (e) {
      print('Error checking in: $e');
      rethrow;
    }
  }

  Future<void> checkOut() async {
    try {
      final response = await ApiService.checkOut({});
      if (response['success']) {
        _isCheckedIn = false;
        notifyListeners();
      }
    } catch (e) {
      print('Error checking out: $e');
      rethrow;
    }
  }

  Future<void> updateTask(String taskId, String status) async {
    try {
      final response = await ApiService.updateTaskStatus(taskId, status);
      if (response['success']) {
        await loadTasks();
      }
    } catch (e) {
      print('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> applyLeave(String leaveType, String startDate, String endDate, String reason) async {
    try {
      final response = await ApiService.applyLeave({
        'leave_type': leaveType,
        'start_date': startDate,
        'end_date': endDate,
        'reason': reason,
      });
      if (response['success']) {
        await loadLeaves();
      }
    } catch (e) {
      print('Error applying leave: $e');
      rethrow;
    }
  }
}

// Screens
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(Duration(seconds: 2));

    final authProvider = AuthProvider();
    await authProvider.checkLoginStatus();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => AuthWrapper(authProvider: authProvider)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Employee Management',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final AuthProvider authProvider;

  const AuthWrapper({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: authProvider,
      child: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          if (auth.isLoggedIn) {
            return MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => EmployeeProvider()),
              ],
              child: MainApp(),
            );
          } else {
            return LoginScreen();
          }
        },
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController(text: 'demo');
  final _passwordController = TextEditingController(text: 'demo');
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<AuthProvider>(context, listen: false).login(
        _usernameController.text,
        _passwordController.text,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_center, size: 80, color: Theme.of(context).primaryColor),
              SizedBox(height: 30),
              Text(
                'Employee Login',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  return null;
                },
              ),
              SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Login'),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Demo Credentials: demo / demo',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatefulWidget {
  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    AttendanceScreen(),
    TasksScreen(),
    LeavesScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    employeeProvider.loadTasks();
    employeeProvider.loadLeaves();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Management'),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications),
            onPressed: () {},
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Attendance'),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.beach_access), label: 'Leaves'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Welcome Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue,
                    child: Text(
                      authProvider.user?.name.substring(0, 1) ?? 'E',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${authProvider.user?.name ?? 'Employee'}!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          authProvider.user?.position ?? 'Position',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // Stats Cards
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            childAspectRatio: 1.3,
            children: [
              _buildStatCard('Pending Tasks', '${employeeProvider.tasks.where((t) => t.status == 'pending').length}', Icons.task, Colors.orange),
              _buildStatCard('Leaves', '${employeeProvider.leaves.length}', Icons.beach_access, Colors.green),
              _buildStatCard('Attendance', '95%', Icons.access_time, Colors.blue),
              _buildStatCard('Notifications', '3', Icons.notifications, Colors.red),
            ],
          ),
          SizedBox(height: 20),

          // Quick Actions
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(Icons.access_time, 'Check In', Colors.blue, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen()));
                      }),
                      _buildActionButton(Icons.task, 'Tasks', Colors.orange, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => TasksScreen()));
                      }),
                      _buildActionButton(Icons.beach_access, 'Apply Leave', Colors.green, () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => LeavesScreen()));
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: color),
            SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(title, style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onPressed) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: onPressed,
          ),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}

class AttendanceScreen extends StatefulWidget {
  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = false;

  Future<void> _checkIn() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<EmployeeProvider>(context, listen: false).checkIn(
        'Office Location',
        'Checked in via mobile app',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully checked in')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking in: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkOut() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<EmployeeProvider>(context, listen: false).checkOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully checked out')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking out: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Check In/Out Card
          Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(Icons.access_time, size: 60, color: Colors.blue),
                  SizedBox(height: 20),
                  Text(
                    employeeProvider.isCheckedIn ? 'Currently Checked In' : 'Not Checked In',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    DateTime.now().toString().split(' ')[0],
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : (employeeProvider.isCheckedIn ? _checkOut : _checkIn),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: employeeProvider.isCheckedIn ? Colors.red : Colors.green,
                      ),
                      child: _isLoading
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(employeeProvider.isCheckedIn ? 'Check Out' : 'Check In'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // Attendance History
          Expanded(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recent Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: 7,
                        itemBuilder: (context, index) {
                          final date = DateTime.now().subtract(Duration(days: index));
                          return ListTile(
                            leading: Icon(Icons.calendar_today, color: Colors.blue),
                            title: Text('Date: ${date.toString().split(' ')[0]}'),
                            subtitle: Text('Check In: 09:00 AM - Check Out: 06:00 PM'),
                            trailing: Chip(
                              label: Text('Present'),
                              backgroundColor: Colors.green[100],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TasksScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Task filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text('All (${employeeProvider.tasks.length})'),
                  selected: true,
                  onSelected: (_) {},
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text('Pending (${employeeProvider.tasks.where((t) => t.status == 'pending').length})'),
                  onSelected: (_) {},
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text('In Progress (${employeeProvider.tasks.where((t) => t.status == 'in_progress').length})'),
                  onSelected: (_) {},
                ),
                SizedBox(width: 8),
                FilterChip(
                  label: Text('Completed (${employeeProvider.tasks.where((t) => t.status == 'completed').length})'),
                  onSelected: (_) {},
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Tasks List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => employeeProvider.loadTasks(),
              child: ListView.builder(
                itemCount: employeeProvider.tasks.length,
                itemBuilder: (context, index) {
                  final task = employeeProvider.tasks[index];
                  return TaskCard(task: task);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({required this.task});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.orange;
      default: return Colors.red;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high': return Colors.red;
      case 'medium': return Colors.orange;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);

    return Card(
      margin: EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(
                    task.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(task.status),
                ),
              ],
            ),
            SizedBox(height: 8),
            if (task.description.isNotEmpty) ...[
              Text(
                task.description,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Due: ${task.dueDate}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(width: 16),
                Icon(Icons.flag, size: 16, color: _getPriorityColor(task.priority)),
                SizedBox(width: 4),
                Text(
                  'Priority: ${task.priority}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: task.status,
                    items: [
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                    ],
                    onChanged: (newStatus) {
                      if (newStatus != null) {
                        employeeProvider.updateTask(task.id, newStatus);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Update Status',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LeavesScreen extends StatefulWidget {
  @override
  _LeavesScreenState createState() => _LeavesScreenState();
}

class _LeavesScreenState extends State<LeavesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Leave Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Apply Leave'),
            Tab(text: 'Leave History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ApplyLeaveScreen(),
          LeaveHistoryScreen(),
        ],
      ),
    );
  }
}

class ApplyLeaveScreen extends StatefulWidget {
  @override
  _ApplyLeaveScreenState createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String _leaveType = 'sick';
  DateTime? _startDate;
  DateTime? _endDate;
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitLeave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select start and end dates')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Provider.of<EmployeeProvider>(context, listen: false).applyLeave(
        _leaveType,
        _startDate!.toString().split(' ')[0],
        _endDate!.toString().split(' ')[0],
        _reasonController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Leave application submitted successfully')),
      );

      _formKey.currentState!.reset();
      setState(() {
        _startDate = null;
        _endDate = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting leave: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            DropdownButtonFormField(
              value: _leaveType,
              items: [
                DropdownMenuItem(value: 'sick', child: Text('Sick Leave')),
                DropdownMenuItem(value: 'vacation', child: Text('Vacation Leave')),
                DropdownMenuItem(value: 'personal', child: Text('Personal Leave')),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _leaveType = value.toString()),
              decoration: InputDecoration(
                labelText: 'Leave Type',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text(_startDate == null ? 'Select Start Date' : 'Start Date: ${_startDate!.toString().split(' ')[0]}'),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) setState(() => _startDate = date);
              },
            ),
            ListTile(
              title: Text(_endDate == null ? 'Select End Date' : 'End Date: ${_endDate!.toString().split(' ')[0]}'),
              trailing: Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: _startDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) setState(() => _endDate = date);
              },
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Reason for Leave',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a reason for leave';
                }
                return null;
              },
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitLeave,
                child: _isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Submit Leave Application'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LeaveHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final employeeProvider = Provider.of<EmployeeProvider>(context);

    return RefreshIndicator(
      onRefresh: () => employeeProvider.loadLeaves(),
      child: ListView.builder(
        itemCount: employeeProvider.leaves.length,
        itemBuilder: (context, index) {
          final leave = employeeProvider.leaves[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(Icons.beach_access, color: _getLeaveColor(leave.leaveType)),
              title: Text('${_formatLeaveType(leave.leaveType)} Leave'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${leave.startDate} to ${leave.endDate}'),
                  SizedBox(height: 4),
                  Text(leave.reason, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
              trailing: Chip(
                label: Text(
                  leave.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, color: Colors.white),
                ),
                backgroundColor: _getStatusColor(leave.status),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getLeaveColor(String type) {
    switch (type) {
      case 'sick': return Colors.red;
      case 'vacation': return Colors.green;
      case 'personal': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _formatLeaveType(String type) {
    return type[0].toUpperCase() + type.substring(1);
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Padding(
      padding: EdgeInsets.all(16.0),
      child: ListView(
        children: [
          // Profile Header
          Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue,
                    child: Text(
                      authProvider.user?.name.substring(0, 1) ?? 'E',
                      style: TextStyle(fontSize: 30, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    authProvider.user?.name ?? 'Employee Name',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    authProvider.user?.position ?? 'Position',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    authProvider.user?.department ?? 'Department',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),

          // Personal Information
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Divider(height: 1),
                _buildInfoItem(Icons.email, 'Email', authProvider.user?.email ?? 'N/A'),
                _buildInfoItem(Icons.phone, 'Phone', authProvider.user?.phone ?? 'N/A'),
                _buildInfoItem(Icons.work, 'Employee ID', authProvider.user?.employeeId ?? 'N/A'),
                _buildInfoItem(Icons.calendar_today, 'Join Date', authProvider.user?.hireDate ?? 'N/A'),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Actions
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.settings, color: Colors.blue),
                  title: Text('Settings'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.help, color: Colors.green),
                  title: Text('Help & Support'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Logout'),
                        content: Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              authProvider.logout();
                            },
                            child: Text('Logout', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}