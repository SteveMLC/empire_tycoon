import 'package:flutter/material.dart';
import '../models/real_estate.dart';

class PropertyGalleryDialog extends StatelessWidget {
  final List<Map<String, dynamic>> ownedProperties;

  const PropertyGalleryDialog({
    Key? key,
    required this.ownedProperties,
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
              child: ownedProperties.isEmpty
                  ? _buildEmptyState()
                  : _buildGalleryGrid(context),
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

  Widget _buildGalleryGrid(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: ownedProperties.length,
      itemBuilder: (context, index) {
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
    );
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