import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StreamerDetail extends StatelessWidget {
  const StreamerDetail({super.key});

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
      body: Column(
        children: [
          Image.asset('assets/damyui_profile.png'),
          SizedBox(
            height: 20,
          ),
          Text('담유이'),
        ],
      ),
    );
  }
}
