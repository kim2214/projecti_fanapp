import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:honeyz_fan_app/model/honeyz_model.dart';
import 'package:honeyz_fan_app/widget/components/streamer_card.dart';

List<String> sequence = [
  "honeychurros",
  "ayauke",
  "damyui",
  "ddddragon",
  "ohwayo",
  "mangnae",
];

class HoneyzPageWidget extends StatefulWidget {
  const HoneyzPageWidget({super.key});

  @override
  State<HoneyzPageWidget> createState() => _HoneyzPageWidgetState();
}

class _HoneyzPageWidgetState extends State<HoneyzPageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
  }

  List<HoneyzModel> _result = [];

  Future<List<HoneyzModel>> _loadFirestore() async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;

    QuerySnapshot<Map<String, dynamic>> _snapshot =
        await _firestore.collection("honeyz").get();

    for (int i = 0; i < sequence.length; i++) {
      for (var snapshot in _snapshot.docs) {
        if (sequence[i] == snapshot.id) {
          _result.add(HoneyzModel.fromJson(snapshot.data()));
        }
      }
    }
    return _result;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
        future: _loadFirestore(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          //해당 부분은 data를 아직 받아 오지 못했을때 실행되는 부분
          if (snapshot.hasData == false) {
            return Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  backgroundColor: Color(0x0fff5e88).withOpacity(0.8),
                ),
              ),
            );
          }
          //error가 발생하게 될 경우 반환하게 되는 부분
          else if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(fontSize: 15),
              ),
            );
          }
          // 데이터를 정상적으로 받아오게 되면 다음 부분을 실행
          else {
            return Column(
              children: [
                Image.asset('assets/honeyz_logo.png'),
                Expanded(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _result.length,
                    padding: EdgeInsets.all(15.0),
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.symmetric(vertical: 20.0),
                        padding: EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0fff5e88).withOpacity(0.8),
                              offset: Offset(0.0, 0.0),
                            )
                          ],
                          borderRadius: BorderRadius.all(
                            Radius.circular(10.0),
                          ),
                        ),
                        child: StreamerCard(
                          index: index,
                          streamer: _result[index],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) => SizedBox(
                      height: 30.0,
                    ),
                  ),
                ),
              ],
            );
          }
        });
  }

  @override
  bool get wantKeepAlive => true;
}
