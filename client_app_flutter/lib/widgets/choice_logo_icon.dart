import 'package:flutter/material.dart';

class ChoiceLogoIcon extends StatelessWidget {
  final double size;

  const ChoiceLogoIcon({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/choice-logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.flutter_dash,
          color: Colors.lightBlue[300],
          size: size,
        );
      },
    );
  }
}
