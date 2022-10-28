import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static final LatLng churchLatLng = LatLng(37.5997, 127.0627);
  static final CameraPosition initialCameraPosition =
      CameraPosition(target: churchLatLng, zoom: 15);
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: renderAppBar,
        body: Column(
          children: [
            CustomGoogleMap(
              initialCameraPosition: initialCameraPosition,
            ),
            ChoolCheckButton(),
          ],
        ),
      ),
    );
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
  );
}

class CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialCameraPosition;
  const CustomGoogleMap({required this.initialCameraPosition, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        initialCameraPosition: initialCameraPosition,
        mapType: MapType.normal, //terrain,
      ),
    );
  }
}

class ChoolCheckButton extends StatelessWidget {
  const ChoolCheckButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Container(
        child: Text('출근'),
      ),
    );
  }
}
