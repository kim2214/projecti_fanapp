import 'package:flutter/material.dart';

import '../screen_base_widget.dart';

class StreamerDetail extends StatelessWidget {
  const StreamerDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenBaseWidget(
      widget: Column(
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
