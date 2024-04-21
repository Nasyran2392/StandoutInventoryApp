import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

class DeliveryItemsPage extends StatefulWidget {
  final String stockOutTaskId;

  DeliveryItemsPage({required this.stockOutTaskId});

  @override
  _DeliveryItemsPageState createState() => _DeliveryItemsPageState();
}

class _DeliveryItemsPageState extends State<DeliveryItemsPage> {
  late String _assignedClientId = '';
  late String _clientName = '';
  late String _clientAddress = '';
  late String _clientImg = '';
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchClientDetails();
  }

  Future<void> _fetchClientDetails() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> taskSnapshot =
          await FirebaseFirestore.instance
              .collection('StockOutTasks')
              .doc(widget.stockOutTaskId)
              .get();

      setState(() {
        _assignedClientId = taskSnapshot.data()!['assignedClientId'];
      });

      final DocumentSnapshot<Map<String, dynamic>> clientSnapshot =
          await FirebaseFirestore.instance.collection('client').doc(_assignedClientId).get();

      setState(() {
        _clientName = clientSnapshot.data()!['name'];
        _clientAddress = clientSnapshot.data()!['address'];
        _clientImg = clientSnapshot.data()!['img'];
      });
    } catch (e) {
      print('Error fetching client details: $e');
    }
  }

  Future<void> _pickImage() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.camera,
    ].request();
    if (statuses[Permission.storage]!.isGranted && statuses[Permission.camera]!.isGranted) {
      _showImagePicker(context);
    } else {
      print('no permission provided');
    }
  }

  Future<void> _imgFromGallery() async {
    final picker = ImagePicker();
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 50).then((value) {
      if (value != null) {
        _cropImage(File(value.path));
      }
    });
  }

  Future<void> _imgFromCamera() async {
    final picker = ImagePicker();
    await picker.pickImage(source: ImageSource.camera, imageQuality: 50).then((value) {
      if (value != null) {
        _cropImage(File(value.path));
      }
    });
  }

  Future<void> _cropImage(File imgFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imgFile.path,
      aspectRatioPresets: Platform.isAndroid
          ? [
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio16x9
            ]
          : [
              CropAspectRatioPreset.original,
              CropAspectRatioPreset.square,
              CropAspectRatioPreset.ratio3x2,
              CropAspectRatioPreset.ratio4x3,
              CropAspectRatioPreset.ratio5x3,
              CropAspectRatioPreset.ratio5x4,
              CropAspectRatioPreset.ratio7x5,
              CropAspectRatioPreset.ratio16x9
            ],
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: "Image Cropper",
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: "Image Cropper",
        )
      ],
    );
    if (croppedFile != null) {
      setState(() {
        _selectedImage = File(croppedFile.path);
      });
    }
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Card(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 5.2,
            margin: const EdgeInsets.only(top: 8.0),
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: InkWell(
                    child: Column(
                      children: const [
                        Icon(Icons.image, size: 60.0),
                        SizedBox(height: 12.0),
                        Text(
                          "Gallery",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.black),
                        )
                      ],
                    ),
                    onTap: () {
                      _imgFromGallery();
                      Navigator.pop(context);
                    },
                  ),
                ),
                Expanded(
                  child: InkWell(
                    child: SizedBox(
                      child: Column(
                                                  children: const [
                            Icon(Icons.camera_alt, size: 60.0),
                            SizedBox(height: 12.0),
                            Text(
                              "Camera",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: Colors.black),
                            )
                          ],
                        ),
                    ),
                    onTap: () {
                      _imgFromCamera();
                      Navigator.pop(context);
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _proceedWithTask() async {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmation"),
          content: Text("Are you sure to proceed this task?"),
                    actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Proceed"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Proceed with task logic
                _proceedTaskLogic();
              },
            ),
          ],
        );
      },
    );
  }

  // Method to handle the logic after confirming
  Future<void> _proceedTaskLogic() async {
    // Upload image to Firebase Storage
    if (_selectedImage != null) {
      try {
        final String imageName = 'orderImage_${DateTime.now().millisecondsSinceEpoch}';
        final firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance.ref('').child(imageName);
        final firebase_storage.UploadTask uploadTask = ref.putFile(_selectedImage!);
        final firebase_storage.TaskSnapshot downloadUrl = (await uploadTask);
        final String imageUrl = await downloadUrl.ref.getDownloadURL();

        // Update Firestore database with image reference and status
        await FirebaseFirestore.instance.collection('StockOutTasks').doc(widget.stockOutTaskId).update({
          'orderImage': imageUrl,
          'status': 'Waiting',
        });

        print('Image uploaded successfully: $imageUrl');

        // Send email to admin
        _sendEmail(imageUrl);

        // Navigate back to the previous page
        Navigator.of(context).pop();
      } catch (error) {
        print('Error uploading image: $error');
      }
    }
  }

  // Method to send email to admin
  void _sendEmail(String imageUrl) async {
    final logger = Logger();
    String email = "standoutinventory@gmail.com"; // Change this to the appropriate admin email address
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
          'image_url': imageUrl, // Pass the image URL to the template
        },
      }),
    );

    if (response.statusCode == 200) {
      logger.i('Email sent successfully');
    } else {
      logger.e('Failed to send email. Status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Items'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Side: Client Image
                _clientImg.isEmpty
                    ? SizedBox.shrink()
                    : InkWell(
                        onTap: () {
                          // Show a larger preview of the client image
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              content: Image.network(_clientImg),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(_clientImg),
                        ),
                      ),
                SizedBox(width: 20),
                // Right Side: Client Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Client Name:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _clientName,
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Client Address:',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _clientAddress,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom Card (Image Upload Section)
          Expanded(
            flex: 1, // Adjust the flex factor as needed
            child: SizedBox(
              width: double.infinity, // Make the card expand to the full width
              child: Card(
                margin: EdgeInsets.all(16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Upload Image',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Insert Delivery Order Page \n (with Client Chop and Signature)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13),
                      ),
                      SizedBox(height: 10),
                      _selectedImage == null
                          ? ElevatedButton(
                              onPressed: _pickImage,
                              child: Text('Select Image'),
                            )
                          : Image.file(_selectedImage!, width: 500, height: 300),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Proceed Button
          ElevatedButton(
            onPressed: _proceedWithTask,
            child: Text('Proceed'),
          ),
        ],
      ),
    );
  }
}

         
