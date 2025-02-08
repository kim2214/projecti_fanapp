import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StreamerCard extends StatelessWidget {
  const StreamerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        context.push('/detail');
      },
      child: Column(
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
