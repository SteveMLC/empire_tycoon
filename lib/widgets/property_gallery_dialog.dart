import 'package:flutter/material.dart';
import '../models/real_estate.dart';
import '../widgets/platinum_spire_trophy.dart';

class PropertyGalleryDialog extends StatelessWidget {
  final List<Map<String, dynamic>> ownedProperties;
  final bool showSpireTrophy;
  final String? spireTrophyLocaleId;

  const PropertyGalleryDialog({
    Key? key,
    required this.ownedProperties,
    this.showSpireTrophy = false,
    this.spireTrophyLocaleId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Dialog header with close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.home_work, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Property Portfolio',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close gallery',
                  ),
                ],
              ),
            ),
            // Gallery content
            Expanded(
              child: ownedProperties.isEmpty && !showSpireTrophy
                  ? _buildEmptyState()
                  : _buildGalleryContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No properties in your portfolio yet!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Purchase properties to see them here',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryContent(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // If the spire trophy should be shown, add it to the top
        if (showSpireTrophy)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSpireTrophyCard(context),
            ),
          ),
        
        // Display the owned properties
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final propertyData = ownedProperties[index];
                final localeId = propertyData['localeId'] as String;
                final propertyId = propertyData['propertyId'] as String;
                final propertyName = propertyData['propertyName'] as String;
                final localeName = propertyData['localeName'] as String;
                final owned = propertyData['owned'] as int;

                return _buildPropertyCard(
                  context,
                  localeId: localeId,
                  propertyId: propertyId,
                  propertyName: propertyName,
                  localeName: localeName,
                  owned: owned,
                );
              },
              childCount: ownedProperties.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpireTrophyCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: const Color(0xFFFFD700).withOpacity(0.5), // Gold border
          width: 2.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Platinum Spire Trophy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF454545),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey.shade100,
              ),
              child: Center(
                child: PlatinumSpireTrophy(
                  size: 170,
                  showEmergenceAnimation: true,
                  username: "TYCOON",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("The Platinum Spire Trophy gleams with prestige!"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              spireTrophyLocaleId != null ? _getLocaleNameById(spireTrophyLocaleId!) : "Your Empire",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getLocaleNameById(String localeId) {
    for (var prop in ownedProperties) {
      if (prop['localeId'] == localeId) {
        return prop['localeName'] as String;
      }
    }
    
    return localeId.split('_').map((word) => word.substring(0, 1).toUpperCase() + word.substring(1)).join(' ');
  }

  Widget _buildPropertyCard(
    BuildContext context, {
    required String localeId,
    required String propertyId,
    required String propertyName,
    required String localeName,
    required int owned,
  }) {
    final imagePath = 'assets/images/$localeId/$propertyId.jpg';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Property image
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon if image fails to load
                  return Container(
                    color: Colors.grey.shade200,
                    child: Center(
                      child: Icon(
                        Icons.home_work,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // Property info
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  propertyName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  localeName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Removed 'Owned: #' indicator as requested
              ],
            ),
          ),
        ],
      ),
    );
  }
}