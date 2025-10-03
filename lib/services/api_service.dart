class ApiService {
  ApiService._private();
  static final ApiService instance = ApiService._private();

  final String baseUrl = 'https://api.example.com'; // TODO: đổi URL

  Future<void> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    throw UnimplementedError('Implement login API');
  }

  Future<void> register(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    throw UnimplementedError('Implement register API');
  }

  Future<void> sendForgotPassword(String email) async {
    await Future.delayed(const Duration(milliseconds: 400));
    throw UnimplementedError('Implement forgot password API');
  }
}
