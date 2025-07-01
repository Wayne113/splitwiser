import 'package:flutter/material.dart';
import 'add_friends_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FriendsManager {
  static Future<List<Friend>> loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final savedFriends = prefs.getStringList('friends') ?? [];
      return savedFriends
          .map((friendStr) => Friend.fromJson(json.decode(friendStr)))
          .toList();
    } catch (e) {
      await prefs.remove('friends');
      return [];
    }
  }

  static Future<void> saveFriend(Friend friend) async {
    final prefs = await SharedPreferences.getInstance();
    final friends = await loadFriends();

    // Check friend email exists or not
    if (!friends.any((f) => f.email == friend.email)) {
      friends.add(friend);
      final friendsJson = friends.map((f) => json.encode(f.toJson())).toList();
      await prefs.setStringList('friends', friendsJson);
    }
  }

  static Future<void> deleteFriend(Friend friend) async {
    final prefs = await SharedPreferences.getInstance();
    final friends = await loadFriends();

    // Remove friend from friends list only
    friends.removeWhere((f) => f.email == friend.email);
    final friendsJson = friends.map((f) => json.encode(f.toJson())).toList();
    await prefs.setStringList('friends', friendsJson);
  }
}

class FriendsPage extends StatefulWidget {
  final List<Friend> selectedFriends;
  final bool showDeleteButtons;

  const FriendsPage({
    Key? key,
    this.selectedFriends = const [],
    this.showDeleteButtons = true,
  }) : super(key: key);

  @override
  _FriendsPageState createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Friend> _allFriends = [];
  List<Friend> _selectedFriends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh friends list when returning from other pages
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final friends = await FriendsManager.loadFriends();
    setState(() {
      _allFriends = friends;

      // Filter selectedFriends to only include friends that still exist
      _selectedFriends = widget.selectedFriends.where((selectedFriend) {
        return friends.any((friend) => friend.email == selectedFriend.email);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends', style: TextStyle(color: Colors.white70)),
        backgroundColor: const Color.fromARGB(255, 39, 39, 40),
        iconTheme: const IconThemeData(color: Colors.white70),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, _selectedFriends);
          },
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 39, 39, 40),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newFriend = await Navigator.push<Friend>(
            context,
            MaterialPageRoute(builder: (context) => const AddFriendsPage()),
          );
          if (newFriend != null) {
            await FriendsManager.saveFriend(newFriend);

            await _loadFriends();
          }
        },
        backgroundColor: Color.fromARGB(164, 92, 56, 200),
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _allFriends.isEmpty
          ? Center(
              child: Text(
                'No friends yet. Add some!',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView.builder(
                itemCount: _allFriends.length,
                itemBuilder: (context, index) {
                  final friend = _allFriends[index];
                  final isSelected = _selectedFriends.contains(friend);

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedFriends.remove(friend);
                        } else {
                          if (!_selectedFriends.contains(friend)) {
                            _selectedFriends.add(friend);
                          }
                        }
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 37, 37, 39),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.deepPurple : Colors.grey,
                          width: isSelected ? 2.0 : 1.0,
                        ),
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
                          // Red delete button in top-right corner (only show if enabled)
                          if (widget.showDeleteButtons)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                              onTap: () async {
                                // Show confirmation dialog
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: Color.fromARGB(255, 37, 37, 39),
                                      title: Text(
                                        'Delete Friend',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      content: Text(
                                        'Are you sure you want to remove ${friend.name} from your friends list?',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(false),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(color: Colors.white70),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(true),
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (shouldDelete == true) {
                                  // Remove from selected friends if selected
                                  setState(() {
                                    _selectedFriends.remove(friend);
                                  });

                                  // Delete from storage
                                  await FriendsManager.deleteFriend(friend);

                                  // Reload friends list
                                  await _loadFriends();

                                  // Show success message
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${friend.name} removed from friends'),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.red[300],
                                  shape: BoxShape.circle,
                                ),
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
                    ),
                  );
                },
              ),
            ),
    );
  }
}
