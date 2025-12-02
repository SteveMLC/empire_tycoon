import 'package:flutter/material.dart';
import '../data/platinum_vault_items.dart';

// Import the refactored components
import '../widgets/platinum_vault/platinum_header.dart';
import '../widgets/platinum_vault/category_tabs.dart';
import '../widgets/platinum_vault/category_content.dart';

class PlatinumVaultScreen extends StatefulWidget {
  const PlatinumVaultScreen({Key? key}) : super(key: key);

  @override
  _PlatinumVaultScreenState createState() => _PlatinumVaultScreenState();
}

class _PlatinumVaultScreenState extends State<PlatinumVaultScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<VaultItem> _vaultItems;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: VaultItemCategory.values.length, vsync: this);
    _vaultItems = getVaultItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117), // Deep charcoal base
      appBar: AppBar(
        title: const PlatinumHeader(),
        backgroundColor: const Color(0xFF161B22), // Sophisticated dark
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // White back arrow
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1C2128),
                const Color(0xFF161B22),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
        ),
        actions: const [
          PlatinumBalance(),
        ],
        bottom: CategoryTabs(tabController: _tabController),
      ),
      body: Container(
        decoration: BoxDecoration(
          // Elegant dark gradient with subtle gold shimmer
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF161B22), // Dark header blend
              const Color(0xFF0D1117), // Deep charcoal
              const Color(0xFF0A0E12), // Near black
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Subtle gold accent glow at top
            Positioned(
              top: -100,
              left: 0,
              right: 0,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Main content
            TabBarView(
              controller: _tabController,
              children: VaultItemCategory.values.map((category) {
                return CategoryContent(
                  category: category,
                  items: _vaultItems,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
} 