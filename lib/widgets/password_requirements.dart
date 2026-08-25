import 'package:flutter/material.dart';

class PasswordRequirements extends StatelessWidget {
  const PasswordRequirements({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Req('At least 6 characters', password.length >= 6),
        const SizedBox(height: 3),
        _Req('Contains a letter', password.contains(RegExp(r'[a-zA-Z]'))),
        const SizedBox(height: 3),
        _Req('Contains a number', password.contains(RegExp(r'[0-9]'))),
      ],
    );
  }
}

class _Req extends StatelessWidget {
  const _Req(this.label, this.met);
  final String label;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: met ? const Color(0xFF059669) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: met ? const Color(0xFF059669) : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}
