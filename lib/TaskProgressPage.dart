import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:standoutinventoryapplication/DeliveryItemsPage.dart';
import 'package:standoutinventoryapplication/PackingItemsPage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';


class TaskProgressPage extends StatefulWidget {
  final String stockOutTaskId;

  TaskProgressPage({required this.stockOutTaskId});

  @override
  _TaskProgressPageState createState() => _TaskProgressPageState();
}

class _TaskProgressPageState extends State<TaskProgressPage> {
  late String _currentStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task Progress'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Stepper for Status Progress
          Expanded(
            flex: 2,
            child: _buildTimelineStepper(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStepper() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('StockOutTasks')
          .doc(widget.stockOutTaskId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          final status = snapshot.data!.data()!['status'];
          _currentStatus = status;
          return Column(
            children: [
              Expanded(
                flex: 2,
                child: Stepper(
                  currentStep: _getStepIndex(status),
                  onStepContinue: _handleStepContinue,
                  // Remove the onStepCancel property to hide cancel buttons
                  steps: [
                    _buildStep('Pending', status),
                    _buildStep('Packing', status),
                    _buildStep('Delivery', status),
                    _buildStep('Waiting', status),
                    _buildStep('Approved', status),
                  ],
                ),
              ),
              if (_currentStatus == 'Packing' || _currentStatus == 'Delivery')
                ElevatedButton(
                  onPressed: () {
                    _rejectTask();
                  },
                  child: Text('Reject Task'),
                ),
            ],
          );
        }
      },
    );
  }

  Step _buildStep(String stepTitle, String currentStatus) {
    return Step(
      title: Text(stepTitle),
      isActive: currentStatus == stepTitle || _isStepCompleted(currentStatus, stepTitle),
      state: _getState(currentStatus, stepTitle),
      content: SizedBox.shrink(),
    );
  }

  int _getStepIndex(String status) {
    switch (status) {
      case 'Pending':
        return 0;
      case 'Packing':
        return 1;
      case 'Delivery':
        return 2;
      case 'Waiting':
        return 3;
      case 'Approved':
        return 4;
      default:
        return 0;
    }
  }

  bool _isStepCompleted(String currentStatus, String stepStatus) {
    final stepIndex = _getStepIndex(stepStatus);
    final currentIndex = _getStepIndex(currentStatus);
    return stepIndex < currentIndex;
  }

  StepState _getState(String currentStatus, String stepStatus) {
    if (_isStepCompleted(currentStatus, stepStatus)) {
      return StepState.complete;
    } else if (currentStatus == stepStatus) {
      return StepState.editing;
    } else {
      return StepState.disabled;
    }
  }

  void _handleStepContinue() {
    if (_currentStatus == 'Pending') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirmation"),
            content: Text("Are you sure to proceed with this task?"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _proceedWithTask();
                },
                child: Text("Confirm"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
            ],
          );
        },
      );
    } else if (_currentStatus == 'Waiting') {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Wait Approval"),
            content: Text("Wait Approval from admin to approve this task"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    } else if (_currentStatus == 'Packing') {
      // Navigate to PackingItemsPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PackingItemsPage(stockOutTaskId: widget.stockOutTaskId),
        ),
      );
    } else if (_currentStatus == 'Delivery') {
      // Navigate to DeliveryItemsPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryItemsPage(stockOutTaskId: widget.stockOutTaskId),
        ),
      );
    } else {
      _proceedWithTask();
    }
  }

  void _proceedWithTask() async {
    setState(() {
      switch (_currentStatus) {
        case 'Pending':
          _currentStatus = 'Packing';
          break;
        case 'Packing':
          _currentStatus = 'Delivery';
          break;
        case 'Delivery':
          _currentStatus = 'Waiting';
          break;
        case 'Waiting':
          _currentStatus = 'Approved';
          break;
        default:
          break;
      }
    });
    if (_currentStatus == 'Packing') {
      // Send email when the status changes to "Packing"
      _sendEmail();
    }
    _updateStatus(_currentStatus);
  }

  Future _sendEmail() async {
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
        'to_name' : displayName,
        // Add other parameters as required by your EmailJS template
      },
    }),
  );

  logger.d(response.body);
}


  void _updateStatus(String status, {String? rejectedDetails}) {
    Map<String, dynamic> updateData = {'status': status};
    if (rejectedDetails != null) {
      updateData['rejectedDetails'] = rejectedDetails;
    }
    FirebaseFirestore.instance.collection('StockOutTasks').doc(widget.stockOutTaskId).update(updateData);
  }

  void _rejectTask() async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String selectedReason = '';
      String customReason = '';

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text("Reason for Rejection"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedReason.isEmpty ? null : selectedReason,
                  onChanged: (String? value) {
                    setState(() {
                      selectedReason = value!;
                    });
                  },
                  items: [
                    DropdownMenuItem(
                      value: 'Items not available',
                      child: Text('Items not available'),
                    ),
                    DropdownMenuItem(
                      value: 'Insufficient Items',
                      child: Text('Insufficient Items'),
                    ),
                    DropdownMenuItem(
                      value: 'Others',
                      child: Text('Others'),
                    ),
                  ],
                ),
                if (selectedReason == 'Others')
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Custom Reason'),
                    onChanged: (value) {
                      customReason = value;
                    },
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  String finalReason = selectedReason == 'Others' ? customReason : selectedReason;
                  await _addBackToInventory(finalReason);
                  _updateStatus('Rejected', rejectedDetails: finalReason);
                  Navigator.of(context).pop();

                  // Send email after updating status
                  await _sendEmail();
                },
                child: Text("Reject"),
              ),
            ],
          );
        },
      );
    },
  );
}


  Future<void> _addBackToInventory(String rejectionReason) async {
    final DocumentSnapshot<Map<String, dynamic>> taskSnapshot =
        await FirebaseFirestore.instance.collection('StockOutTasks').doc(widget.stockOutTaskId).get();
    final List<dynamic> selectedProducts = taskSnapshot.data()!['selectedProducts'];
    selectedProducts.forEach((product) async {
      final String productId = product['productId'];
      final int quantity = product['quantity'];

      final DocumentSnapshot<Map<String, dynamic>> productSnapshot =
          await FirebaseFirestore.instance.collection('inventory').doc(productId).get();
      final int currentQuantity = productSnapshot.data()!['quantity'];
      final int updatedQuantity = currentQuantity + quantity;

      await FirebaseFirestore.instance.collection('inventory').doc(productId).update({'quantity': updatedQuantity});
    });
  }
}
