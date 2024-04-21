import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:standoutinventoryapplication/Homepage.dart';
import 'package:standoutinventoryapplication/StockInProgressPage.dart';
import 'package:standoutinventoryapplication/UserProfile.dart';

class StockInList extends StatefulWidget {
  const StockInList({Key? key}) : super(key: key);

  @override
  _StockInListState createState() => _StockInListState();
}

class _StockInListState extends State<StockInList> {
  String _selectedOption = 'New Task';
  late CollectionReference<Map<String, dynamic>> _stockInTasksCollection;
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _stockInTasksCollection = FirebaseFirestore.instance.collection('StockInTasks');
  }

  Future<void> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  void navigateToUserProfile(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? '';
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
        title: Text('Stock-In List'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Stock-In Task',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(height: 3.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedOption = 'New Task';
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                            return _selectedOption == 'New Task' ? Color.fromARGB(255, 241, 243, 244) : Colors.transparent;
                          }),
                        ),
                        child: Text('New Task'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedOption = 'Progression';
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                            return _selectedOption == 'Progression' ? Color.fromARGB(255, 241, 243, 244) : Colors.transparent;
                          }),
                        ),
                        child: Text('In-Progress'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedOption = 'Approval';
                          });
                        },
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                            return _selectedOption == 'Approval' ? Color.fromARGB(255, 241, 243, 244) : Colors.transparent;
                          }),
                        ),
                        child: Text('Approval'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildTaskListForOption(),
            ),
          ],
        ),
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
          }
          if (index == 1) {
            navigateToUserProfile(context);
          }
        },
      ),
    );
  }

  Widget _buildTaskListForOption() {
    switch (_selectedOption) {
      case 'New Task':
        return _buildNewTaskList();
      case 'Progression':
        return _buildProgressionList();
      case 'Approval':
        return _buildApprovalList();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildNewTaskList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stockInTasksCollection
          .where('assignedStorekeeperId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'Pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final taskDocs = snapshot.data!.docs;
          return Column(
            children: taskDocs.map((doc) {
              return _buildTaskCard(doc);
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildProgressionList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stockInTasksCollection
          .where('assignedStorekeeperId', isEqualTo: _currentUserId)
          .where('status', whereIn: ['Pick-Up', 'Store-In'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final taskDocs = snapshot.data!.docs;
          return Column(
            children: taskDocs.map((doc) {
              return _buildTaskCard(doc);
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildApprovalList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stockInTasksCollection
          .where('assignedStorekeeperId',
          isEqualTo: _currentUserId)
          .where('status', whereIn: ['Waiting', 'Approved', 'Rejected','Rejection Confirmed'])
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final taskDocs = snapshot.data!.docs;
          return Column(
            children: taskDocs.map((doc) {
              return _buildTaskCard(doc);
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildTaskCard(DocumentSnapshot<Map<String, dynamic>> doc) {
    final clientId = doc['assignedClientId'];
    final dueDate = doc['dueDate'];
    final status = doc['status'];
    final noOrder = doc['noOrder'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0),
      child: Card(
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance.collection('client').doc(clientId).get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return CircleAvatar(
                      child: Icon(Icons.error),
                    );
                  } else {
                    final imgUrl = snapshot.data!['img'];
                    return CircleAvatar(
                      backgroundImage: NetworkImage(imgUrl),
                    );
                  }
                },
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client: ${doc['assignedClientIdName']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Due Date: $dueDate'),
                    SizedBox(height: 8),
                    Text('Order No: $noOrder'),
                    SizedBox(height: 8),
                    Text('Status: $status'),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Task Details'),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                    future: FirebaseFirestore.instance.collection('client').doc(clientId).get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (snapshot.hasError) {
                                        return Text('Error: ${snapshot.error}');
                                      } else {
                                        final clientData = snapshot.data!.data();
                                        final name = clientData?['name'];
                                        final address = clientData?['address'];
                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Client: $name'),
                                            SizedBox(height: 8),
                                            Text('Address: $address'),
                                            SizedBox(height: 16),
                                            Text('Order No: $noOrder'),
                                            SizedBox(height: 8),
                                            Text('Due Date: $dueDate'),
                                            SizedBox(height: 8),
                                            Text('Status: $status'),
                                            SizedBox(height: 16),
                                            Text('Selected Products:'),
                                          ],
                                        );
                                      }
                                    },
                                  ),

                                  SizedBox(height: 16),
                                  Text('Selected Products:'),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      for (var product in doc['selectedProducts'])
                                        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                                          future: FirebaseFirestore.instance.collection('inventory').doc(product['productId']).get(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return CircularProgressIndicator();
                                            } else if (snapshot.hasError) {
                                              return Text('Error: ${snapshot.error}');
                                            } else {
                                              final productName = snapshot.data!['productName'];
                                              return Text('- Product Name: $productName, Quantity: ${product['quantity']}');
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Close'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Text('View'),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StockInProgressPage(
                            stockInTaskId: doc.id,
                          ),
                        ),
                      );
                    },
                    child: Text('Proceed'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

