import 'package:flutter/material.dart';
import 'package:flutter_shield_example/app_password.dart';
import 'package:flutter_shield_example/generate_cert.dart';
import 'package:flutter_shield_example/signature_verify.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppGenerateCert(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 100,
                    child: Center(
                      child: Text('Generate Cert'),
                    ),
                  ),
                ),
              ),
            ),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppPassword(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 100,
                    child: Center(
                      child: Text('Encrypt & Decrypt'),
                    ),
                  ),
                ),
              ),
            ),
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(5),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignatureVerify(),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 100,
                    child: Center(
                      child: Text('Signature & verify'),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
