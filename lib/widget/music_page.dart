import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:honeyz_fan_app/model/music_model.dart';
import 'package:honeyz_fan_app/widget/components/music_card.dart';

class MusicPageWidget extends StatefulWidget {
  const MusicPageWidget({super.key});

  @override
  State<MusicPageWidget> createState() => _MusicPageWidgetState();
}

class _MusicPageWidgetState extends State<MusicPageWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
  }

  List<MusicModel> _result = [];

  Future<List<MusicModel>> _loadFirestore() async {
    FirebaseFirestore _firestore = FirebaseFirestore.instance;

    QuerySnapshot<Map<String, dynamic>> _snapshot = await _firestore
        .collection("music")
        .orderBy('created_at', descending: false)
        .get();
    _result = _snapshot.docs.map((e) => MusicModel.fromJson(e.data())).toList();
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
                        child: MusicCard(
                          musicModel: _result[index],
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
