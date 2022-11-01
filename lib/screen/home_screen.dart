import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool choolCheckDone = false;
  GoogleMapController? mapController;
  // static final LatLng churchLatLng = LatLng(37.5997, 127.0627);
  static final LatLng schoolLatLng = LatLng(37.6018, 127.064);
  static final CameraPosition initialCameraPosition =
      CameraPosition(target: schoolLatLng, zoom: 15);
  static final double okDistance = 100; //100m
  static final Circle withinDistanceCircle = Circle(
    circleId: CircleId('withinDistanceCircle'),
    center: schoolLatLng,
    fillColor: Colors.blue.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.blue,
    strokeWidth: 1,
  );
  static final Circle notWithinDistanceCircle = Circle(
    circleId: CircleId('notWithinDistanceCircle'),
    center: schoolLatLng,
    fillColor: Colors.red.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.red,
    strokeWidth: 1,
  );
  static final Circle checkDoneCircle = Circle(
    circleId: CircleId('checkDoneCircle'),
    center: schoolLatLng,
    fillColor: Colors.deepPurple.withOpacity(0.5),
    radius: okDistance,
    strokeColor: Colors.deepPurple,
    strokeWidth: 1,
  );
  static final Marker marker = Marker(
    markerId: MarkerId('marker'),
    position: schoolLatLng,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: renderAppBar,
        body: FutureBuilder<String>(
            future: checkPermission(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (snapshot.data == '위치 권한이 허가되었습니다.') {
                return StreamBuilder<Position>(
                    //generic은 snapshot의 Type
                    stream: Geolocator
                        .getPositionStream(), //getPositionStream은 position값이 바뀔때마다 불린다.(위치가 이동될때마다)
                    builder: (context, snapshot) {
                      //snapshot.data가 바뀌면 builder가 다시 실행된다
                      bool isWithinRange = false; //어떤 circle을 넣어줄지 정해준다.

                      if (snapshot.hasData) {
                        final start = snapshot.data!;
                        final end = schoolLatLng;

                        final distance = Geolocator.distanceBetween(
                          start.latitude,
                          start.longitude,
                          end.latitude,
                          end.longitude,
                        );

                        if (distance < okDistance) {
                          isWithinRange = true;
                        }
                      }
                      return Column(
                        children: [
                          CustomGoogleMap(
                            initialCameraPosition: initialCameraPosition,
                            circle: choolCheckDone
                                ? checkDoneCircle
                                : isWithinRange
                                    ? withinDistanceCircle
                                    : notWithinDistanceCircle,
                            marker: marker,
                            onMapCreated: onMapCreated,
                          ),
                          ChoolCheckButton(
                            isWithinRange: isWithinRange,
                            choolCheckDone: choolCheckDone,
                            onPressed: onChoolCheckPressed,
                          ),
                        ],
                      );
                    });
              }

              return Center(
                child: Text(snapshot.data!),
              );
            }),
      ),
    );
  }

  onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  onChoolCheckPressed() async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext) {
        return AlertDialog(
          title: Text('출근하기'),
          content: Text('출근을 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("취소"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("출근하기"),
            ),
          ],
        );
      },
    );
    if (result) {
      setState(() {
        choolCheckDone = true;
      });
    }
  }

  Future<String> checkPermission() async {
    //위치 서비스가 켜져있는지 확인
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (isLocationEnabled == false) {
      return '위치 서비스를 활성화 해주세요';
    }

    LocationPermission checkedPermission =
        await Geolocator.checkPermission(); //현재 앱이 가지고 있는 위치서비스 권한 값을 가지고온다
    if (checkedPermission == LocationPermission.denied) {
      //denied는 위치서비스를 쓸 순 없지만 위치권한 요청은 할 수 있다
      checkedPermission = await Geolocator.requestPermission();
      if (checkedPermission == LocationPermission.denied) {
        return '위치 권한을 허가해주세요.';
      }
    }
    if (checkedPermission == LocationPermission.deniedForever) {
      //deniedForever는 위치권한 요청 다이얼로그조차 띄울 수 없다.
      return '앱의 위치 권한을 세팅에서 허가해주세요.';
    }

    return '위치 권한이 허가되었습니다.';
  }

  AppBar renderAppBar = AppBar(
    title: Text(
      '오늘도 출근', //'근처 식당찾기',
      style: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.w900,
      ),
    ),
    centerTitle: true,
    backgroundColor: Colors.white,
    actions: [
      IconButton(
        onPressed: () async {
          if (mapController == null) {
            return;
          }
          final location = await Geolocator.getCurrentPosition();
          mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(location.latitude, location.longitude),
            ),
          );
        },
        icon: Icon(Icons.my_location),
        color: Colors.black,
      ),
    ],
  );
}

class CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialCameraPosition;
  final Circle circle;
  final Marker marker;
  final MapCreatedCallback onMapCreated;
  const CustomGoogleMap(
      {required this.initialCameraPosition,
      Key? key,
      required this.circle,
      required this.marker,
      required this.onMapCreated})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        mapType: MapType.normal, //terrain,
        myLocationEnabled: true, //현재 위치 표시
        myLocationButtonEnabled: false, //현재위치 새로고침 버튼
        circles: Set.from([
          circle,
        ]),
        markers: Set.from([
          marker,
        ]),
        onMapCreated: onMapCreated,
      ),
    );
  }
}

class ChoolCheckButton extends StatelessWidget {
  final bool isWithinRange;
  final VoidCallback onPressed;
  final bool choolCheckDone;
  const ChoolCheckButton(
      {Key? key,
      required this.isWithinRange,
      required this.onPressed,
      required this.choolCheckDone})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timelapse_outlined,
            size: 50,
            color: choolCheckDone
                ? Colors.deepPurple
                : isWithinRange
                    ? Colors.blue
                    : Colors.red,
          ),
          SizedBox(height: 20),
          if (!choolCheckDone && isWithinRange)
            TextButton(
              onPressed: onPressed,
              child: Text('출근하기'),
            ),
        ],
      ),
    );
  }
}
