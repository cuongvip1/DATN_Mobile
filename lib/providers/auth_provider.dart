import 'package:flutter/foundation.dart';

class AuthProvider extends ChangeNotifier {
  bool _loading = false;
  bool get loading => _loading;

  void setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  // TODO: thêm method login/register sử dụng ApiService
}