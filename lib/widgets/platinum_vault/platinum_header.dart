import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_state.dart';

/// Widget for the Platinum Vault header which includes the title and PP balance
class PlatinumHeader extends StatelessWidget {
  const PlatinumHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Row(
      children: [
        // Custom vault icon with glow effect
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.8),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.shield_moon_outlined, color: Color(0xFFFFD700), size: 24),
        ),
        const SizedBox(width: 12),
        Text(
          'Platinum Vault',
          style: TextStyle(
            color: const Color(0xFFFFD700),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.7),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget for displaying Platinum Points balance in a styled container
class PlatinumBalance extends StatelessWidget {
  const PlatinumBalance({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final gameState = context.watch<GameState>();

    return Container(
      margin: const EdgeInsets.only(right: 16.0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4A1259).withOpacity(0.8),
            const Color(0xFF7B1FA2).withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 5,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Custom platinum coin
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFFD700), // Solid gold background
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.6),
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '✦',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            gameState.platinumPoints.toString(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );
  }
} 