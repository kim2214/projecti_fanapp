import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:honeyz_fan_app/model/honeyz_model.dart';

class StreamerDetail extends StatelessWidget {
  final HoneyzModel honeyz;

  const StreamerDetail({super.key, required this.honeyz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        scrolledUnderElevation: 0.0,
        leading: BackButton(
          onPressed: () {
            context.pop();
          },
        ),
        backgroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          children: [
            Image.asset('assets/${honeyz.profileName}_profile.png'),
            SizedBox(
              height: 20,
            ),
            Text(honeyz.name!),
          ],
        ),
      ),
    );
  }
}
