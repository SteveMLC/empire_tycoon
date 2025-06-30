# 🚀 Quick Ad Troubleshooting Guide

## **For Immediate Ad Issues**

### **Step 1: Check Current Status**
```dart
adMobService.printDebugStatus();
```
This shows you:
- Which ads are ready vs not ready
- Current game state tracking values
- Recent errors and success rates

### **Step 2: Identify the Issue**

| Symptom | Likely Cause | Quick Fix |
|---------|--------------|-----------|
| **"Ad not ready - emergency loading"** | Predictive loading condition not met | Check game state values in debug output |
| **Success rate < 90%** | Loading conditions too restrictive | Review and expand loading logic |
| **All ads failing** | Network issue or AdMob rate limiting | Check network connection and AdMob console |
| **Specific ad type failing** | Missing game state update | Verify `updateGameState()` calls for that condition |

### **Step 3: Quick Diagnostics**

**For Offline Income Ads:**
```dart
// Check if offline income is being tracked
print('Has offline income: ${gameState.showOfflineIncomeNotification}');
print('Background return: $_isReturningFromBackground');
```

**For BuildSkip Ads:**
```dart
// Check context-aware conditions
print('Business count: $_userBusinessCount');
print('First business level: $_firstBusinessLevel');  
print('Current screen: $_currentScreen');
```

**For EventClear Ads:**
```dart
// Check event detection
print('Has active events: $_hasActiveEvents');
```

### **Step 4: Force Load for Testing**
```dart
// Emergency load specific ad type for testing
_loadHustleBoostAd();
_loadBuildSkipAd();
_loadEventClearAd();
_loadOfflineincome2xAd();
```

## **For Adding New Ads**

### **5-Step Process:**
1. **Add variables**: `RewardedAd? _newAd`, `bool _isLoading`, `DateTime? _loadTime`
2. **Create load method**: `_loadNewAd()` with error handling
3. **Create show method**: `showNewAd()` with emergency fallback
4. **Add to predictive loading**: Update `_performPredictiveLoading()`
5. **Update game state**: Add tracking variables if needed

### **Template Code:**
```dart
// Variables
RewardedAd? _newAd;
bool _isNewAdLoading = false;
DateTime? _newAdLoadTime;

// Loading logic in _performPredictiveLoading()
if (shouldLoadNewAd && !_isAdValid(_newAd, _newAdLoadTime) && !_isNewAdLoading) {
  _loadNewAd();
}
```

## **For Monitoring Performance**

### **Key Metrics to Watch:**
- **Impression Loss Rate**: Target < 5%
- **Success Rate per Ad Type**: Target > 95%
- **Emergency Loading Frequency**: Should be rare
- **Ad Expiry Rate**: Monitor 50-minute window

### **Analytics Commands:**
```dart
// Revenue overview
Map<String, dynamic> analytics = adMobService.getRevenueAnalytics();
print('Loss Rate: ${analytics['impressionLossRate']}%');

// Per-ad breakdown
analytics['byAdType'].forEach((adType, data) {
  print('$adType: ${data['successRate']}%');
});
```

---

## **Need More Details?**

📖 **Full Documentation**: `docs/PREDICTIVE_AD_LOADING_IMPLEMENTATION.md`

This quick guide covers the most common scenarios. For comprehensive implementation details, troubleshooting, and best practices, see the full documentation above.

## **Emergency Contacts**

- **AdMob Console**: Check for rate limiting or policy issues
- **Test Devices**: Verify ads work on different devices
- **Network Issues**: Test with different connections

**Remember**: The predictive loading system is designed to eliminate 95% impression loss. If you're seeing high failure rates, the issue is likely in game state tracking or loading conditions, not the core ad serving mechanism. 