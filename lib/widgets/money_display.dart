import 'package:flutter/material.dart';
import '../utils/number_formatter.dart';

class MoneyDisplay extends StatelessWidget {
  final double money;
  final Color? fontColor;
  final double? fontSize;
  final bool showCents;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  final List<Shadow>? shadows;
  final bool isPlatinumStyle;
  
  const MoneyDisplay({
    Key? key,
    required this.money,
    this.fontColor,
    this.fontSize,
    this.showCents = true,
    this.fontWeight,
    this.textAlign,
    this.shadows,
    this.isPlatinumStyle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedMoney = NumberFormatter.formatCurrency(money);
    
    if (isPlatinumStyle) {
      // Create a premium platinum-styled money display
      return Stack(
        children: [
          // Create subtle blur effect for depth
          Text(
            formattedMoney,
            style: TextStyle(
              color: Colors.black.withOpacity(0.3),
              fontSize: fontSize ?? 20,
              fontWeight: fontWeight ?? FontWeight.bold,
              letterSpacing: 0.5,
            ),
            textAlign: textAlign,
          ),
          
          // Main text with custom gradient for premium effect
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  fontColor ?? const Color(0xFFFFFFFF),
                  const Color(0xFFE5E5FF),
                ],
              ).createShader(bounds);
            },
            child: Text(
              formattedMoney,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize ?? 20,
                fontWeight: fontWeight ?? FontWeight.bold,
                letterSpacing: 0.5,
                shadows: shadows,
              ),
              textAlign: textAlign,
            ),
          ),
        ],
      );
    } else {
      // Standard money display
      return Text(
        formattedMoney,
        style: TextStyle(
          color: fontColor ?? Colors.black,
          fontSize: fontSize ?? 20,
          fontWeight: fontWeight ?? FontWeight.bold,
          shadows: shadows,
        ),
        textAlign: textAlign,
      );
    }
  }
}