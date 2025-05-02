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
      appBar: AppBar(
        title: const PlatinumHeader(),
        backgroundColor: const Color(0xFF2D0C3E), // Rich purple background
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.5),
        actions: const [
          PlatinumBalance(),
        ],
        bottom: CategoryTabs(tabController: _tabController),
      ),
      body: Container(
        decoration: BoxDecoration(
          // Luxury rich purple gradient background
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2D0C3E), // Rich purple
              const Color(0xFF1A0523), // Darker purple
            ],
            stops: const [0.0, 1.0],
          ),
          // Add shimmer effect
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withOpacity(0.05),
              blurRadius: 15,
              spreadRadius: 10,
            ),
          ],
        ),
        child: TabBarView(
          controller: _tabController,
          children: VaultItemCategory.values.map((category) {
            return CategoryContent(
              category: category,
              items: _vaultItems,
            );
          }).toList(),
        ),
      ),
    );
  }
} 