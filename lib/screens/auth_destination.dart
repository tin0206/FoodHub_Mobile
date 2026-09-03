import 'package:flutter/material.dart';
import 'package:foodhub_mobile/models/user.dart';
import 'package:foodhub_mobile/screens/admin/admin_shell_screen.dart';
import 'package:foodhub_mobile/screens/main_shell_screen.dart';
import 'package:foodhub_mobile/screens/onboarding_screen.dart';

Widget destinationFor(UserModel user, {bool isNewSignup = false}) {
  if (user.role == 'admin') return AdminShellScreen(user: user);
  if (isNewSignup) return OnboardingScreen(user: user);
  return MainShellScreen(initialUser: user);
}
