import 'package:flutter/material.dart';
import 'package:splitwiser/splitwiser/add_friends_page.dart';
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

    // Check fren email exists or not
    if (!friends.any((f) => f.email == friend.email)) {
      friends.add(friend);
      final friendsJson = friends.map((f) => json.encode(f.toJson())).toList();
      await prefs.setStringList('friends', friendsJson);
    }
  }

  static Future<void> deleteFriend(Friend friend) async {
    final prefs = await SharedPreferences.getInstance();
    final friends = await loadFriends();

    // Remove friend email
    friends.removeWhere((f) => f.email == friend.email);
    final friendsJson = friends.map((f) => json.encode(f.toJson())).toList();
    await prefs.setStringList('friends', friendsJson);
  }
}

class FriendsPage extends StatefulWidget {
  final List<Friend> selectedFriends;

  const FriendsPage({
    Key? key,
    this.selectedFriends = const [],
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
    _selectedFriends = List.from(widget.selectedFriends);
  }
  
  Future<void> _loadFriends() async {
    final friends = await FriendsManager.loadFriends();
    setState(() {
      _allFriends = friends;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Friends',
          style: TextStyle(color: Colors.white70),
        ),
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
            MaterialPageRoute(
              builder: (context) => const AddFriendsPage(),
            ),
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
                      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 37, 37, 39),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? Colors.deepPurple : Colors.grey,
                          width: isSelected ? 2.0 : 1.0,
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
                  ),
                );
                },
              ),
            ),
    );
  }
}
