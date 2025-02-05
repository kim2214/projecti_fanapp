import 'package:flutter/material.dart';

class StreamerCard extends StatelessWidget {
  const StreamerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/damyui_profile.png'),
        SizedBox(
          height: 20,
        ),
        Text('담유이'),
      ],
    );
  }
}
