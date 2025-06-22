import 'package:flutter/material.dart';
import 'transaction_page.dart';
import 'scan_page.dart';
import 'group_detail_page.dart';

import 'add_new_group_page.dart';
import 'friends_page.dart';
import 'profile_page.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  GroupPageState createState() => GroupPageState();
}

class GroupPageState extends State<GroupPage> {
  List<Map<String, dynamic>> groups = [];
  UserProfile? userProfile;

  // Calculate total amounts owed and owing
  Map<String, double> _calculateTotalBalances() {
    double youOwe = 0.0;
    double owesYou = 0.0;

    for (var group in groups) {
      final expenses = group['expenses'] as List<dynamic>? ?? [];
      final members = group['members'] as List<dynamic>? ?? [];

      // Find current user's email
      String currentUserEmail = '';
      for (var member in members) {
        if (member['isCurrentUser'] == true) {
          currentUserEmail = member['email'];
          break;
        }
      }

      if (currentUserEmail.isEmpty) continue;

      // Calculate balance for this group
      double balance = 0.0;

      for (var expense in expenses) {
        final paidBy = expense['paidBy'] as Map<String, dynamic>? ?? {};
        final split = expense['split'] as List<dynamic>? ?? [];

        // Calculate how much current user paid
        double userPaid = 0.0;
        if (paidBy['type'] == 'single' && paidBy['payer'] == currentUserEmail) {
          userPaid = paidBy['amount'] as double? ?? 0.0;
        } else if (paidBy['type'] == 'multiple') {
          final payers = paidBy['payers'] as Map<String, dynamic>? ?? {};
          userPaid = payers[currentUserEmail] as double? ?? 0.0;
        }

        // Calculate how much current user owes
        double userOwes = 0.0;
        for (var splitItem in split) {
          if (splitItem['email'] == currentUserEmail) {
            userOwes = splitItem['amount'] as double? ?? 0.0;
            break;
          }
        }

        // Add to balance (positive = owed to user, negative = user owes)
        balance += userPaid - userOwes;
      }

      // Add to totals
      if (balance > 0) {
        owesYou += balance;
      } else if (balance < 0) {
        youOwe += -balance;
      }
    }

    return {
      'youOwe': youOwe,
      'owesYou': owesYou,
    };
  }

  @override
  void initState() {
    super.initState();
    _loadGroups();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await ProfileManager.loadProfile();
    setState(() {
      userProfile = profile;
    });
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
    } catch (e) {
      final groupsData = prefs.get('groups');
      if (groupsData is String) {
        await prefs.remove('groups');
        setState(() {
          groups = [];
        });
      } else {
        setState(() {
          groups = [];
        });
      }
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
                        icon: const Icon(Icons.group_add, color: Color(0xFF7F55FF)),
                        onPressed: () async {
                          final newGroup = await Navigator.push<Group>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AddNewGroupPage(),
                            ),
                          );

                          if (newGroup != null) {
                            // Convert to Map and add to groups
                            final groupMap = await newGroup.toJson();

                            // Save to SharedPreferences
                            final prefs = await SharedPreferences.getInstance();
                            final savedGroups = prefs.getStringList('groups') ?? [];
                            savedGroups.add(json.encode(groupMap));
                            await prefs.setStringList('groups', savedGroups);

                            // Update the local groups list
                            if (mounted) {
                              setState(() {
                                groups.add(groupMap);
                              });

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Group "${newGroup.name}" created successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                        iconSize: 22,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        icon: const Icon(Icons.people, color: Color(0xFF7F55FF)),
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
                            'RM ${_calculateTotalBalances()['youOwe']!.toStringAsFixed(2)}',
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
                            'RM ${_calculateTotalBalances()['owesYou']!.toStringAsFixed(2)}',
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
    } else {
      bodyContent = TransactionPage();
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ScanPage()),
                    );
                  },
                  icon: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 244, 67, 54),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.document_scanner_outlined,
                      color: Colors.white,
                      size: 28.0,
                    ),
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
                  child: Icon(
                    Icons.swap_horiz,
                    color: Colors.white,
                    size: 24.0,
                  ),
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
        final updatedGroupFromDetail = await Navigator.of(context).push<Map<String, dynamic>>(
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

        // 如果有更新的group数据返回，更新本地groups列表
        if (updatedGroupFromDetail != null) {
          setState(() {
            final groupIndex = groups.indexWhere((g) => g['name'] == group['name']);
            if (groupIndex != -1) {
              groups[groupIndex] = updatedGroupFromDetail;
            }
          });
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
                  'RM ${(group['total'] ?? 0.0).toStringAsFixed(2)}',
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
                        'RM ${(detail['amount'] ?? 0.0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (updatedGroup['details'] == null || (updatedGroup['details'] as List).isEmpty)
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
            if (updatedGroup['status'] != null && updatedGroup['status']['amount'] != null)
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
                              color: updatedGroup['status']['color'] == 0xFFFFE0E0
                                  ? Colors.red
                                  : Colors.green,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'RM ${updatedGroup['status']['amount']?.toStringAsFixed(2) ?? '0.00'}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: updatedGroup['status']['color'] == 0xFFFFE0E0
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

  Map<String, dynamic> _recalculateGroupSettlement(Map<String, dynamic> group) {
    // Get expenses and group members
    final expenses = group['expenses'] as List<dynamic>? ?? [];
    final members = group['members'] as List<dynamic>? ?? [];
    final memberBalances = <String, double>{};

    // Find current user's email
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
          memberBalances[email] = (memberBalances[email] ?? 0.0) + (amount as double);
        });
      }

      // Subtract amounts owed
      for (var splitItem in split) {
        final email = splitItem['email'] as String;
        final amount = splitItem['amount'] as double;
        memberBalances[email] = (memberBalances[email] ?? 0.0) - amount;
      }
    }

    // Update group details and status
    final details = <Map<String, dynamic>>[];
    double userBalance = memberBalances[currentUserEmail] ?? 0.0;

    memberBalances.forEach((email, balance) {
      if (balance != 0 && email != currentUserEmail) {
        // Find member name by email
        String memberName = email;
        for (var member in members) {
          if (member['email'] == email) {
            memberName = member['name'];
            break;
          }
        }

        if (balance > 0) {
          // This member has positive balance (they paid more than their share)
          // So you owe them
          details.add({
            'name': 'You owe $memberName',
            'amount': balance.abs(),
          });
        } else {
          // This member has negative balance (they paid less than their share)
          // So they owe you
          details.add({
            'name': '$memberName owes you',
            'amount': balance.abs(),
          });
        }
      }
    });

    return {
      'details': details,
      'status': {
        'text': userBalance == 0 ? 'Settled up' : (userBalance > 0 ? 'You are owed' : 'You owe'),
        'color': userBalance == 0 ? 0xFFE8F5E8 : (userBalance > 0 ? 0xFFE8F5E8 : 0xFFFFE0E0),
        'amount': userBalance.abs(),
      },
    };
  }
}
