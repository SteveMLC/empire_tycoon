import 'package:flutter/material.dart';
import '../utils/number_formatter.dart';

class MoneyDisplay extends StatelessWidget {
  final double money;
  final Color? fontColor;
  final double? fontSize;
  final bool showCents;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;
  
  const MoneyDisplay({
    Key? key,
    required this.money,
    this.fontColor,
    this.fontSize,
    this.showCents = true,
    this.fontWeight,
    this.textAlign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      NumberFormatter.formatCurrency(money),
      style: TextStyle(
        color: fontColor ?? Colors.black,
        fontSize: fontSize ?? 20,
        fontWeight: fontWeight ?? FontWeight.bold,
      ),
      textAlign: textAlign,
    );
  }
}