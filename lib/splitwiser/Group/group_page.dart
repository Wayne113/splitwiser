import 'package:flutter/material.dart';
import 'group_detail_page.dart';
import '../Add/add_new_group_page.dart';
import '../Add/create_expense_form.dart';
import 'friends_page.dart';
import 'profile_page.dart';
import 'currency_service.dart';
import '../Dashboard/dashbaord_page.dart';
import '../Dashboard/activity_service.dart';

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  GroupPageState createState() => GroupPageState();
}

class GroupPageState extends State<GroupPage> {
  List<Map<String, dynamic>> groups = [];
  UserProfile? userProfile;

  double totalYouOwe = 0.0;
  double totalOwesYou = 0.0;

  String displayCurrency = 'MYR';
  double exchangeRate = 1.0;
  final CurrencyService _currencyService = CurrencyService();

  void _calculateTotalBalances() {
    double youOwe = 0.0;
    double owesYou = 0.0;

    for (var group in groups) {
      if (group['isSettled'] == true) {
        continue;
      }

      final expenses = group['expenses'] as List<dynamic>? ?? [];
      final members = group['members'] as List<dynamic>? ?? [];

      String currentUserEmail = '';
      for (var member in members) {
        if (member['isCurrentUser'] == true) {
          currentUserEmail = member['email'];
          break;
        }
      }

      if (currentUserEmail.isEmpty) continue;

      double balance = 0.0;

      for (var expense in expenses) {
        final paidBy = expense['paidBy'] as Map<String, dynamic>? ?? {};
        final split = expense['split'] as List<dynamic>? ?? [];

        double userPaid = 0.0;
        if (paidBy['type'] == 'single' && paidBy['payer'] == currentUserEmail) {
          userPaid = paidBy['amount'] as double? ?? 0.0;
        } else if (paidBy['type'] == 'multiple') {
          final payers = paidBy['payers'] as Map<String, dynamic>? ?? {};
          userPaid = payers[currentUserEmail] as double? ?? 0.0;
        }

        double userOwes = 0.0;
        for (var splitItem in split) {
          if (splitItem['email'] == currentUserEmail) {
            userOwes =
                splitItem['finalAmount'] as double? ??
                splitItem['amount'] as double? ??
                0.0;
            break;
          }
        }

        balance += userPaid - userOwes;
      }

      if (balance > 0) {
        owesYou += balance;
      } else if (balance < 0) {
        youOwe += -balance;
      }
    }

    setState(() {
      totalYouOwe = youOwe;
      totalOwesYou = owesYou;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _loadUserProfile();
    _loadCurrencyPreference();
  }

  Future<void> _loadUserProfile() async {
    final profile = await ProfileManager.loadProfile();
    setState(() {
      userProfile = profile;
    });
  }

  // Load saved currency preference
  Future<void> _loadCurrencyPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('preferred_display_currency');

      if (savedCurrency != null && savedCurrency != displayCurrency) {
        final rate = await _currencyService.getExchangeRate(
          'MYR',
          savedCurrency,
        );

        setState(() {
          displayCurrency = savedCurrency;
          exchangeRate = rate;
        });
      }
    } catch (e) {
      print("Error loading currency preference: $e");
    }
  }

  // Check for currency changes when returning from other pages
  Future<void> _checkCurrencyChanges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency =
          prefs.getString('preferred_display_currency') ?? 'MYR';

      if (savedCurrency != displayCurrency) {
        final rate = await _currencyService.getExchangeRate(
          'MYR',
          savedCurrency,
        );

        setState(() {
          displayCurrency = savedCurrency;
          exchangeRate = rate;
        });
      }
    } catch (e) {
      print("Error checking currency changes: $e");
    }
  }

  // Convert amount from MYR to display currency
  double _convertAmount(double amount) {
    return amount * exchangeRate;
  }

  // Get currency symbol for display
  String _getCurrencySymbol() {
    return _currencyService.getCurrencySymbol(displayCurrency);
  }

  ImageProvider _getAvatarImage() {
    if (userProfile?.localAvatarPath != null) {
      return FileImage(File(userProfile!.localAvatarPath!));
    } else if (userProfile?.avatarUrl != null) {
      return NetworkImage(userProfile!.avatarUrl!);
    } else {
      return NetworkImage('https://randomuser.me/api/portraits/men/32.jpg');
    }
  }

  Future<void> _loadGroups() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final savedGroups = prefs.getStringList('groups') ?? [];
      setState(() {
        groups = savedGroups
            .map((groupStr) => json.decode(groupStr) as Map<String, dynamic>)
            .toList();
      });
      _calculateTotalBalances();
    } catch (e) {
      print("Error laoding groups: $e");

      setState(() {
        groups = [];
      });
      _calculateTotalBalances();
    }
  }

  Future<void> _saveGroups() async {
    final prefs = await SharedPreferences.getInstance();
    final groupsJson = groups.map((group) => json.encode(group)).toList();
    await prefs.setStringList('groups', groupsJson);
  }

  int selectedIndex = 0;
  double scanScale = 1.0;

  void _deleteGroup(String groupName) {
    setState(() {
      groups.removeWhere((group) => group['name'] == groupName);
      _saveGroups();
    });
  }

  // Show add menu with options for group or expense
  void _showAddMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Add New',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF7F55FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.group_add, color: Color(0xFF7F55FF)),
                ),
                title: Text('Add Group'),
                subtitle: Text('Create a new group'),
                onTap: () async {
                  Navigator.pop(context);
                  final newGroup = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddNewGroupPage(),
                    ),
                  );
                  if (newGroup != null) {
                    // Save the new group to SharedPreferences
                    final groupData = await (newGroup as Group).toJson();
                    setState(() {
                      groups.add(groupData);
                    });
                    await _saveGroups();

                    // Log group creation activity (optional, ignore errors)
                    try {
                      await ActivityService.addGroupCreated(
                        groupName: groupData['name'],
                      );
                    } catch (e) {
                      // Continue even if activity logging fails
                    }
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.receipt_long, color: Color(0xFF4CAF50)),
                ),
                title: Text('Add Expense'),
                subtitle: Text('Create a new expense'),
                onTap: () async {
                  Navigator.pop(context);
                  // Get all group names for the expense form
                  final groupNames = groups
                      .map((g) => g['name'] as String)
                      .toList();

                  if (groupNames.isNotEmpty) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateExpenseForm(
                          groups: groupNames,
                          onExpenseCreated: () async {
                            // Reload groups to reflect new expense
                            await _loadGroups();
                          },
                        ),
                      ),
                    );
                  } else {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please create a group first before adding expenses',
                          ),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    if (selectedIndex == 0) {
      bodyContent = SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Groups',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'You are in ${groups.length} group${groups.length == 1 ? '' : 's'}.',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(
                          Icons.people,
                          color: Color(0xFF7F55FF),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FriendsPage(),
                            ),
                          );
                        },
                        iconSize: 22,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () async {
                      final updatedProfile = await Navigator.push<UserProfile>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfilePage(),
                        ),
                      );
                      if (updatedProfile != null) {
                        setState(() {
                          userProfile = updatedProfile;
                        });
                        // Reload groups to see profile changes
                        await _loadGroups();
                      }
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: _getAvatarImage(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  //You Owe
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(233, 43, 37, 55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'RM ${totalYouOwe.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'You Owe',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  //Owes You
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(233, 43, 37, 55),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'RM ${totalOwesYou.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Owes You',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ...groups.map((group) => _buildGroupCard(group)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    } else if (selectedIndex == 2) {
      bodyContent = DashboardPage();
    } else {
      bodyContent = Container(); 
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(233, 127, 85, 255),
            Color.fromARGB(71, 34, 26, 89),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: bodyContent),
        // Bar
        bottomNavigationBar: Container(
          margin: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
          height: 56,
          decoration: BoxDecoration(
            color: const Color.fromARGB(99, 43, 42, 42),
            borderRadius: BorderRadius.circular(30.0),
            boxShadow: [
              BoxShadow(
                color: Color.fromARGB(93, 0, 0, 0),
                blurRadius: 1,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedIndex = 0;
                  });
                },
                icon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selectedIndex == 0
                        ? Color.fromARGB(85, 255, 255, 255)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.supervisor_account,
                    color: Colors.white,
                    size: 24.0,
                  ),
                ),
              ),
              AnimatedScale(
                scale: scanScale,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: IconButton(
                  splashRadius: 28,
                  onPressed: () async {
                    setState(() {
                      scanScale = 0.85;
                    });
                    await Future.delayed(const Duration(milliseconds: 120));
                    setState(() {
                      scanScale = 1.0;
                    });
                    _showAddMenu();
                  },
                  icon: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 244, 67, 54),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, color: Colors.white, size: 28.0),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedIndex = 2;
                  });
                },
                icon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selectedIndex == 2
                        ? const Color.fromARGB(85, 255, 255, 255)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.dashboard, color: Colors.white, size: 24.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Group card
  Widget _buildGroupCard(Map<String, dynamic> group) {
    // Recalculate group details for display
    final recalculatedData = _recalculateGroupSettlement(group);
    final updatedGroup = Map<String, dynamic>.from(group);
    updatedGroup['details'] = recalculatedData['details'];
    updatedGroup['status'] = recalculatedData['status'];

    return GestureDetector(
      onTap: () async {
        final updatedGroupFromDetail = await Navigator.of(context)
            .push<Map<String, dynamic>>(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    GroupDetailPage(
                      group: group,
                      onDeleteGroup: () => _deleteGroup(group['name']),
                    ),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.98, end: 1.0).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                transitionDuration: Duration(milliseconds: 200),
              ),
            );

        // Check for currency changes when returning from group detail
        await _checkCurrencyChanges();

        // If updated group data is returned, update local groups list
        if (updatedGroupFromDetail != null) {
          setState(() {
            final groupIndex = groups.indexWhere(
              (g) => g['name'] == group['name'],
            );
            if (groupIndex != -1) {
              groups[groupIndex] = updatedGroupFromDetail;
            }
          });
          // Recalculate total balances
          _calculateTotalBalances();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color.fromARGB(121, 255, 255, 255),
          borderRadius: BorderRadius.circular(18),
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
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.house, color: Colors.deepOrangeAccent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        group['date'] ?? '',
                        style: TextStyle(
                          color: Color.fromARGB(255, 49, 49, 49),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_getCurrencySymbol()} ${_convertAmount(group['total'] ?? 0.0).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (updatedGroup['details'] != null &&
                (updatedGroup['details'] as List).isNotEmpty)
              ...(updatedGroup['details'] as List).map<Widget>(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 4, left: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey[200],
                        child: Icon(
                          detail['avatar'] != null
                              ? IconData(
                                  detail['avatar'] as int,
                                  fontFamily: 'MaterialIcons',
                                )
                              : Icons.person,
                          size: 16,
                          color: Colors.blueGrey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        detail['name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const Spacer(),
                      Text(
                        '${_getCurrencySymbol()} ${_convertAmount(detail['amount'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (updatedGroup['details'] == null ||
                (updatedGroup['details'] as List).isEmpty)
              // Only show middle bar if NOT settled up
              if (updatedGroup['status']?['text'] != 'Settled up')
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: updatedGroup['status']?['color'] != null
                        ? Color(updatedGroup['status']['color'] as int)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    updatedGroup['status']?['text'] ?? 'No expenses yet',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
            if (updatedGroup['status'] != null &&
                updatedGroup['status']['amount'] != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: updatedGroup['status']['color'] != null
                      ? Color(updatedGroup['status']['color'] as int)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: updatedGroup['status']['text'] == 'Settled up'
                    ? Alignment.center
                    : null,
                child: updatedGroup['status']['text'] == 'Settled up'
                    ? Text(
                        'Settled up',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      )
                    : Row(
                        children: [
                          Text(
                            updatedGroup['status']['text'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color:
                                  updatedGroup['status']['color'] == 0xFFFFE0E0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_getCurrencySymbol()} ${_convertAmount(updatedGroup['status']['amount'] ?? 0.0).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color:
                                  updatedGroup['status']['color'] == 0xFFFFE0E0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                        ],
                      ),
              ),
          ],
        ),
      ),
    );
  }

  // Get member name by email
  String _getMemberName(String email, List<dynamic> members) {
    for (var member in members) {
      if (member['email'] == email) {
        if (member['isCurrentUser'] == true) {
          return 'You';
        }
        return member['name'];
      }
    }
    return email;
  }

  Map<String, dynamic> _recalculateGroupSettlement(Map<String, dynamic> group) {
    // Check if group is settled, yes then show settled up text
    if (group['isSettled'] == true) {
      return {
        'details': <Map<String, dynamic>>[],
        'status': {'text': 'Settled up', 'color': 0xFFE8F5E8, 'amount': 0.0},
      };
    }

    // Get expenses and group members
    final expenses = group['expenses'] as List<dynamic>? ?? [];
    final members = group['members'] as List<dynamic>? ?? [];
    final memberBalances = <String, double>{};

    // Find my email
    String currentUserEmail = 'You';
    for (var member in members) {
      if (member['isCurrentUser'] == true) {
        currentUserEmail = member['email'];
        break;
      }
    }

    // Initialize balances for all members
    for (var member in members) {
      memberBalances[member['email']] = 0.0;
    }

    // Calculate balances from all expenses
    for (var expense in expenses) {
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
        // Use finalAmount (if includes tax/charge), otherwise use amount
        final amount =
            splitItem['finalAmount'] as double? ??
            splitItem['amount'] as double? ??
            0.0;
        memberBalances[email] = (memberBalances[email] ?? 0.0) - amount;
      }
    }

    // Update group details and status
    final details = <Map<String, dynamic>>[];
    double userBalance = memberBalances[currentUserEmail] ?? 0.0;

    // Optimized all transactions
    // Separate creditors (positive balance) and debtors (negative balance)
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    memberBalances.forEach((email, balance) {
      if (balance > 0.01) {
        creditors.add(MapEntry(email, balance));
      } else if (balance < -0.01) {
        debtors.add(MapEntry(email, balance.abs()));
      }
    });

    // Create debt relationships
    final creditorBalances = Map<String, double>.fromEntries(creditors);

    for (var debtor in debtors) {
      var remainingDebt = debtor.value;
      final debtorEmail = debtor.key;
      final debtorName = _getMemberName(debtorEmail, members);

      for (var creditor in creditors) {
        if (remainingDebt <= 0.01) break;

        final creditorEmail = creditor.key;
        final creditorName = _getMemberName(creditorEmail, members);
        final availableCredit = creditorBalances[creditorEmail] ?? 0.0;

        if (availableCredit <= 0.01) continue;

        final settlementAmount = math.min(remainingDebt, availableCredit);

        // Grammar hehe
        String debtorDisplayName = debtorEmail == currentUserEmail
            ? 'You'
            : debtorName;
        String creditorDisplayName = creditorEmail == currentUserEmail
            ? 'You'
            : creditorName;

        // "You owe" not "You owes"
        String debtText;
        if (debtorDisplayName == 'You') {
          debtText = 'You owe $creditorDisplayName';
        } else {
          debtText = '$debtorDisplayName owes $creditorDisplayName';
        }

        details.add({'name': debtText, 'amount': settlementAmount});

        creditorBalances[creditorEmail] = availableCredit - settlementAmount;
        remainingDebt -= settlementAmount;
      }
    }

    return {
      'details': details,
      'status': {
        'text': userBalance == 0
            ? 'Settled up'
            : (userBalance > 0 ? 'You are owed' : 'You owe'),
        'color': userBalance == 0
            ? 0xFFE8F5E8
            : (userBalance > 0 ? 0xFFE8F5E8 : 0xFFFFE0E0),
        'amount': userBalance.abs(),
      },
    };
  }
}
