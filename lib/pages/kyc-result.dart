import 'package:flutter/material.dart';
class KycResultScreen extends StatelessWidget {
  final String? status;

  const KycResultScreen({Key? key, this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String message = status == 'approved'
        ? "Your KYC has been approved!"
        : status == 'rejected'
            ? "Your KYC was rejected. Please try again."
            : "KYC process is still in progress.";

    return Scaffold(
      appBar: AppBar(title: Text("KYC Status")),
      body: Center(child: Text(message)),
    );
  }
}
