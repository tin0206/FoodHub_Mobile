import 'package:foodhub_mobile/models/user.dart';

class SessionService {
  SessionService._();

  static final SessionService instance = SessionService._();

  UserModel? currentUser;

  bool get isLoggedIn => currentUser != null;

  void setUser(UserModel user) {
    currentUser = user;
  }

  void clear() {
    currentUser = null;
  }
}
