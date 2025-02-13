import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hyperkyc_flutter/hyperkyc_flutter.dart';
import 'package:hyperkyc_flutter/hyperkyc_config.dart';
import 'package:hyperkyc_flutter/hyperkyc_result.dart';

class FaceRecognitionScreen extends StatefulWidget {
  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  bool _isProcessing = false;
  XFile? pickedFile; // Store the picked file

  // Function to browse and select an image
  Future<void> browseImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        pickedFile = file; // Store the file directly
      });
    } else {
      print('No image selected');
    }
  }

  // Function to trigger the face recognition process
  Future<void> startFaceRecognition() async {
    if (pickedFile == null) {
      _showMessage(
          "No image selected! Please select an image first.", Colors.red);
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final Map<String, String> customInputs = {
        'appId': '5u6sp3',
        'appKey': 'grg0k0jz09djas6afe72',
        'workflowId': 'selfie_onboarding',
        'transactionId': "unosag24",
        'inputSelfie': pickedFile!.path, // Send file path directly
      };

      var hyperKycConfig = HyperKycConfig.fromAppIdAppKey(
        appId: customInputs['appId']!,
        appKey: customInputs['appKey']!,
        workflowId: customInputs['workflowId']!,
        transactionId: customInputs['transactionId']!,
      );

      hyperKycConfig.setInputs(inputs: customInputs);

      HyperKycResult hyperKycResult =
          await HyperKyc.launch(hyperKycConfig: hyperKycConfig);
      print("result: $hyperKycResult");

      String? status = hyperKycResult.status?.value;
      switch (status) {
        case 'auto_approved':
          _showMessage("Verification Successful - Auto Approved", Colors.green);
        case 'auto_declined':
          _showMessage("Verification - Auto Declined", Colors.red);
        case 'needs_review':
          _showMessage("Verification - Need Review", Colors.red);
        case 'error':
          _showMessage("Error", Colors.red);
        case 'user_cancelled':
          _showMessage("Validation Cancled By User", Colors.red);
        default:
        _showMessage("Contact Support Team for more details", Colors.red);
      }
    } catch (e) {
      _showMessage("Error during verification. Please try again.", Colors.red);
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Helper function to show a message
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("HyperVerge Face Recognition")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isProcessing) CircularProgressIndicator(),
            if (!_isProcessing) ...[
              ElevatedButton(
                onPressed: browseImage,
                child: Text("Browse Image"),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: pickedFile == null
                    ? null
                    : startFaceRecognition, // Validate pickedFile
                child: Text("Start Face Recognition"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
