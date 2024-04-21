import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:standoutinventoryapplication/StockInList.dart';
import 'package:standoutinventoryapplication/StockOutList.dart';
import 'package:standoutinventoryapplication/UserProfile.dart';
import 'package:rxdart/rxdart.dart';

class Homepage extends StatelessWidget {
  const Homepage({Key? key}) : super(key: key);

  void signInOut() {
    FirebaseAuth.instance.signOut();
  }

  void navigateToStockOutList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StockOutList()),
    );
  }

  void navigateToStockInList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StockInList()),
    );
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

  void _showSignOutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sign Out Now'),
          content: Text('Are you sure you want to sign out?'),
          actions: <Widget>[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.red,
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('No', style: TextStyle(color: Colors.white)),
              ),
            ),
            SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.green,
              ),
              child: TextButton(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                  Navigator.of(context).pop();
                },
                child: Text('Yes', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String> getUserDisplayName() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final docSnapshot = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    return docSnapshot.get('displayName');
  }

  Stream<List<DataRow>> getSynchronizedRowsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserId = currentUser!.uid;

    final stockInTasksQuery = FirebaseFirestore.instance
        .collection('StockInTasks')
        .where('assignedStorekeeperId', isEqualTo: currentUserId)
        .where('status', whereIn: ['Pending', 'Pick-Up', 'Store-In'])
        .snapshots(); // Use snapshots() to get real-time updates

    final stockOutTasksQuery = FirebaseFirestore.instance
        .collection('StockOutTasks')
        .where('assignedStorekeeperId', isEqualTo: currentUserId)
        .where('status', whereIn: ['Pending', 'Packing', 'Delivery'])
        .snapshots(); // Use snapshots() to get real-time updates

    return Rx.combineLatest2(stockInTasksQuery, stockOutTasksQuery, (stockInSnapshot, stockOutSnapshot) {
      final stockInTasksRows = stockInSnapshot.docs.map((doc) {
        return DataRow(
          cells: [
            DataCell(Text('Stock-In')),
            DataCell(Text(doc['dueDate'])),
            DataCell(Text(doc['status'])),
          ],
        );
      }).toList();

      final stockOutTasksRows = stockOutSnapshot.docs.map((doc) {
        return DataRow(
          cells: [
            DataCell(Text('Stock-Out')),
            DataCell(Text(doc['dueDate'])),
            DataCell(Text(doc['status'])),
          ],
        );
      }).toList();

      return [...stockInTasksRows, ...stockOutTasksRows];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              _showSignOutConfirmationDialog(context);
            },
            icon: Icon(Icons.logout),
          ),
        ],
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color.fromARGB(255, 223, 153, 235), width: 3.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Standout Inventory",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                FutureBuilder<String>(
                  future: getUserDisplayName(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (snapshot.hasData) {
                      return Text(
                        "Welcome, ${snapshot.data}",
                        style: TextStyle(fontSize: 18,color: Color.fromARGB(255, 0, 0, 0)),
                      );
                    } else {
                      return Text(
                        "Welcome",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 16.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Card(
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset("images/stockin.png", width: 200, height: 120),
                              SizedBox(height: 16.0),
                              StreamBuilder<List<DataRow>>(
                                stream: getSynchronizedRowsStream(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }
                                  if (snapshot.hasData) {
                                    int stockInPendingCount = snapshot.data!
                                        .where((row) =>
                                    (row.cells[0].child.toString().contains('Stock-In') &&
                                        (row.cells[2].child.toString().contains('Pending') ||
                                            row.cells[2].child.toString().contains('Pick-Up') ||
                                            row.cells[2].child.toString().contains('Store-In')))
                                    )
                                        .length;
                                    return Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(left: 8.0), // Adjust the padding value as needed
                                    child: Text("Stock-In : ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "$stockInPendingCount",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              );
                                  }
                                  return Text('Stock-In', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
                                },
                              ),
                              SizedBox(height: 8.0),
                              ElevatedButton(
                                onPressed: () {
                                  navigateToStockInList(context);
                                },
                                child: Text("Stock-In", style: TextStyle(fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16.0),
                  Expanded(
                    child: Padding(
  padding: const EdgeInsets.all(2.0                      ),
                      child: Card(
                        elevation: 5,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset("images/stockout.png", width: 200, height: 120),
                              SizedBox(height: 16.0),
                              StreamBuilder<List<DataRow>>(
                                stream: getSynchronizedRowsStream(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }
                                  if (snapshot.hasData) {
                                    int stockOutPendingCount = snapshot.data!
                                        .where((row) =>
                                    (row.cells[0].child.toString().contains('Stock-Out') &&
                                        (row.cells[2].child.toString().contains('Pending') ||
                                            row.cells[2].child.toString().contains('Packing') ||
                                            row.cells[2].child.toString().contains('Delivery')))
                                    )
                                        .length;
                                    return Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(left: 8.0), // Adjust the padding value as needed
                                    child: Text("Stock-Out : ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  ),
                                  Container(
                                    padding: EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      "$stockOutPendingCount",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              );


                                  }
                                  return Text('Stock-Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
                                },
                              ),
                              SizedBox(height: 8.0),
                              GestureDetector(
                                child: ElevatedButton(
                                  onPressed: () {
                                    navigateToStockOutList(context);
                                  },
                                  child: Text("Stock-Out", style: TextStyle(fontSize: 16)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.0),
            SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text("New Tasks Assign",textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,)),
            ),
            SizedBox(height: 20.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: StreamBuilder<List<DataRow>>(
                  stream: getSynchronizedRowsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }
                    if (snapshot.hasData) {
                      return DataTable(
                        columns: [
                          DataColumn(label: Text("Task")),
                          DataColumn(label: Text("Due Date")),
                          DataColumn(label: Text("Status")),
                        ],
                        rows: snapshot.data!,
                      );
                    }
                    return Text('No data available');
                  },
                ),
              ),
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
          if (index == 1) {
            navigateToUserHomepage(context); // Navigate to UserProfile when Homepage button is tapped
          }
          if (index == 1) {
            navigateToUserProfile(context); // Navigate to UserProfile when Profile button is tapped
          }
        },
      ),
    );
  }
}

