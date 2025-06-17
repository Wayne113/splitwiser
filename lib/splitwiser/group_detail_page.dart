import 'package:flutter/material.dart';

class GroupDetailPage extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback? onDeleteGroup;
  const GroupDetailPage({Key? key, required this.group, this.onDeleteGroup}) : super(key: key);

  String _getUserName() => 'You';

  @override
  Widget build(BuildContext context) {
    final items = group['items'] as List<dynamic>? ?? [];
    final details = group['details'] as List<dynamic>? ?? [];
    final status = group['status'] as Map<String, dynamic>? ?? {};
    final userName = _getUserName();
    final screenWidth = MediaQuery.of(context).size.width;

    // Helper for item status
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
      if (user.isEmpty) return Color(0xFFF3F3F3); // Not Involved
      if (item['paidBy'] == userName) return Color(0xFFE0F2E9); // Owes you
      return Color(0xFFFFF0F0); // You owe
    }

    Map<String, dynamic> _getItemStatus(
      Map<String, dynamic> item,
      String userName,
    ) {
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
            Color.fromARGB(232, 176, 150, 255),
            Color.fromARGB(209, 99, 90, 221),
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
                group['name'] ?? 'Group Detail',
                style: TextStyle(color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.white),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Confirm Deletion'),
                        content: Text('Are you sure you want to delete this group?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (onDeleteGroup != null) {
                                onDeleteGroup!();
                              }
                              Navigator.of(context).pop();
                            },
                            child: Text('Delete'),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.9),
                child: Icon(Icons.cake, color: Colors.pink),
              ),
            ],
          ),
          leading: BackButton(color: Colors.white),
        ),
        body: Stack(
          children: [
            // 下方两个卡片
            ListView(
              padding: EdgeInsets.only(top: 70),
              children: [
                // Who owes whom 卡片（全屏宽，顶部圆角）
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
                                  '${detail['name']} ${detail['text']}',
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
                // 日期/账单明细卡片（全屏宽，无圆角）
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
                        ...items.map((item) {
                          final itemStatus = _getItemStatus(item, userName);
                          final bgColor = _getItemBg(item, userName);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: bgColor,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.card_giftcard,
                                  color: Colors.pinkAccent,
                                ),
                              ),
                              title: Text(
                                item['name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(item['date']),
                              trailing: Column(
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
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // 顶部 you are owed 卡片（悬浮，有阴影和圆角）
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
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {},
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
}
