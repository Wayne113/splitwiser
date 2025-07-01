import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'activity_service.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> groups = [];
  List<Map<String, dynamic>> recentDashboardItems = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadGroups();
    await _loadRecentDashboardItems();
  }

  // Refresh data
  Future<void> refreshData() async {
    await _loadData();
  }

  Future<void> _loadGroups() async {
    try {
      // SharedPreferences
      // Load Groups
      final prefs = await SharedPreferences.getInstance();
      final savedGroups = prefs.getStringList('groups') ?? [];
      final newGroups = savedGroups
          .map((groupStr) => json.decode(groupStr) as Map<String, dynamic>)
          .toList();

      setState(() {
        groups = newGroups;
      });
    } catch (e) {
      setState(() {
        groups = [];
      });
    }
  }

  Future<void> _loadRecentDashboardItems() async {
    try {
      // Load activities from ActivityService
      final activities = await ActivityService.getActivities();

      setState(() {
        recentDashboardItems = activities;
      });
    } catch (e) {
      setState(() {
        recentDashboardItems = [];
      });
    }
  }

  Map<String, double> _calculateCategoryTotals() {
    Map<String, double> categoryTotals = {};

    for (var group in groups) {
      final expenses = group['expenses'] as List<dynamic>? ?? [];
      for (var expense in expenses) {
        // Get category from icon codePoint
        final category = _getCategoryFromIcon(expense['avatar'] as int?);
        final amount = expense['amount'] as double? ?? 0.0;
        final currency = expense['currency'] as String? ?? 'MYR';

        // always MYR to show totals
        final convertedAmount = _convertToMYR(amount, currency);

        categoryTotals[category] =
            (categoryTotals[category] ?? 0.0) + convertedAmount;
      }
    }

    return categoryTotals;
  }

  String _getCategoryFromIcon(int? iconCodePoint) {
    if (iconCodePoint == null) return 'Other';

    // Map icon codePoints to categories based on Create Expense Form icons
    switch (iconCodePoint) {
      case 0xe25a:
        return 'Food';
      case 0xe1d7:
        return 'Transport';
      case 0xe120:
        return 'Birthday';
      case 0xe59c:
        return 'Shopping';
      case 0xe318:
        return 'Home';
      case 0xe5e4:
        return 'Drinking';
      case 0xe297:
        return 'Travel';
      case 0xe40d:
        return 'Movie';
      default:
        return 'Other';
    }
  }

  double _convertToMYR(double amount, String fromCurrency) {
    // Hardcoded rate, in case live conversion fails
    final rates = {
      'MYR': 1.0,
      'USD': 4.7,
      'EUR': 5.0,
      'CNY': 0.65,
      'SGD': 3.5,
      'THB': 0.13,
      'JPY': 0.032,
      'KRW': 0.0035,
      'AUD': 3.1,
      'NZD': 2.8,
      'CAD': 3.4,
      'PHP': 0.082,
      'IDR': 0.00031,
      'VND': 0.00019,
    };

    return amount * (rates[fromCurrency] ?? 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final categoryTotals = _calculateCategoryTotals();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),

            // dynamic height for chart bubbles
            _buildChartSection(categoryTotals),

            const SizedBox(height: 16),

            Container(height: 400, child: _buildRecentActivitySection()),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection(Map<String, double> categoryTotals) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chart',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                    ],
                  ),
                ),
                // Total Expense (chart bubbles) top-right corner
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF7F55FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF7F55FF).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Expense',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7F55FF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'RM ${categoryTotals.values.fold(0.0, (sum, amount) => sum + amount).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7F55FF),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            if (categoryTotals.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No expenses yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            else
              _buildCategoryBubbles(categoryTotals),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBubbles(Map<String, double> categoryTotals) {
    final categories = categoryTotals.entries.toList();
    categories.sort(
      (a, b) => b.value.compareTo(a.value),
    ); // Sort by amount descending

    // Calculate max amount for sizing
    final maxAmount = categories.isNotEmpty ? categories.first.value : 0.0;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: categories.map((entry) {
        return _buildCategoryBubble(entry.key, entry.value, maxAmount);
      }).toList(),
    );
  }

  Widget _buildCategoryBubble(
    String category,
    double amount,
    double maxAmount,
  ) {
    final categoryData = _getCategoryData(category);

    // Calculate bubble size based on amount
    final minSize = 80.0;
    final maxSize = 140.0;
    final sizeRatio = maxAmount > 0 ? amount / maxAmount : 0.0;
    final bubbleSize = minSize + (maxSize - minSize) * sizeRatio;

    // Calculate icon and font sizes based on bubble size
    final iconSize = (bubbleSize * 0.25).clamp(20.0, 40.0);
    final amountFontSize = (bubbleSize * 0.12).clamp(12.0, 18.0);
    final categoryFontSize = (bubbleSize * 0.08).clamp(10.0, 14.0);

    return Container(
      width: bubbleSize,
      height: bubbleSize,
      decoration: BoxDecoration(
        color: categoryData['color'],
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: categoryData['color'].withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(categoryData['icon'], size: iconSize, color: Colors.white),
          SizedBox(height: bubbleSize * 0.05),
          Text(
            'RM ${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: amountFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            category,
            style: TextStyle(
              fontSize: categoryFontSize,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getCategoryData(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return {'icon': Icons.fastfood, 'color': Color(0xFF4CAF50)};
      case 'transport':
        return {'icon': Icons.directions_car, 'color': Color(0xFFF44336)};
      case 'birthday':
        return {'icon': Icons.cake, 'color': Color(0xFFE91E63)};
      case 'shopping':
        return {'icon': Icons.shopping_cart, 'color': Color(0xFFFF9800)};
      case 'home':
        return {'icon': Icons.home, 'color': Color(0xFF607D8B)};
      case 'drinking':
        return {'icon': Icons.sports_bar, 'color': Color(0xFF795548)};
      case 'travel':
        return {'icon': Icons.flight, 'color': Color(0xFF2196F3)};
      case 'movie':
        return {'icon': Icons.movie, 'color': Color(0xFF9C27B0)};
      default:
        return {'icon': Icons.category, 'color': Color(0xFF9E9E9E)};
    }
  }

  Widget _buildRecentActivitySection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20),

          if (recentDashboardItems.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 64, color: Colors.grey[400]),
                    SizedBox(height: 16),
                    Text(
                      'No recent activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Create expenses to see activity here',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: recentDashboardItems.length > 10
                    ? 10
                    : recentDashboardItems.length,
                itemBuilder: (context, index) {
                  return _buildDashboardItem(recentDashboardItems[index]);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardItem(Map<String, dynamic> dashboardItem) {
    final type = dashboardItem['type'] as String? ?? '';
    final timestamp = dashboardItem['timestamp'] as String? ?? '';
    final description = dashboardItem['description'] as String? ?? '';

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'expense_added':
        icon = Icons.add_circle;
        iconColor = Colors.green;
        break;
      case 'group_created':
        icon = Icons.group_add;
        iconColor = Colors.blue;
        break;
      case 'expense_updated':
        icon = Icons.edit;
        iconColor = Colors.orange;
        break;
      case 'group_updated':
        icon = Icons.edit;
        iconColor = Colors.orange;
        break;
      case 'settlement':
        icon = Icons.check_circle;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.info;
        iconColor = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return timestamp;
    }
  }
}
