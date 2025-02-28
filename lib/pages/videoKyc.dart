import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
class VideoKyc extends StatefulWidget {
  const VideoKyc({super.key});

  @override
  State<VideoKyc> createState() => _VideoKycState();
}

class _VideoKycState extends State<VideoKyc> {
  

  Future<void> startKyc() async {
    int randomNumber = Random().nextInt(100000); // Generates a number between 0 and 99999
    const String appId = "5u6sp3";
    const String appKey = "grg0k0jz09djas6afe72";
    const String workflowId = "customer_vkyc";
    String transactionId = "Uno-Fsa-$randomNumber";
    const String redirectUrl = "yourapp://kyc-result";
    String userName = "Sylvester Rajesh Mondal"; 

    final Uri url =
        Uri.parse('https://ind.idv.hyperverge.co/v1/link-kyc/start');

    final response = await http.post(
      url,
      headers: {
        'appId': appId,
        'appKey': appKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "workflowId": workflowId,
        "transactionId": transactionId,
        "redirectUrl": redirectUrl,
        "forceCreateLink": "yes",
        "inputs": {"name": userName},
      }),
    );
    print("Responce Body");
    print(response.body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final String? kycUrl = data['result']['startKycUrl']; 
        if (kycUrl != null) {
        Uri kycUri = Uri.parse(kycUrl);
        if (await canLaunchUrl(kycUri)) { // Use launchUrl
          await launchUrl(kycUri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch KYC URL';
        }
      }
    } else {
      throw 'Failed to initiate KYC';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Video KYC')),
      body: Center(
        child: ElevatedButton(
          onPressed: startKyc,
          child: const Text('Start Video KYC'),
        ),
      ),
    );
  }
}
