import 'package:flutter/material.dart';
import 'package:splitwiser/splitwiser/add_friends_page.dart';
import 'package:splitwiser/splitwiser/friends_page.dart';
import 'package:splitwiser/splitwiser/profile_page.dart';

class Group {
  final String name;
  final List<Friend> members;

  Group({required this.name, required this.members});

  Future<Map<String, dynamic>> toJson() async {
    // Get current user profile
    final userProfile = await ProfileManager.loadProfile();

    // Create a list that includes the current user plus selected friends
    final allMembers = <Map<String, dynamic>>[];

    // Add current user first
    if (userProfile != null) {
      allMembers.add({
        'name': userProfile.name,
        'email': userProfile.email,
        'isCurrentUser': true,
      });
    } else {
      // Fallback if no profile is set
      allMembers.add({
        'name': 'You',
        'email': 'you@example.com',
        'isCurrentUser': true,
      });
    }

    // Add selected friends
    allMembers.addAll(members.map((m) => {
      ...m.toJson(),
      'isCurrentUser': false,
    }));

    return {
      'name': name,
      'members': allMembers,
      'date': DateTime.now().toString().split(' ')[0],
      'total': 0.0,
      'details': <Map<String, dynamic>>[],
      'status': {'text': 'No expenses yet', 'color': 0xFFE8F5E8, 'amount': null},
    };
  }

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      name: json['name'],
      members: (json['members'] as List)
          .map((m) => Friend.fromJson(m))
          .toList(),
    );
  }
}

class AddNewGroupPage extends StatefulWidget {
  const AddNewGroupPage({Key? key}) : super(key: key);

  @override
  State<AddNewGroupPage> createState() => _AddNewGroupPageState();
}

class _AddNewGroupPageState extends State<AddNewGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  List<Friend> _addedFriends = [];

  bool _isFormValid() {
    return _groupNameController.text.isNotEmpty;
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Group',
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
              onChanged: (value) => setState(() {}),
              decoration: InputDecoration(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Group name', style: TextStyle(color: Colors.white)),
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
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
              ),
              style: TextStyle(fontSize: 16, color: Colors.white),
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
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 37, 37, 39),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey, width: 1.0),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              friend.name,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid()
                    ? () async {
                        final newGroup = Group(
                          name: _groupNameController.text,
                          members: _addedFriends,
                        );
                        Navigator.pop(context, newGroup);
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
                  'Create',
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
      ),
    );
  }
}
