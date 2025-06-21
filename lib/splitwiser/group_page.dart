import 'package:flutter/material.dart';
import 'transaction_page.dart';
import 'scan_page.dart';
import 'group_detail_page.dart';
import 'create_expense_form.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({super.key});

  @override
  GroupPageState createState() => GroupPageState();
}

class GroupPageState extends State<GroupPage> {
  List<Map<String, dynamic>> groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
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
                        icon: const Icon(Icons.add, color: Color(0xFF7F55FF)),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreateExpenseForm(
                                groups: groups
                                    .map((g) => g['name'] as String)
                                    .toList(),
                                onExpenseCreated: () {
                                  _loadGroups(); 
                                },
                              ),
                            ),
                          );
                        },
                        iconSize: 22,
                      ),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(
                      'https://randomuser.me/api/portraits/men/32.jpg',
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
                        children: const [
                          Text(
                            'RM 2567.58',
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
                        children: const [
                          Text(
                            'RM 2826.43',
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
              ...groups.map((group) => _buildGroupCard(group)).toList(),
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
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
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
            if (group['details'] != null &&
                (group['details'] as List).isNotEmpty)
              ...(group['details'] as List).map<Widget>(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
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
                      const SizedBox(width: 8),
                      Text(
                        '${detail['name'] ?? ''} ${detail['text'] ?? ''}',
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
            if (group['details'] == null || (group['details'] as List).isEmpty)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: group['status']?['color'] != null
                      ? Color(group['status']['color'] as int)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  group['status']?['text'] ?? 'No expenses yet',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            if (group['status'] != null && group['status']['amount'] != null)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: group['status']['color'] != null
                      ? Color(group['status']['color'] as int)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(
                      group['status']['text'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: group['status']['color'] == 0xFFFFE0E0
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'RM ${group['status']['amount']?.toStringAsFixed(2) ?? '0.00'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: group['status']['color'] == 0xFFFFE0E0
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
}
