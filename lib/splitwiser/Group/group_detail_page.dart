import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'settlement_page.dart';
import 'edit_group_page.dart';
import '../Add/create_expense_form.dart';
import 'dart:math' as math;
import 'currency_service.dart';
import '../Dashboard/activity_service.dart';

class GroupDetailPage extends StatefulWidget {
  final Map<String, dynamic> group;
  final VoidCallback? onDeleteGroup;
  const GroupDetailPage({Key? key, required this.group, this.onDeleteGroup})
    : super(key: key);

  @override
  _GroupDetailPageState createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late Map<String, dynamic> currentGroup;

  String displayCurrency = 'MYR';
  double exchangeRate = 1.0;
  bool isLoadingRate = false;
  final CurrencyService _currencyService = CurrencyService();

  DateTime? selectedMonthYear;

  Future<void> _reloadGroupData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGroups = prefs.getStringList('groups') ?? [];

    for (String groupStr in savedGroups) {
      final groupData = json.decode(groupStr) as Map<String, dynamic>;
      if (groupData['name'] == currentGroup['name']) {
        setState(() {
          currentGroup = groupData;
        });
        break;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    currentGroup = Map<String, dynamic>.from(widget.group);
    _loadSavedCurrency();
    _checkForProfileUpdates();
  }

  // Load saved currency preference
  Future<void> _loadSavedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('preferred_display_currency');

      if (savedCurrency != null) {
        await _changeCurrency(savedCurrency);
      }
    } catch (e) {
      print("Error loading saved currency: $e");
    }
  }

  Future<void> _saveCurrencyPreference(String currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_display_currency', currency);
      await prefs.setInt(
        'currency_change_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print("Error saving currency preference: $e");
    }
  }

  double _convertAmount(double amount) {
    return amount * exchangeRate;
  }

  // Check for profile updates and reload group data if needed
  Future<void> _checkForProfileUpdates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileChangeTimestamp =
          prefs.getInt('profile_change_timestamp') ?? 0;
      final lastChecked =
          prefs.getInt('last_profile_check_${currentGroup['name']}') ?? 0;

      if (profileChangeTimestamp > lastChecked) {
        await _reloadGroupData();

        await prefs.setInt(
          'last_profile_check_${currentGroup['name']}',
          DateTime.now().millisecondsSinceEpoch,
        );
      }
    } catch (e) {}
  }

  Future<void> _changeCurrency(String newCurrency) async {
    if (newCurrency == displayCurrency) return;

    setState(() {
      isLoadingRate = true;
    });

    try {
      final originalCurrency = _getOriginalCurrency();
      final rate = await _currencyService.getExchangeRate(
        originalCurrency,
        newCurrency,
      );

      setState(() {
        displayCurrency = newCurrency;
        exchangeRate = rate;
        isLoadingRate = false;
      });

      await _saveCurrencyPreference(newCurrency);
    } catch (e) {
      setState(() {
        isLoadingRate = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get exchange rate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCurrencySelector() {
    final currencies = [
      {'code': 'MYR', 'name': 'Malaysian Ringgit', 'country': 'Malaysia'},
      {'code': 'AUD', 'name': 'Australian Dollar', 'country': 'Australia'},
      {'code': 'CAD', 'name': 'Canadian Dollar', 'country': 'Canada'},
      {'code': 'CNY', 'name': 'Chinese Yuan', 'country': 'China'},
      {'code': 'EUR', 'name': 'Euro', 'country': 'European Union'},
      {'code': 'GBP', 'name': 'British Pound', 'country': 'United Kingdom'},
      {'code': 'HKD', 'name': 'Hong Kong Dollar', 'country': 'Hong Kong'},
      {'code': 'IDR', 'name': 'Indonesian Rupiah', 'country': 'Indonesia'},
      {'code': 'JPY', 'name': 'Japanese Yen', 'country': 'Japan'},
      {'code': 'KRW', 'name': 'South Korean Won', 'country': 'South Korea'},
      {'code': 'NZD', 'name': 'New Zealand Dollar', 'country': 'New Zealand'},
      {'code': 'PHP', 'name': 'Philippine Peso', 'country': 'Philippines'},
      {'code': 'SGD', 'name': 'Singapore Dollar', 'country': 'Singapore'},
      {'code': 'THB', 'name': 'Thai Baht', 'country': 'Thailand'},
      {'code': 'TWD', 'name': 'Taiwan Dollar', 'country': 'Taiwan'},
      {'code': 'USD', 'name': 'US Dollar', 'country': 'United States'},
      {'code': 'VND', 'name': 'Vietnamese Dong', 'country': 'Vietnam'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: Color(0xFF7F55FF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 28, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    itemCount: currencies.length,
                    itemBuilder: (context, index) {
                      final currency = currencies[index];
                      final isSelected = currency['code'] == displayCurrency;

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 2,
                        ),
                        leading: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              )
                            : null,
                        title: Text(
                          '${currency['code']} - ${currency['name']}',
                          style: TextStyle(
                            fontSize: 16,
                            color: isSelected ? Colors.green : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(
                          '${currency['country']} (${_currencyService.getCurrencySymbol(currency['code']!)})',
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected
                                ? Colors.green.shade600
                                : Colors.grey.shade600,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _changeCurrency(currency['code']!);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getUserName() {
    final members = currentGroup['members'] as List<dynamic>? ?? [];
    for (var member in members) {
      if (member['isCurrentUser'] == true) {
        return member['email'] as String;
      }
    }
    return 'You';
  }

  String _getOriginalCurrency() {
    final expenses = currentGroup['expenses'] as List<dynamic>? ?? [];
    if (expenses.isEmpty) return 'MYR';

    Map<String, int> currencyCount = {};
    for (var expense in expenses) {
      String currency = expense['currency'] ?? 'MYR';
      currencyCount[currency] = (currencyCount[currency] ?? 0) + 1;
    }

    // Return the most used currency
    String mostUsedCurrency = 'MYR';
    int maxCount = 0;
    currencyCount.forEach((currency, count) {
      if (count > maxCount) {
        maxCount = count;
        mostUsedCurrency = currency;
      }
    });

    return mostUsedCurrency;
  }

  String _getDisplayCurrency() {
    return _currencyService.getCurrencySymbol(displayCurrency);
  }

  String _getCurrentMonthYear() {
    // If user has selected a specific month, show that
    if (selectedMonthYear != null) {
      return _formatMonthYear(selectedMonthYear!);
    }

    final expenses = currentGroup['expenses'] as List<dynamic>? ?? [];

    if (expenses.isEmpty) {
      // If no expenses, show current month
      final now = DateTime.now();
      return _formatMonthYear(now);
    }

    // Get the most recent expense date
    DateTime? mostRecentDate;
    for (var expense in expenses) {
      if (expense['date'] != null) {
        try {
          final expenseDate = DateTime.parse(expense['date']);
          if (mostRecentDate == null || expenseDate.isAfter(mostRecentDate)) {
            mostRecentDate = expenseDate;
          }
        } catch (e) {
          // fail then continue to next expense
          continue;
        }
      }
    }

    // Return formatted month/year of most recent expense, or current if none found
    return _formatMonthYear(mostRecentDate ?? DateTime.now());
  }

  String _formatMonthYear(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  // Show month/year picker
  void _showMonthYearPicker() {
    // Get all unique months from expenses
    final expenses = currentGroup['expenses'] as List<dynamic>? ?? [];
    Set<DateTime> availableMonths = {};

    for (var expense in expenses) {
      if (expense['date'] != null) {
        try {
          final expenseDate = DateTime.parse(expense['date']);
          // Add first day of the month to set
          availableMonths.add(DateTime(expenseDate.year, expenseDate.month, 1));
        } catch (e) {
          continue;
        }
      }
    }

    // Convert to sorted list to latest first
    List<DateTime> monthsList = availableMonths.toList()
      ..sort((a, b) => b.compareTo(a));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: EdgeInsets.only(top: 8, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select Month',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              // Month list
              Expanded(
                child: monthsList.isEmpty
                    ? Center(
                        child: Text(
                          'No expenses found',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        itemCount:
                            monthsList.length + 1, // +1 for "All months" option
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            // "All months" option
                            final isSelected = selectedMonthYear == null;
                            return ListTile(
                              leading: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                      size: 20,
                                    )
                                  : null,
                              title: Text(
                                'All months',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.black87,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  selectedMonthYear = null; // Show all expenses
                                });
                                Navigator.pop(context);
                              },
                            );
                          }

                          final month = monthsList[index - 1];
                          final isSelected =
                              selectedMonthYear != null &&
                              selectedMonthYear!.year == month.year &&
                              selectedMonthYear!.month == month.month;

                          return ListTile(
                            leading: isSelected
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 20,
                                  )
                                : null,
                            title: Text(
                              _formatMonthYear(month),
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.blue
                                    : Colors.black87,
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                selectedMonthYear = month;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show undo settle confirmation dialog
  void _showUndoSettleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Undo Settlement'),
          content: Text(
            'Are you sure you want to undo the settlement? This will restore the original balances.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _undoGroupSettlement();

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Settlement undone successfully!'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
              child: Text('Confirm', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Undo group settlement
  Future<void> _undoGroupSettlement() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGroups = prefs.getStringList('groups') ?? [];

      // Find and update the current group
      final updatedGroups = savedGroups.map((groupStr) {
        final groupData = json.decode(groupStr) as Map<String, dynamic>;

        if (groupData['name'] == currentGroup['name']) {
          // Remove settled flags
          groupData.remove('isSettled');
          groupData.remove('settledDate');
        }

        return json.encode(groupData);
      }).toList();

      // Save updated groups
      await prefs.setStringList('groups', updatedGroups);

      // Add timestamp to help other pages detect settlement changes
      await prefs.setInt(
        'settlement_change_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

      // Update local state
      setState(() {
        currentGroup.remove('isSettled');
        currentGroup.remove('settledDate');
      });

      // Log undo settlement activity
      await ActivityService.addUndoSettlement(groupName: currentGroup['name']);
    } catch (e) {
      print("Error undoing group settlement: $e");
    }
  }

  // Shared method to calculate member balances (ALWAYS uses ALL expenses, not filtered)
  Map<String, double> _calculateMemberBalances() {
    // Always use ALL expenses for balance calculation, regardless of month filter
    final expenses = currentGroup['expenses'] as List<dynamic>? ?? [];
    final items = currentGroup['items'] as List<dynamic>? ?? [];
    final allExpenses = expenses.isNotEmpty ? expenses : items;

    final members = currentGroup['members'] as List<dynamic>? ?? [];
    final memberBalances = <String, double>{};

    // Initialize balances for all members
    for (var member in members) {
      memberBalances[member['email']] = 0.0;
    }

    // Calculate balances from ALL expenses (not filtered by month)
    for (var expense in allExpenses) {
      final paidBy = expense['paidBy'] as Map<String, dynamic>;
      final split = expense['split'] as List<dynamic>;

      // Add amounts paid
      if (paidBy['type'] == 'single') {
        final payer = paidBy['payer'] as String;
        final amount = paidBy['amount'] as double;
        memberBalances[payer] = (memberBalances[payer] ?? 0.0) + amount;
      } else if (paidBy['type'] == 'multiple') {
        final payers = paidBy['payers'] as Map<String, dynamic>;
        payers.forEach((email, amount) {
          memberBalances[email] =
              (memberBalances[email] ?? 0.0) + (amount as double);
        });
      }

      // Subtract amounts owed
      for (var splitItem in split) {
        final email = splitItem['email'] as String;
        // Use finalAmount (for custom amounts with tax/charge), otherwise use amount
        final amount =
            splitItem['finalAmount'] as double? ??
            splitItem['amount'] as double? ??
            0.0;
        memberBalances[email] = (memberBalances[email] ?? 0.0) - amount;
      }
    }

    return memberBalances;
  }

  // Calculate actual debt relationships from individual expenses
  List<Map<String, dynamic>> _calculateActualDebtRelationships() {
    final expenses = currentGroup['expenses'] as List<dynamic>? ?? [];
    final items = currentGroup['items'] as List<dynamic>? ?? [];
    final allExpenses = expenses.isNotEmpty ? expenses : items;
    final members = currentGroup['members'] as List<dynamic>? ?? [];

    final debtRelationships = <Map<String, dynamic>>[];

    // Find my email
    String currentUserEmail = 'You';
    for (var member in members) {
      if (member['isCurrentUser'] == true) {
        currentUserEmail = member['email'];
        break;
      }
    }

    // Process each expense to find debt relationships
    for (var expense in allExpenses) {
      final paidBy = expense['paidBy'] as Map<String, dynamic>;
      final split = expense['split'] as List<dynamic>;

      // Handle single payer
      if (paidBy['type'] == 'single') {
        final payerEmail = paidBy['payer'] as String;
        final payerName = _getMemberName(payerEmail);

        // Find who owes the payer
        for (var splitItem in split) {
          final ownerEmail = splitItem['email'] as String;
          final ownerName = _getMemberName(ownerEmail);
          final amount =
              splitItem['finalAmount'] as double? ??
              splitItem['amount'] as double? ??
              0.0;

          // Skip if the payer owes themselves
          if (ownerEmail == payerEmail) continue;

          // Grammar hehe
          String ownerDisplayName = ownerEmail == currentUserEmail
              ? 'You'
              : ownerName;
          String payerDisplayName = payerEmail == currentUserEmail
              ? 'You'
              : payerName;

          // "You owe" not "You owes"
          String debtText;
          if (ownerDisplayName == 'You') {
            debtText = 'You owe $payerDisplayName';
          } else {
            debtText = '$ownerDisplayName owes $payerDisplayName';
          }

          debtRelationships.add({
            'name': debtText,
            'text': '',
            'amount': amount,
          });
        }
      }
      // Handle multiple payers
      else if (paidBy['type'] == 'multiple') {
        final payers = paidBy['payers'] as Map<String, dynamic>;

        // For each person in the split, calculate their debt relationship
        for (var splitItem in split) {
          final memberEmail = splitItem['email'] as String;
          final memberName = _getMemberName(memberEmail);
          final amountOwed = splitItem['amount'] as double;
          final amountPaid = payers[memberEmail] as double? ?? 0.0;

          final netAmount = amountPaid - amountOwed;

          if (netAmount.abs() > 0.01) { // Avoid floating point precision issues
            // Use proper display name with fallback - ensure it's never null
            String displayName = (memberName != null && memberName.isNotEmpty) ? memberName : memberEmail;

            if (netAmount > 0) {
              // This person overpaid, others owe them
              String owedText = displayName == 'You' ? 'You are owed' : '$displayName is owed';
              debtRelationships.add({
                'name': owedText,
                'text': '',
                'amount': netAmount,
              });
            } else {
              // This person owes money
              String owesText = displayName == 'You' ? 'You owe' : '$displayName owes';
              debtRelationships.add({
                'name': owesText,
                'text': '',
                'amount': netAmount.abs(),
              });
            }
          }
        }
      }
    }

    return debtRelationships;
  }

  Map<String, dynamic> _recalculateGroupSettlement() {
    final members = currentGroup['members'] as List<dynamic>? ?? [];

    // Check if group is settled - if so, all balances should be 0
    if (currentGroup['isSettled'] == true) {
      return {
        'details': <Map<String, dynamic>>[],
        'status': {'text': 'Settled up', 'color': 0xFFE8F5E8, 'amount': 0.0},
      };
    }

    // Calculate actual debt relationships from individual expenses
    final details = _calculateActualDebtRelationships();
    final memberBalances = _calculateMemberBalances();

    // Find current user's email
    String currentUserEmail = 'You';
    for (var member in members) {
      if (member['isCurrentUser'] == true) {
        currentUserEmail = member['email'];
        break;
      }
    }

    double userBalance = memberBalances[currentUserEmail] ?? 0.0;

    return {
      'details': details,
      'status': {
        'text': userBalance == 0
            ? 'No balance'
            : (userBalance > 0 ? 'You are owed' : 'You owe'),
        'color': userBalance == 0
            ? 0xFFE8F5E8
            : (userBalance > 0 ? 0xFFE8F5E8 : 0xFFFFE0E0),
        'amount': userBalance.abs(),
      },
    };
  }

  // Filter expenses by selected month
  List<dynamic> _getFilteredExpenses() {
    final expenses = currentGroup['expenses'] as List<dynamic>? ?? [];
    final items = currentGroup['items'] as List<dynamic>? ?? [];
    final allItems = expenses.isNotEmpty ? expenses : items;

    // If no month is selected, return all items
    if (selectedMonthYear == null) {
      return allItems;
    }

    // Filter items by selected month/year
    return allItems.where((item) {
      if (item['date'] == null) return false;

      try {
        final itemDate = DateTime.parse(item['date']);
        return itemDate.year == selectedMonthYear!.year &&
            itemDate.month == selectedMonthYear!.month;
      } catch (e) {
        return false;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final allItems = _getFilteredExpenses();

    final userName = _getUserName();
    final screenWidth = MediaQuery.of(context).size.width;

    // Recalculate details and status based on current data
    final recalculatedData = _recalculateGroupSettlement();
    final details = recalculatedData['details'] as List<dynamic>;
    final status = recalculatedData['status'] as Map<String, dynamic>;

    Map<String, dynamic> _findUserInSplit(
      List<dynamic> split,
      String userName,
    ) {
      try {
        return split.firstWhere(
          (s) => s['name'] == userName,
          orElse: () => <String, dynamic>{},
        );
      } catch (e) {
        return <String, dynamic>{};
      }
    }

    Color _getItemBg(Map<String, dynamic> item, String userName) {
      final split = item['split'] as List<dynamic>? ?? [];
      final user = _findUserInSplit(split, userName);
      if (user.isEmpty) return Color(0xFFF3F3F3);
      if (item['paidBy'] == userName) return Color(0xFFE0F2E9);
      return Color(0xFFFFF0F0);
    }

    Map<String, dynamic> _getItemStatus(
      Map<String, dynamic> item,
      String userName,
    ) {
      // Handle new expense format
      if (item.containsKey('paidBy') && item.containsKey('split')) {
        final paidBy = item['paidBy'] as Map<String, dynamic>;
        final split = item['split'] as List<dynamic>;

        // Find user's share in split
        double userShare = 0.0;
        for (var splitItem in split) {
          if (splitItem['email'] == userName || splitItem['name'] == userName) {
            // Use finalAmount if available (includes tax/charge), otherwise use amount
            userShare =
                splitItem['finalAmount'] as double? ??
                splitItem['amount'] as double? ??
                0.0;
            break;
          }
        }

        // Check if user paid
        bool userPaid = false;
        double userPaidAmount = 0.0;

        if (paidBy['type'] == 'single') {
          if (paidBy['payer'] == userName) {
            userPaid = true;
            userPaidAmount = paidBy['amount'] as double? ?? 0.0;
          }
        } else if (paidBy['type'] == 'multiple') {
          final payers = paidBy['payers'] as Map<String, dynamic>;
          if (payers.containsKey(userName)) {
            userPaid = true;
            userPaidAmount = payers[userName] as double? ?? 0.0;
          }
        }

        if (userPaid) {
          double netAmount = userPaidAmount - userShare;
          if (netAmount > 0) {
            return {
              'status': 'You are owed',
              'amount': netAmount,
              'color': Colors.green,
            };
          } else if (netAmount < 0) {
            return {
              'status': 'You owe',
              'amount': netAmount.abs(),
              'color': Colors.red,
            };
          } else {
            return {
              'status': 'Settled up',
              'amount': 0.0,
              'color': Colors.green,
            };
          }
        } else {
          return {
            'status': 'You owe',
            'amount': userShare,
            'color': Colors.red,
          };
        }
      }

      // Handle old format for backward compatibility
      final split = item['split'] as List<dynamic>? ?? [];
      final userSplit = _findUserInSplit(split, userName);
      final paidBy = item['paidBy'];
      final totalAmount = item['amount'] as double? ?? 0.0;
      if (userSplit.isEmpty) {
        return {'status': 'Not Involved', 'amount': 0.0, 'color': Colors.grey};
      }
      double userShare = userSplit['amount'] as double? ?? 0.0;
      if (paidBy == userName) {
        double amountOwedToYou = totalAmount - userShare;
        return {
          'status': 'Owes you',
          'amount': amountOwedToYou,
          'color': Colors.green,
        };
      } else {
        return {'status': 'You Owe', 'amount': userShare, 'color': Colors.red};
      }
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(232, 122, 102, 183),
            Color.fromARGB(209, 99, 89, 231),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Text(
                currentGroup['name'] ?? 'Group Detail',
                style: TextStyle(color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                icon: Text(
                  '+',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateExpenseForm(
                        groups: [currentGroup['name'] as String],
                        preSelectedGroup: currentGroup['name'] as String,
                        onExpenseCreated: () async {
                          // Reload the group data from SharedPreferences
                          await _reloadGroupData();
                        },
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.white),
                onPressed: () async {
                  final updatedGroup =
                      await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditGroupPage(
                            group: currentGroup,
                            onDeleteGroup: widget.onDeleteGroup,
                            onUpdateGroup: (updatedGroup) {
                              setState(() {
                                currentGroup = updatedGroup;
                              });
                            },
                          ),
                        ),
                      );

                  // If there's returned updated data, also update state
                  if (updatedGroup != null) {
                    setState(() {
                      currentGroup = updatedGroup;
                    });
                  }
                },
              ),
            ],
          ),
          leading: BackButton(
            color: Colors.white,
            onPressed: () {
              // Returning to Group Page
              Navigator.of(context).pop(currentGroup);
            },
          ),
        ),
        body: Stack(
          children: [
            ListView(
              padding: EdgeInsets.only(top: 70),
              children: [
                Container(
                  width: screenWidth,
                  margin: EdgeInsets.only(top: 0),
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    top: 50,
                    bottom: 68,
                  ),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 231, 227, 227),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Who owes whom?',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (details.isNotEmpty)
                        ...details.map(
                          (detail) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.grey[200],
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  detail['text'].isEmpty
                                      ? detail['name']
                                      : '${detail['name']} ${detail['text']}',
                                  style: TextStyle(fontSize: 15),
                                ),
                                const Spacer(),
                                Text(
                                  '${_getDisplayCurrency()} ${(_convertAmount(detail['amount'])).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (details.isEmpty)
                        Text(
                          'Everyone is settled up.',
                          style: TextStyle(color: Colors.black45),
                        ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: Offset(0, -20),
                  child: Container(
                    width: screenWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                _showMonthYearPicker();
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _getCurrentMonthYear(),
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.black54,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            // Currency selector
                            GestureDetector(
                              onTap: () {
                                _showCurrencySelector();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.currency_exchange,
                                      color: Colors.black54,
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      displayCurrency,
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 2),
                                    Icon(
                                      Icons.arrow_drop_down,
                                      color: Colors.black54,
                                      size: 16,
                                    ),
                                    if (isLoadingRate) ...[
                                      SizedBox(width: 4),
                                      SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...allItems.map((item) {
                          final itemStatus = _getItemStatus(item, userName);
                          final bgColor = _getItemBg(item, userName);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ExpansionTile(
                              tilePadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              childrenPadding: EdgeInsets.zero,
                              shape: Border(),
                              collapsedShape: Border(),
                              leading: CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(
                                  item['avatar'] != null
                                      ? IconData(
                                          item['avatar'] as int,
                                          fontFamily: 'MaterialIcons',
                                        )
                                      : Icons.card_giftcard,
                                  color: Color(0xFF7F55FF),
                                ),
                              ),
                              title: Text(
                                item['name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(item['date']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        itemStatus['status'],
                                        style: TextStyle(
                                          color: itemStatus['color'],
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (itemStatus['amount'] > 0)
                                        Text(
                                          '${_getDisplayCurrency()} ${(_convertAmount(itemStatus['amount'])).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: itemStatus['color'],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert, size: 20),
                                    onSelected: (String value) async {
                                      if (value == 'edit') {
                                        await _editExpense(item);
                                      } else if (value == 'delete') {
                                        await _deleteExpense(item);
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => [
                                      PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit,
                                              size: 16,
                                              color: Colors.blue,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              children: [_buildExpenseDetails(item)],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
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
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          status['text'] ?? 'You are owed',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getDisplayCurrency()} ${(_convertAmount(status['amount'] ?? 0.0)).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: status['text'] == 'You owe'
                                ? Colors.red
                                : status['text'] == 'Settled up'
                                ? Colors.grey
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Show different button based on settlement status
                    currentGroup['isSettled'] == true
                        ? ElevatedButton(
                            onPressed: () {
                              _showUndoSettleDialog();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade100,
                              foregroundColor: Colors.red.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text('Undo Settle'),
                          )
                        : ElevatedButton(
                            onPressed: () async {
                              final settlementData =
                                  _calculateOptimalSettlement();
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SettlementPage(
                                    group: currentGroup,
                                    optimizedSettlement:
                                        settlementData['settlements'],
                                    totalTransactions:
                                        settlementData['totalTransactions']
                                            .toDouble(),
                                    originalTransactions:
                                        settlementData['originalTransactions']
                                            .toDouble(),
                                    displayCurrency: displayCurrency,
                                    exchangeRate: exchangeRate,
                                    currencySymbol: _currencyService
                                        .getCurrencySymbol(displayCurrency),
                                  ),
                                ),
                              );

                              // If settlement was marked as settled, update local state
                              if (result == true) {
                                // Reload group data from SharedPreferences to ensure consistency
                                await _reloadGroupData();

                                setState(() {
                                  // State will be updated by _reloadGroupData()
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text('Settle'),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseDetails(Map<String, dynamic> item) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Who paid section
          Text(
            'Who paid:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          _buildPaidBySection(item),

          SizedBox(height: 16),

          // Split details section
          Text(
            'Split details:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          _buildSplitSection(item),

          // Show attachments if available
          if (item.containsKey('receiptPaths') &&
              (item['receiptPaths'] as List<dynamic>).isNotEmpty) ...[
            SizedBox(height: 16),
            Text(
              'Attachments:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            _buildAttachmentsSection(item),
          ],
        ],
      ),
    );
  }

  Widget _buildPaidBySection(Map<String, dynamic> item) {
    if (!item.containsKey('paidBy')) {
      return Text(
        'You paid ${_getDisplayCurrency()} ${(_convertAmount(item['amount'] ?? 0.0)).toStringAsFixed(2)}',
      );
    }

    final paidBy = item['paidBy'] as Map<String, dynamic>;

    if (paidBy['type'] == 'single') {
      final payer = paidBy['payer'] as String;
      final amount = paidBy['amount'] as double? ?? 0.0;
      final payerName = _getMemberName(payer);
      return Row(
        children: [
          Icon(Icons.person, size: 20, color: Colors.grey[600]),
          SizedBox(width: 8),
          Text(
            '$payerName paid ${_getDisplayCurrency()} ${(_convertAmount(amount)).toStringAsFixed(2)}',
          ),
        ],
      );
    } else if (paidBy['type'] == 'multiple') {
      final payers = paidBy['payers'] as Map<String, dynamic>;
      final split = item['split'] as List<dynamic>? ?? [];

      return Column(
        children: payers.entries.map((entry) {
          final payerEmail = entry.key;
          final amountPaid = entry.value as double;
          final payerName = _getMemberName(payerEmail);

          // Find how much this person should pay
          double shouldPay = 0.0;
          for (var splitItem in split) {
            if (splitItem['email'] == payerEmail) {
              shouldPay = splitItem['finalAmount'] as double? ??
                         splitItem['amount'] as double? ?? 0.0;
              break;
            }
          }

          // Calculate overpaid amount
          final overpaid = amountPaid - shouldPay;
          String paymentText = '$payerName paid ${_getDisplayCurrency()} ${(_convertAmount(amountPaid)).toStringAsFixed(2)}';

          if (overpaid > 0.01) {
            paymentText += ' (overpaid ${_getDisplayCurrency()} ${(_convertAmount(overpaid)).toStringAsFixed(2)})';
          } else if (overpaid < -0.01) {
            paymentText += ' (owes ${_getDisplayCurrency()} ${(_convertAmount(overpaid.abs())).toStringAsFixed(2)})';
          }

          return Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.person, size: 20, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(paymentText),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildSplitSection(Map<String, dynamic> item) {
    if (!item.containsKey('split')) {
      return SizedBox.shrink();
    }

    final split = item['split'] as List<dynamic>;

    // Get payer information to show who each person owes
    String payerName = 'Unknown';
    if (item.containsKey('paidBy')) {
      final paidBy = item['paidBy'] as Map<String, dynamic>;
      if (paidBy['type'] == 'single') {
        final payer = paidBy['payer'] as String;
        payerName = _getMemberName(payer);
      } else {
        payerName = 'Multiple payers';
      }
    } else {
      payerName = 'You';
    }

    // Check if this is a custom amount split and get tax/charge info
    bool isCustomAmount = split.isNotEmpty && split.first['method'] == 'custom';
    double serviceTaxPercentage = 0.0;
    double serviceChargePercentage = 0.0;

    // Get tax and charge percentages from the item data if available
    if (item.containsKey('serviceTaxPercentage')) {
      serviceTaxPercentage = (item['serviceTaxPercentage'] as double?) ?? 0.0;
    }
    if (item.containsKey('serviceChargePercentage')) {
      serviceChargePercentage =
          (item['serviceChargePercentage'] as double?) ?? 0.0;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show tax and service charge info for custom amount splits
        if (isCustomAmount) ...[
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applied Charges:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Service Tax: ${serviceTaxPercentage == 0 ? '0' : serviceTaxPercentage}%',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    Text(
                      'Service Charge: ${serviceChargePercentage == 0 ? '0' : serviceChargePercentage}%',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        // Show individual split amounts
        ...split.map<Widget>((splitItem) {
          final name = splitItem['name'] as String? ?? 'Unknown';
          // Use finalAmount if available (for custom amounts with tax/charge), otherwise use amount
          final amount =
              splitItem['finalAmount'] as double? ??
              splitItem['amount'] as double? ??
              0.0;
          final method = splitItem['method'] as String? ?? '';

          // Show split amount (what each person should pay)
          String debtText;
          if (payerName == 'Multiple payers') {
            // For multiple payers, show what each person should pay (not what they paid)
            String payText = name == 'You' ? 'You pay' : '$name pays';
            if (method == 'equally') {
              debtText = '$payText ${_getDisplayCurrency()} ${(_convertAmount(amount)).toStringAsFixed(2)}';
            } else if (method == 'custom') {
              debtText = '$payText ${_getDisplayCurrency()} ${(_convertAmount(amount)).toStringAsFixed(2)}';
            } else {
              debtText = '$payText ${_getDisplayCurrency()} ${(_convertAmount(amount)).toStringAsFixed(2)}';
            }
          } else if (name == payerName) {
            debtText =
                '$name paid ${_getDisplayCurrency()} ${(_convertAmount(amount)).toStringAsFixed(2)}';
          } else {
            debtText =
                '$name owes $payerName ${_getDisplayCurrency()} ${(_convertAmount(amount)).toStringAsFixed(2)}';
          }

          return Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
                SizedBox(width: 8),
                Expanded(child: Text(debtText)),
                if (method.isNotEmpty)
                  Text(
                    '($method)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Map<String, dynamic> _calculateOptimalSettlement() {
    final memberBalances = _calculateMemberBalances();

    // Separate creditors and debtors
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    memberBalances.forEach((email, balance) {
      if (balance > 0.01) {
        // Small threshold to avoid floating point issues
        creditors.add(MapEntry(email, balance));
      } else if (balance < -0.01) {
        debtors.add(MapEntry(email, balance.abs()));
      }
    });

    // Sort by amount (largest first) for better optimization
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    final optimizedSettlement = <Map<String, dynamic>>[];
    int originalTransactions = creditors.length + debtors.length;

    // Optimize settlements using greedy algorithm
    final creditorBalances = Map<String, double>.fromEntries(creditors);

    for (var debtor in debtors) {
      var remainingDebt = debtor.value;
      final debtorEmail = debtor.key;

      for (var creditor in creditors) {
        if (remainingDebt <= 0.01) break;

        final creditorEmail = creditor.key;
        final availableCredit = creditorBalances[creditorEmail] ?? 0.0;

        if (availableCredit <= 0.01) continue;

        final settlementAmount = math.min(remainingDebt, availableCredit);

        // Find member names
        String debtorName = _getMemberName(debtorEmail);
        String creditorName = _getMemberName(creditorEmail);

        // "You pay" not "You pays"
        String description;
        if (debtorName == 'You') {
          description = 'You pay $creditorName';
        } else {
          description = '$debtorName pays $creditorName';
        }

        optimizedSettlement.add({
          'description': description,
          'amount': settlementAmount,
          'from': debtorEmail,
          'to': creditorEmail,
        });

        // Update balances
        creditorBalances[creditorEmail] = availableCredit - settlementAmount;
        remainingDebt -= settlementAmount;
      }
    }

    return {
      'settlements': optimizedSettlement,
      'totalTransactions': optimizedSettlement.length,
      'originalTransactions': originalTransactions,
    };
  }

  Widget _buildAttachmentsSection(Map<String, dynamic> item) {
    final receiptPaths = item['receiptPaths'] as List<dynamic>;

    return Wrap(
      spacing: 4.7,
      runSpacing: 8,
      children: receiptPaths.map<Widget>((path) {
        return GestureDetector(
          onTap: () => _showImageViewer(path),
          child: Container(
            width: 63,
            height: 63,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(path as String),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey[400],
                      size: 32,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showImageViewer(String imagePath) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.file(
                    File(imagePath),
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[800],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 48,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Image not found',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMemberName(String email) {
    final members = currentGroup['members'] as List<dynamic>? ?? [];

    for (var member in members) {
      if (member['email'] == email) {
        // Return "You" for me, otherwise return the member's name
        if (member['isCurrentUser'] == true) {
          return 'You';
        }
        final name = member['name'] as String?;
        return name?.isNotEmpty == true ? name! : email;
      }
    }
    return email;
  }

  Future<void> _editExpense(Map<String, dynamic> expense) async {
    // Import CreateExpenseForm if not already imported
    final updatedExpense = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateExpenseForm(
          groups: [currentGroup['name']],
          preSelectedGroup: currentGroup['name'],
          editingExpense: expense,
          onExpenseCreated: () {
            // Reload group data when expense is updated
            setState(() {
              // This will trigger a rebuild and recalculation
            });
          },
        ),
      ),
    );

    if (updatedExpense != null) {
      // Find and update the expense in the group
      final expenses = currentGroup['expenses'] as List<dynamic>? ?? [];
      final expenseIndex = expenses.indexWhere(
        (e) =>
            e['name'] == expense['name'] &&
            e['date'] == expense['date'] &&
            e['amount'] == expense['amount'],
      );

      if (expenseIndex != -1) {
        expenses[expenseIndex] = updatedExpense;

        // Recalculate group total
        double total = 0.0;
        for (var exp in expenses) {
          total += (exp['amount'] as double? ?? 0.0);
        }
        currentGroup['total'] = total;

        // Save to SharedPreferences
        await _saveGroupToPreferences();
      }

      setState(() {
        // This will trigger a rebuild with the updated data
      });
    }
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Expense'),
          content: Text(
            'Are you sure you want to delete "${expense['name']}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      // Remove the expense from the group
      final expenses = currentGroup['expenses'] as List<dynamic>? ?? [];
      expenses.removeWhere(
        (e) =>
            e['name'] == expense['name'] &&
            e['date'] == expense['date'] &&
            e['amount'] == expense['amount'],
      );

      // Recalculate group total
      double total = 0.0;
      for (var exp in expenses) {
        total += (exp['amount'] as double? ?? 0.0);
      }
      currentGroup['total'] = total;

      // Save to SharedPreferences
      await _saveGroupToPreferences();

      setState(() {
        // This will trigger a rebuild with the updated data
      });
    }
  }

  Future<void> _saveGroupToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGroups = prefs.getStringList('groups') ?? [];

    // Find and update the group
    for (int i = 0; i < savedGroups.length; i++) {
      final groupData = json.decode(savedGroups[i]) as Map<String, dynamic>;
      if (groupData['name'] == currentGroup['name']) {
        savedGroups[i] = json.encode(currentGroup);
        break;
      }
    }

    await prefs.setStringList('groups', savedGroups);
  }
}
