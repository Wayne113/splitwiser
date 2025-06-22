import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'profile_page.dart';
import 'settlement_page.dart';
import 'edit_group_page.dart';
import 'create_expense_form.dart';
import 'dart:math' as math;

class GroupDetailPage extends StatefulWidget {
  final Map<String, dynamic> group;
  final VoidCallback? onDeleteGroup;
  const GroupDetailPage({Key? key, required this.group, this.onDeleteGroup}) : super(key: key);

  @override
  _GroupDetailPageState createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  late Map<String, dynamic> currentGroup;

  Future<void> _reloadGroupData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGroups = prefs.getStringList('groups') ?? [];

    // Find the current group in saved data
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
  }

  String _getUserName() {
    // Find current user's email from group members
    final members = currentGroup['members'] as List<dynamic>? ?? [];
    for (var member in members) {
      if (member['isCurrentUser'] == true) {
        return member['email'] as String;
      }
    }
    return 'You'; // Fallback
  }

  Map<String, dynamic> _recalculateGroupSettlement() {
    // Get expenses and group members
    final expenses = currentGroup['expenses'] as List<dynamic>? ?? [];
    final members = currentGroup['members'] as List<dynamic>? ?? [];
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
            'text': '',
            'amount': balance.abs(),
          });
        } else {
          // This member has negative balance (they paid less than their share)
          // So they owe you
          details.add({
            'name': '$memberName owes you',
            'text': '',
            'amount': balance.abs(),
          });
        }
      }
    });

    return {
      'details': details,
      'status': {
        'text': userBalance >= 0 ? 'You are owed' : 'You owe',
        'color': userBalance >= 0 ? 0xFFE8F5E8 : 0xFFFFE0E0,
        'amount': userBalance.abs(),
      },
    };
  }

  @override
  Widget build(BuildContext context) {
    // Try to get expenses first (new format), fallback to items (old format)
    final expenses = currentGroup['expenses'] as List<dynamic>? ?? [];
    final items = currentGroup['items'] as List<dynamic>? ?? [];
    final allItems = expenses.isNotEmpty ? expenses : items;

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
        final totalAmount = item['amount'] as double? ?? 0.0;

        // Find user's share in split
        double userShare = 0.0;
        for (var splitItem in split) {
          if (splitItem['email'] == userName || splitItem['name'] == userName) {
            userShare = splitItem['amount'] as double? ?? 0.0;
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
                icon: Text('+', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
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
                  final updatedGroup = await Navigator.push<Map<String, dynamic>>(
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

                  // 如果有返回的更新数据，也更新状态
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
                                  detail['text'].isEmpty ? detail['name'] : '${detail['name']} ${detail['text']}',
                                  style: TextStyle(fontSize: 15),
                                ),
                                const Spacer(),
                                Text(
                                  'RM ${detail['amount'].toStringAsFixed(2)}',
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
                      )
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Mar 2024',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.calendar_today,
                              color: Colors.black45,
                              size: 20,
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
                              tilePadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                          'RM ${itemStatus['amount'].toStringAsFixed(2)}',
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
                                            Icon(Icons.edit, size: 16, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 16, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              children: [
                                _buildExpenseDetails(item),
                              ],
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
                          style: TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'RM ${status['amount']?.toStringAsFixed(2) ?? ''}',
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
                    ElevatedButton(
                      onPressed: () {
                        final settlementData = _calculateOptimalSettlement();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SettlementPage(
                              group: currentGroup,
                              optimizedSettlement: settlementData['settlements'],
                              totalTransactions: settlementData['totalTransactions'].toDouble(),
                              originalTransactions: settlementData['originalTransactions'].toDouble(),
                            ),
                          ),
                        );
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
        ],
      ),
    );
  }

  Widget _buildPaidBySection(Map<String, dynamic> item) {
    if (!item.containsKey('paidBy')) {
      return Text('You paid RM ${item['amount']?.toStringAsFixed(2) ?? '0.00'}');
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
          Text('$payerName paid RM ${amount.toStringAsFixed(2)}'),
        ],
      );
    } else if (paidBy['type'] == 'multiple') {
      final payers = paidBy['payers'] as Map<String, dynamic>;
      return Column(
        children: payers.entries.map((entry) {
          final payerName = _getMemberName(entry.key);
          return Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(Icons.person, size: 20, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text('$payerName paid RM ${(entry.value as double).toStringAsFixed(2)}'),
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

    return Column(
      children: split.map<Widget>((splitItem) {
        final name = splitItem['name'] as String? ?? 'Unknown';
        final amount = splitItem['amount'] as double? ?? 0.0;
        final method = splitItem['method'] as String? ?? '';

        return Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
              SizedBox(width: 8),
              Expanded(
                child: Text('$name owes RM ${amount.toStringAsFixed(2)}'),
              ),
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
      }).toList(),
    );
  }

  Map<String, dynamic> _calculateOptimalSettlement() {
    // Get expenses and group members
    final expenses = currentGroup['expenses'] as List<dynamic>? ?? [];
    final members = currentGroup['members'] as List<dynamic>? ?? [];
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

    // Separate creditors and debtors
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    memberBalances.forEach((email, balance) {
      if (balance > 0.01) { // Small threshold to avoid floating point issues
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
    final debtorBalances = Map<String, double>.fromEntries(debtors);

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

        optimizedSettlement.add({
          'description': '$debtorName pays $creditorName',
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

  String _getMemberName(String email) {
    final members = currentGroup['members'] as List<dynamic>? ?? [];
    for (var member in members) {
      if (member['email'] == email) {
        return member['name'] as String;
      }
    }
    return email; // Fallback to email if name not found
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
      final expenseIndex = expenses.indexWhere((e) =>
        e['name'] == expense['name'] &&
        e['date'] == expense['date'] &&
        e['amount'] == expense['amount']
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
          content: Text('Are you sure you want to delete "${expense['name']}"?'),
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
      expenses.removeWhere((e) =>
        e['name'] == expense['name'] &&
        e['date'] == expense['date'] &&
        e['amount'] == expense['amount']
      );

      // Recalculate group total
      double total = 0.0;
      for (var exp in expenses) {
        total += (exp['amount'] as double? ?? 0.0);
      }
      currentGroup['total'] = total;

      // Save to SharedPreferences
      await _saveGroupToPreferences();

      // Update UI
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
