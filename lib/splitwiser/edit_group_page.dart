import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:splitwiser/splitwiser/add_friends_page.dart';
import 'package:splitwiser/splitwiser/friends_page.dart';

class EditGroupPage extends StatefulWidget {
  final Map<String, dynamic> group;
  final VoidCallback? onDeleteGroup;
  final Function(Map<String, dynamic>)? onUpdateGroup;

  const EditGroupPage({
    Key? key,
    required this.group,
    this.onDeleteGroup,
    this.onUpdateGroup,
  }) : super(key: key);

  @override
  _EditGroupPageState createState() => _EditGroupPageState();
}

class _EditGroupPageState extends State<EditGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  List<Friend> _addedFriends = [];

  bool _isFormValid() {
    return _groupNameController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    // 预填充group name
    _groupNameController.text = widget.group['name'] ?? '';

    // 转换现有members为Friend对象
    final members = widget.group['members'] as List<dynamic>? ?? [];
    _addedFriends = members.map((member) => Friend(
      name: member['name'] ?? '',
      email: member['email'] ?? '',
    )).toList();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 防止键盘弹出时按钮浮动
      appBar: AppBar(
        title: const Text(
          'Edit Group',
          style: TextStyle(color: Colors.white70),
        ),
        backgroundColor: const Color.fromARGB(255, 39, 39, 40),
        iconTheme: const IconThemeData(color: Colors.white70),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 39, 39, 40),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              TextField(
                controller: _groupNameController,
                readOnly: true, // Make group name non-editable
                enabled: false, // Disable the field completely
                decoration: InputDecoration(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Group name', style: TextStyle(color: Colors.grey)),
                      Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  hintText: 'Enter group name',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                  ),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 20,
                  ),
                  filled: true,
                  fillColor: Color.fromARGB(255, 37, 37, 39),
                ),
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 40),
              GestureDetector(
                onTap: () async {
                  final selectedFriends = await Navigator.push<List<Friend>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FriendsPage(selectedFriends: _addedFriends),
                    ),
                  );
                  if (selectedFriends != null) {
                    setState(() {
                      _addedFriends = selectedFriends;
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Members',
                        style: TextStyle(fontSize: 17, color: Colors.white),
                      ),
                      Icon(Icons.add, color: Colors.white),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: _addedFriends.map((friend) {
                    // 检查是否是当前用户（wayne）
                    final isCurrentUser = friend.email == 'wayne_113@outlook.com' ||
                                         friend.name.toLowerCase() == 'wayne';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 37, 37, 39),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCurrentUser ? Colors.deepPurple : Colors.grey,
                          width: isCurrentUser ? 2.0 : 1.0,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    friend.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (isCurrentUser) ...[
                                    SizedBox(width: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'You',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 4),
                              Text(
                                friend.email,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          // 只有非当前用户才显示删除按钮
                          if (!isCurrentUser)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.red[300],
                                  shape: BoxShape.circle,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _addedFriends.remove(friend);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(9),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _deleteGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isFormValid()
                          ? () async {
                              _saveChanges();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(164, 92, 56, 200),
                        disabledBackgroundColor: Color.fromARGB(36, 92, 56, 200),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
    );
  }



  void _deleteGroup() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[800],
          title: Text('Delete Group', style: TextStyle(color: Colors.white)),
          content: Text(
            'Are you sure you want to delete "${widget.group['name']}"? This action cannot be undone.',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close edit page
                if (widget.onDeleteGroup != null) {
                  widget.onDeleteGroup!();
                }
                Navigator.of(context).pop(); // Close group detail page
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveChanges() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // 转换Friend对象回Map格式，确保当前用户被标记
      final membersData = _addedFriends.map((friend) {
        final isCurrentUser = friend.email == 'wayne_113@outlook.com' ||
                             friend.name.toLowerCase() == 'wayne';
        return {
          'name': friend.name,
          'email': friend.email,
          'isCurrentUser': isCurrentUser,
        };
      }).toList();

      final updatedGroup = Map<String, dynamic>.from(widget.group);
      updatedGroup['name'] = _groupNameController.text.trim();
      updatedGroup['members'] = membersData;

      // 先通知父组件更新UI
      if (widget.onUpdateGroup != null) {
        widget.onUpdateGroup!(updatedGroup);
      }

      // 然后保存到SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final groups = prefs.getStringList('groups') ?? [];

      // 找到并更新对应的group (使用name作为标识，因为可能没有id)
      final groupIndex = groups.indexWhere((groupStr) {
        final group = json.decode(groupStr);
        return group['name'] == widget.group['name']; // 使用原始名称查找
      });

      if (groupIndex != -1) {
        groups[groupIndex] = json.encode(updatedGroup);
        await prefs.setStringList('groups', groups);
      } else {
        // 如果找不到，可能是新group，直接添加
        groups.add(json.encode(updatedGroup));
        await prefs.setStringList('groups', groups);
      }

      // 检查widget是否还mounted
      if (mounted) {
        // 返回更新后的group数据
        Navigator.of(context).pop(updatedGroup);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
