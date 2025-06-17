import 'package:flutter/material.dart';
import 'package:splitwiser/splitwiser/add_friends_page.dart';

class Group {
  final String name;
  final List<Friend> members;

  Group({required this.name, required this.members});
}

class AddNewGroupPage extends StatefulWidget {
  const AddNewGroupPage({Key? key}) : super(key: key);

  @override
  State<AddNewGroupPage> createState() => _AddNewGroupPageState();
}

class _AddNewGroupPageState extends State<AddNewGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  List<Friend> _addedFriends = []; // List to store added friends

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
        title: const Text('Create Group', style: TextStyle(color: Colors.white70)),
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
                  borderSide: BorderSide(
                    color: Colors.deepPurple,
                    width: 2,
                  ),
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
              onTap: () async { // Made onTap async
                final newFriend = await Navigator.push<Friend>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddFriendsPage(),
                  ),
                );
                if (newFriend != null) {
                  setState(() {
                    _addedFriends.add(newFriend);
                  });
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: 0, // Reduced vertical padding
                  horizontal: 5,
                ),
                // Removed decoration
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
            SizedBox(height: 24), // Spacing between Add Members and friend list
            // Display added friends
            if (_addedFriends.isNotEmpty) // Only show if there are friends
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch to full width
                children: _addedFriends.map((friend) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20), // Matched TextField contentPadding
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 37, 37, 39),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey, // Matched TextField enabledBorder color
                        width: 1.0,
                      ),
                    ),
                    child: Column(
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
                        SizedBox(height: 4), // Spacing between name and email
                        Text(
                          friend.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            Spacer(), // Added Spacer to push button to bottom
            SizedBox(
              width: double.infinity, // Make it full width
              child: ElevatedButton(
                onPressed: _isFormValid() ? () {
                  final newGroup = Group(
                    name: _groupNameController.text,
                    members: _addedFriends,
                  );
                  Navigator.pop(context, newGroup);
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(164, 92, 56, 200),
                  disabledBackgroundColor: Color.fromARGB(36, 92, 56, 200),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16), // Consistent padding
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