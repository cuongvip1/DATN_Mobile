import 'dart:async';

class ApiService {
  ApiService._private();
  static final ApiService instance = ApiService._private();

  final Map<String, String> _mockUsers = {
    'cuong01062004@gmail.com': '123456',
    'owner@example.com': 'owner123',
  };

  final Map<String, String> _roles = {
    'cuong01062004@gmail.com': 'tenant',
    'owner@example.com': 'owner',
  };

  // rooms: có thêm prev_elec, prev_water, fixed_rent
  final List<Map<String, dynamic>> _rooms = [
    {
      'id': 'A1',
      'name': 'Phòng A1',
      'tenant': 'cuong01062004@gmail.com',
      'prev_elec': 120, // số tháng trước
      'prev_water': 15,
      'fixed_rent': 2500000
    },
    {
      'id': 'A2',
      'name': 'Phòng A2',
      'tenant': null,
      'prev_elec': 0,
      'prev_water': 0,
      'fixed_rent': 2000000
    },
    {
      'id': 'B1',
      'name': 'Phòng B1',
      'tenant': null,
      'prev_elec': 0,
      'prev_water': 0,
      'fixed_rent': 2000000
    },
  ];

  String? _currentEmail;

  Future<String> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final stored = _mockUsers[email];
    if (stored == null) throw Exception('User not found');
    if (stored != password) throw Exception('Invalid credentials');
    _currentEmail = email;
    return 'mock_token_${email.hashCode}';
  }

  Future<void> register(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_mockUsers.containsKey(email)) throw Exception('Email already exists');
    _mockUsers[email] = password;
    _roles[email] = 'tenant';
  }

  Future<void> sendForgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_mockUsers.containsKey(email)) throw Exception('User not found');
  }

  String getCurrentEmail() => _currentEmail ?? '';

  Future<String> getCurrentUserRole() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final email = _currentEmail;
    if (email == null) return 'tenant';
    return _roles[email] ?? 'tenant';
  }

  Future<List<Map<String, dynamic>>> getRoomsForOwner() async {
    await Future.delayed(const Duration(milliseconds: 200));
    // return shallow copy
    return _rooms.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<Map<String, dynamic>?> getRoomForCurrentTenant() async {
    await Future.delayed(const Duration(milliseconds: 150));
    final email = _currentEmail;
    if (email == null) return null;
    final room = _rooms.firstWhere(
      (r) => r['tenant'] == email,
      orElse: () => {},
    );
    return room.isEmpty ? null : Map<String, dynamic>.from(room);
  }

  Future<Map<String, dynamic>?> getRoomById(String id) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final room = _rooms.firstWhere((r) => r['id'] == id, orElse: () => {});
    return room.isEmpty ? null : Map<String, dynamic>.from(room);
  }

  Future<void> setFixedRent(String roomId, int rent) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final idx = _rooms.indexWhere((r) => r['id'] == roomId);
    if (idx == -1) throw Exception('Room not found');
    _rooms[idx]['fixed_rent'] = rent;
  }

  // Submit current readings: lưu current -> cập nhật prev_* cho tháng sau
  Future<void> submitCurrentReadings(String roomId, int currElec, int currWater) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final idx = _rooms.indexWhere((r) => r['id'] == roomId);
    if (idx == -1) throw Exception('Room not found');
    _rooms[idx]['prev_elec'] = currElec;
    _rooms[idx]['prev_water'] = currWater;
  }

  Future<void> payBill(String roomId, int amount) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final room = _rooms.indexWhere((r) => r['id'] == roomId);
    if (room == -1) throw Exception('Phòng không tồn tại');
  }

  void seedUser(String email, String password, {String role = 'tenant'}) {
    _mockUsers[email] = password;
    _roles[email] = role;
  }

  bool userExists(String email) => _mockUsers.containsKey(email);
}
