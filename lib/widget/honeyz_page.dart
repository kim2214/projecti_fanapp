import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:honeyz_fan_app/model/streamer_model.dart';
import 'package:honeyz_fan_app/model/live_check_model.dart';
import 'package:honeyz_fan_app/widget/components/streamer_card.dart';
import 'package:http/http.dart' as http;

List<String> sequence = [
  "honeychurros",
  "ayauke",
  "damyui",
  "ddddragon",
  "ohwayo",
  "mangnae",
];

List<String> brodcastIDList = [
  "c0d9723cbb75dc223c6aa8a9d4f56002",
  "abe8aa82baf3d3ef54ad8468ee73e7fc",
  "b82e8bc2505e37156b2d1140ba1fc05c",
  "798e100206987b59805cfb75f927e965",
  "65a53076fe1a39636082dd6dba8b8a4b",
  "bd07973b6021d72512240c01a386d5c9",
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

  List<StreamerModel> _result = [];
  List<LiveCheckModel> _liveCheckResult = [];

  Future<List<StreamerModel>> _loadFirestore() async {
    await _liveCheck();

    FirebaseFirestore _firestore = FirebaseFirestore.instance;

    QuerySnapshot<Map<String, dynamic>> _snapshot =
        await _firestore.collection("honeyz").get();

    for (int i = 0; i < sequence.length; i++) {
      for (var snapshot in _snapshot.docs) {
        if (sequence[i] == snapshot.id) {
          _result.add(StreamerModel.fromJson(snapshot.data()));
        }
      }
    }
    return _result;
  }

  Future<List<LiveCheckModel>> _liveCheck() async {
    if (_liveCheckResult.isEmpty) {
      for (int i = 0; i < brodcastIDList.length; i++) {
        final url = Uri.parse(
            'https://api.chzzk.naver.com/polling/v2/channels/${brodcastIDList[i]}/live-status');

        try {
          final response = await http.get(url);

          if (response.statusCode == 200) {
            final String decodedBody =
                utf8.decode(response.bodyBytes); // UTF-8 디코딩
            final Map<String, dynamic> data =
                json.decode(decodedBody); // JSON을 Map으로 변환

            _liveCheckResult.add(LiveCheckModel.fromJson(data['content']));
          } else {
            print('오류 발생: ${response.statusCode}');
          }
        } catch (e) {
          print('예외 발생: $e');
        }
      }
    }

    return _liveCheckResult;
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
                  backgroundColor: Color(0x0fff5e88).withOpacity(1.0),
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
                          border: Border.all(
                              color: _liveCheckResult[index].status == 'OPEN'
                                  ? Colors.black
                                  : Colors.red,
                              width: _liveCheckResult[index].status == 'OPEN'
                                  ? 5.0
                                  : 0.0),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x0fff5e88).withOpacity(1.0),
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
                          status: _liveCheckResult[index],
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
