import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ActivityService {
  static const String _activitiesKey = 'recent_activities';
  static const int _maxActivities = 50;

  /// Add activity to recent activities
  static Future<void> addActivity({
    required String type,
    required String description,
    String? groupName,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedActivities = prefs.getStringList(_activitiesKey) ?? [];

      // Create new activity
      final activity = {
        'type': type,
        'description': description,
        'timestamp': DateTime.now().toIso8601String(),
        'groupName': groupName,
        'metadata': metadata ?? {},
      };

      final activities = savedActivities
          .map(
            (activityStr) => json.decode(activityStr) as Map<String, dynamic>,
          )
          .toList();

      // Most recent first
      activities.insert(0, activity);

      // Keep only the latest activities
      if (activities.length > _maxActivities) {
        activities.removeRange(_maxActivities, activities.length);
      }

      final updatedActivities = activities
          .map((activity) => json.encode(activity))
          .toList();

      await prefs.setStringList(_activitiesKey, updatedActivities);
    } catch (e) {
      // Silently fail - activity logging is not critical
    }
  }

  /// for expense creation
  static Future<void> addExpenseCreated({
    required String expenseName,
    required double amount,
    required String groupName,
    required String currency,
  }) async {
    await addActivity(
      type: 'expense_added',
      description:
          'Added "$expenseName" (${_getCurrencySymbol(currency)} ${amount.toStringAsFixed(2)}) to $groupName',
      groupName: groupName,
      metadata: {
        'expenseName': expenseName,
        'amount': amount,
        'currency': currency,
      },
    );
  }

  /// for expense update
  static Future<void> addExpenseUpdated({
    required String expenseName,
    required String groupName,
  }) async {
    await addActivity(
      type: 'expense_updated',
      description: 'Updated "$expenseName" in $groupName',
      groupName: groupName,
      metadata: {'expenseName': expenseName},
    );
  }

  /// for group creation
  static Future<void> addGroupCreated({required String groupName}) async {
    await addActivity(
      type: 'group_created',
      description: 'Created group "$groupName"',
      groupName: groupName,
    );
  }

  /// for group update
  static Future<void> addGroupUpdated({required String groupName}) async {
    await addActivity(
      type: 'group_updated',
      description: 'Updated group "$groupName"',
      groupName: groupName,
    );
  }

  /// for settlement
  static Future<void> addSettlement({required String groupName}) async {
    await addActivity(
      type: 'settlement',
      description: 'Settled up group "$groupName"',
      groupName: groupName,
    );
  }

  /// for undo settlement
  static Future<void> addUndoSettlement({required String groupName}) async {
    await addActivity(
      type: 'settlement',
      description: 'Undid settlement for group "$groupName"',
      groupName: groupName,
    );
  }

  /// Get all recent activities
  static Future<List<Map<String, dynamic>>> getActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedActivities = prefs.getStringList(_activitiesKey) ?? [];

      return savedActivities
          .map(
            (activityStr) => json.decode(activityStr) as Map<String, dynamic>,
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all activities
  static Future<void> clearActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_activitiesKey);
    } catch (e) {
      // Silently fail - activity clearing is not critical
    }
  }

  /// Get currency symbol
  static String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'MYR':
        return 'RM';
      case 'SGD':
        return 'S\$';
      case 'THB':
        return '฿';
      case 'IDR':
        return 'Rp';
      case 'PHP':
        return '₱';
      case 'VND':
        return '₫';
      case 'CNY':
        return '¥';
      case 'KRW':
        return '₩';
      case 'JPY':
        return '¥';
      case 'USD':
        return '\$';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'NZD':
        return 'NZ\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'HKD':
        return 'HK\$';
      case 'TWD':
        return 'NT\$';
      default:
        return currencyCode;
    }
  }
}
