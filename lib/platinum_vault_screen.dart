  const SizedBox(width: 8),
  Text(
    '${gameState.platinumPoints.toString()} P',
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
  ),
  const SizedBox(height: 8),
  Text(
    "Keep earning Platinum!",
    style: TextStyle(
      fontSize: 14,
      color: Colors.grey.shade500,
    ),
  ),
  child: GridView.builder(
    padding: const EdgeInsets.all(16.0),
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 200.0,
      childAspectRatio: 2 / 4.2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
    ),
  ), 