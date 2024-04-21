import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class PackingItemsPage extends StatefulWidget {
  final String stockOutTaskId;

  PackingItemsPage({required this.stockOutTaskId});

  @override
  _PackingItemsPageState createState() => _PackingItemsPageState();
}

class _PackingItemsPageState extends State<PackingItemsPage> {
  List<bool> isConfirmedList = [];
  bool isAllConfirmed = false; // Track if all items are confirmed

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Packing Items'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('StockOutTasks').doc(widget.stockOutTaskId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          } else {
            final selectedProducts = snapshot.data!.data()!['selectedProducts'];
            if (isConfirmedList.isEmpty) {
              isConfirmedList = List.generate(selectedProducts.length, (_) => false);
            }
            return ListView.builder(
              itemCount: selectedProducts.length,
              itemBuilder: (context, index) {
                final productId = selectedProducts[index]['productId'];
                final quantityInventory = selectedProducts[index]['quantity'];
                return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  future: FirebaseFirestore.instance.collection('inventory').doc(productId).get(),
                  builder: (context, productSnapshot) {
                    if (productSnapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (productSnapshot.hasError) {
                      return Text('Error: ${productSnapshot.error}');
                    } else if (!productSnapshot.hasData) {
                      return Text('Product not found');
                    } else {
                      final productData = productSnapshot.data!.data()!;
                      final productName = productData['productName'];
                      final quantity = productData['quantity'];
                      final img = productData['img'];
                      final shelfLocation = productData['shelfLocation'];
                      final description = productData['description'];
                      final category = productData['category'];

                      return Card(
                        child: ListTile(
                          leading: Image.network(
                            img,
                            width: 50,
                          ),
                          title: Text(
                            'Product: $productName',
                            style: TextStyle(fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantity: $quantity',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Shelf Location: $shelfLocation',
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Quantity Request: $quantityInventory',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Product Details'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Image.network(
                                              img,
                                              width: 500,
                                            ),
                                            SizedBox(height: 20),
                                            Text('Product ID: $productId'),
                                            Text('Product Name: $productName'),
                                            Text('Quantity: $quantity'),
                                            Text('Description: $description'),
                                            Text('Category: $category'),
                                            Text('Shelf Location: $shelfLocation'),
                                            Text('Quantity Requested: $quantityInventory'),
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
                                },
                                style: ButtonStyle(
                                  backgroundColor: MaterialStateProperty.all<Color>(Color.fromARGB(255, 239, 241, 187)),
                                  padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                                ),
                                child: Text(
                                  'View',
                                  style: TextStyle(fontSize: 14, color: Colors.black),
                                ),
                              ),
                              SizedBox(width: 8),
                              TextButton(
                                onPressed: isConfirmedList[index] ? null : () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Confirm Quantity'),
                                        content: Text('Is the quantity enough for the client request?'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                isConfirmedList[index] = true;
                                              });
                                              checkAllConfirmed();
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('Yes'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Text('No'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: ButtonStyle(
                                  backgroundColor: isConfirmedList[index] ? MaterialStateProperty.all<Color>(Colors.green) : MaterialStateProperty.all<Color>(Color.fromARGB(255, 165, 183, 190)),
                                  padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.symmetric(horizontal: 10, vertical: 5)),
                                ),
                                child: Text(
                                  'Confirm',
                                  style: TextStyle(fontSize: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: isAllConfirmed ? FloatingActionButton.extended(
        onPressed: () {
          // Show confirmation dialog before proceeding
          _changeStatusToDelivery(context);
          _sendEmail();
        },
        label: Text('Proceed'),
        backgroundColor: Color.fromARGB(255, 37, 170, 236),
      ) : null,
    );
  }

  void checkAllConfirmed() {
    // Check if all items are confirmed and setState to update UI
    bool allConfirmed = true;
    for (bool confirmed in isConfirmedList) {
      if (!confirmed) {
        allConfirmed = false;
        break;
      }
    }
    setState(() {
      isAllConfirmed = allConfirmed;
    });
  }

  void _changeStatusToDelivery(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm?'),
          content: Text('Are you sure you want to proceed this packing task?'),
          actions: <Widget>[
            TextButton(
              onPressed: () async {
                try {
                  // Update the status attribute to "Delivery" in Firestore
                  await FirebaseFirestore.instance.collection('StockOutTasks').doc(widget.stockOutTaskId).update({
                    'status': 'Delivery',
                  });
                  // Navigate back to the previous page
                  Navigator.of(context).pop(); // Pop the confirmation dialog
                  Navigator.of(context).pop(); // Pop the packing items page
                } catch (e) {
                  // Handle errors
                  print('Error updating status: $e');
                }
                              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Pop the confirmation dialog
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );
  }

  void _sendEmail() async {
    final logger = Logger();
    String email = "standoutinventory@gmail.com"; // Change this to the appropriate recipient email address
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final taskSnapshot = await FirebaseFirestore.instance
        .collection('StockOutTasks')
        .doc(widget.stockOutTaskId)
        .get();

    final status = taskSnapshot.data()!['status'];
    final noOrder = taskSnapshot.data()!['noOrder'];
    final dueDate = taskSnapshot.data()!['dueDate'];
    final assignedClientId = taskSnapshot.data()!['assignedClientId'];
    final assignedStorekeeperId = taskSnapshot.data()!['assignedStorekeeperId'];

    // Fetch client details using assignedClientId
    final clientSnapshot = await FirebaseFirestore.instance
        .collection('client')
        .doc(assignedClientId)
        .get();

    final clientName = clientSnapshot.data()!['name'];
    final clientAddress = clientSnapshot.data()!['address'];

    // Fetch user details using assignedClientId
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(assignedStorekeeperId)
        .get();

    final displayName = userSnapshot.data()!['displayName'];

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        // Add your EmailJS user ID here
        'Authorization': 'aemImAt97yfG8FOEK',
      },
      body: json.encode({
        'service_id': 'service_xhuz367',
        'template_id': 'template_jbnfjla',
        'user_id': 'aemImAt97yfG8FOEK',
        'template_params': {
          'to_email': email,
          'status': status,
          'to_numberOrder': noOrder,
          'dueDate': dueDate,
          'to_client': clientName,
          'to_address': clientAddress,
          'to_name': displayName,
          // Add other parameters as required by your EmailJS template
        },
      }),
    );

    if (response.statusCode == 200) {
      logger.d('Email sent successfully');
    } else {
      logger.e('Failed to send email: ${response.statusCode}');
    }
  }
}

