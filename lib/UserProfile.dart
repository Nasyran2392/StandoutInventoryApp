import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:standoutinventoryapplication/Homepage.dart';

class UserProfile extends StatelessWidget {
  final String userId;

  const UserProfile({Key? key, required this.userId}) : super(key: key);

  void navigateToUserProfile(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? ''; // Get current user ID
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserProfile(userId: userId)),
    );
  }

  void navigateToUserHomepage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => Homepage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text('No data found'),
            );
          }

          // Access user data from snapshot
          Map<String, dynamic> userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      _showImagePreviewDialog(context, userData['img']);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(userData['img']), // Assuming img is the URL of the profile picture
                            radius: 40,
                          ),
                          SizedBox(width: 16),
                          Text(
                            userData['displayName'],
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(),
                  ListTile(
                    title: Text(
                      'Country :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(userData['country'] ?? 'Not provided'),
                  ),
                  ListTile(
                    title: Text(
                      'Address :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(userData['address'] ?? 'Not provided'),
                  ),
                  ListTile(
                    title: Text(
                      'Email :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(userData['email'] ?? 'Not provided'),
                  ),
                  ListTile(
                    title: Text(
                      'Phone :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(userData['phone'] ?? 'Not provided'),
                  ),
                  ListTile(
                    title: Text(
                      'Username :',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(userData['username'] ?? 'Not provided'),
                  ),
                  ListTile(
                    title: Text(
                      'Account Created : ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(_formatTimestamp(userData['timeStamp'])),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Homepage',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          if (index == 0) {
            navigateToUserHomepage(context);
          // } else if (index == 1) {
          //   navigateToUserProfile(context);
          }
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.year}-${dateTime.month}-${dateTime.day}';
  }

  void _showImagePreviewDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(imageUrl),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
