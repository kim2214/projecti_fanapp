import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:honeyz_fan_app/model/honeyz_model.dart';
import 'package:honeyz_fan_app/widget/components/streamer_card.dart';

class MainPageWidget extends StatefulWidget {
  const MainPageWidget({super.key});

  @override
  State<MainPageWidget> createState() => _MainPageWidgetState();
}

class _MainPageWidgetState extends State<MainPageWidget> {
  @override
  void initState() {
    super.initState();
    _fromFirestore();
  }

  Future<List<HoneyzModel>> _fromFirestore() async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;
    QuerySnapshot<Map<String, dynamic>> _snapshot =
    await _firestore.collection("honeyz").get();
    List<HoneyzModel> _result =
    _snapshot.docs.map((e) => HoneyzModel.fromJson(e.data())).toList();
    print(_result[0]);
    return _result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset('assets/honeyz_logo.png'),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 6,
            padding: EdgeInsets.all(5.0),
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 20.0),
                padding: EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFF5E88).withOpacity(0.8),
                      offset: Offset(0.0, 0.0),
                    )
                  ],
                  borderRadius: BorderRadius.all(
                    Radius.circular(10.0),
                  ),
                ),
                child: StreamerCard(
                  index: index,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
