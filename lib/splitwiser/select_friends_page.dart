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

class SelectFriendsPage extends StatefulWidget {
  final List<Friend> selectedFriends;
  
  const SelectFriendsPage({
    Key? key, 
    this.selectedFriends = const [],
  }) : super(key: key);

  @override
  _SelectFriendsPageState createState() => _SelectFriendsPageState();
}

class _SelectFriendsPageState extends State<SelectFriendsPage> {
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
          'Select Friends',
          style: TextStyle(color: Colors.white70),
        ),
        backgroundColor: const Color.fromARGB(255, 39, 39, 40),
        iconTheme: const IconThemeData(color: Colors.white70),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, _selectedFriends);
            },
            child: Text(
              'Done',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
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
          : ListView.builder(
              itemCount: _allFriends.length,
              itemBuilder: (context, index) {
                final friend = _allFriends[index];
                final isSelected = _selectedFriends.contains(friend);
                
                return ListTile(
                  title: Text(
                    friend.name,
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    friend.email,
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              if (!_selectedFriends.contains(friend)) {
                                _selectedFriends.add(friend);
                              }
                            } else {
                              _selectedFriends.remove(friend);
                            }
                          });
                        },
                        fillColor: WidgetStateProperty.resolveWith(
                          (states) => Color.fromARGB(162, 212, 200, 200),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete,
                          color: Colors.red[300],
                        ),
                        onPressed: () async {
                          final shouldDelete = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: Color.fromARGB(255, 39, 39, 40),
                              title: Text(
                                'Delete Friend',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: Text(
                                'Are you sure you want to delete ${friend.name}?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(
                                    'Cancel',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red[300]),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (shouldDelete == true) {
                            _selectedFriends.remove(friend);

                            await FriendsManager.deleteFriend(friend);

                            await _loadFriends();
                          }
                        },
                      ),
                    ],
                  ),
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
                );
              },
            ),
    );
  }
}