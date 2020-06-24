import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safewaydirection/api/storeInformation/store.dart';
import 'package:safewaydirection/data.dart' as safeway;
import 'package:safewaydirection/tMap.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show cos, sqrt, asin;
var height = AppBar().preferredSize.height * 1.1;
var width =  AppBar().preferredSize.width;

safeway.Route a = safeway.Route();

void main() => runApp(MyApp()); //신경

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.yellow,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
} //안써도

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
} //괜찮.

class _MyHomePageState extends State<MyHomePage> {
  bool extended = false;
  Completer<GoogleMapController> _controller = Completer();
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<Set<LatLng>> points = [];
  Set<Circle> circles ={};
  List<LatLng> polylinePoints = [];
  List<LatLng> acciPassList = [];
  List<LatLng> passList = [];
  List<List<LatLng>> nearPoints = [];
  LatLng source = LatLng(35.222752,129.090583);
  LatLng destination = LatLng(35.222792,129.095795);
  int visibleColorCnt = 0;
  int num =1;
  @override
  initState() {
    super.initState();

  }

  void getNearStores(LatLng pos, String id) async{
    print("=============== you called getNearStores() ================");
    List<Stores> nearStores = await findNearStores(100,pos);
    print(nearStores.length);
    for(int i=0; i<nearStores.length; i++){
      markers.add(Marker(
          markerId: MarkerId("store"+id),
          position: nearStores[i].storeLocation.location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: ()=>print("유해업소")
      ));
    }
//
//    setState(() {
//
//    });
    print("================ getNearStores() Done ==================");
  } //상가정보. 아직 활용 안할 것.

  void getPoints() async{
    print("================getPoint!=================");
    markers.add(Marker(
        markerId: MarkerId('source'),
        position: source,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        onTap: ()=>print("출발지")
    ));
    List<LatLng> passlist = [LatLng(35.221982,129.092644)];
    var values = await TmapServices.getRoute(source, destination,passlist);
    for(int i=0; i<values["features"].length; i++){ // points & linestrings
      String type = values["features"][i]["geometry"]["type"];
      List<dynamic> coordi = values["features"][i]["geometry"]["coordinates"];
      //print((coordi[0]).runtimeType);
      if(type =="LineString"){
        for(int j=0;  j<coordi.length; j++){
          LatLng position1 = LatLng(coordi[j][1],coordi[j][0]);
          if(markers.isNotEmpty&&markers.last.position!=position1){
            markers.add(Marker(
                markerId: MarkerId("LineString"+markers.length.toString()),
                position: position1,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                onTap: ()=>print(position1.longitude)
            ));
//            print("===================nearRoadInfoTest==================");
//            var near = await TmapServices.getNearRoadInformation(position1);
//            for(int k=0;k<near["resultData"]["linkPoints"].length; k++){
//              var lat = near["resultData"]["linkPoints"][k]["location"]["latitude"];
//              var lng = near["resultData"]["linkPoints"][k]["location"]["longitude"];
//              markers.add(Marker(
//                  markerId: MarkerId(markers.length.toString()),
//                  position: LatLng(lat,lng),
//                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//              ));
//            }
//            print("===================nearRoadInfoTestDone==================");
          }
        }
      }else{
        LatLng position2 = LatLng(coordi[1],coordi[0]);
        if(markers.isNotEmpty&&markers.last.position==position2){
          markers.remove(markers.last);
        }
        markers.add(Marker(
            markerId: MarkerId("Point"+markers.length.toString()),
            position: position2,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            onTap: ()=>print("Point")
        ));
//        print("===================nearRoadInfoTest==================");
//        var near = await TmapServices.getNearRoadInformation(position2);
//        for(int k=0;k<near["resultData"]["linkPoints"].length; k++){
//          var lat = near["resultData"]["linkPoints"][k]["location"]["latitude"];
//          var lng = near["resultData"]["linkPoints"][k]["location"]["longitude"];
//          markers.add(Marker(
//            markerId: MarkerId(markers.length.toString()),
//            position: LatLng(lat,lng),
//            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
//          ));
//        }
//        print("===================nearRoadInfoTestDone==================");
        //await getNearStores(position2,markers.length.toString());
      }
    }
    markers.add(Marker(
        markerId: MarkerId('destination'),
        position: destination,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        onTap: ()=>print("도착지")
    ));
    for(Marker m in markers){
      polylinePoints.add(m.position);
    }
    polylines.add(Polyline(
      polylineId: PolylineId('pid'),
      points:polylinePoints,
      color: Colors.blue,
      visible: true,
    ));
    setState(() {

    });
  } //출발지부터 목적지까지 기본 경로.

  void getAccidentData() async{
    http.Response response = await http.get("http://3.34.194.177:8088/secret/api/frequently/schoolzone/2018");
    var values = jsonDecode(response.body);
    var acciLat = double.parse(values[0]["la_crd"]);
    var acciLng = double.parse(values[0]["lo_crd"]);
    var acciPos = LatLng(acciLat,acciLng);
    markers.add(Marker(
        markerId: MarkerId('schoolzoneAcci'),
        position: acciPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        onTap: ()=>print("사고")
    ));
    List<List<double>> fourWay = [[0.001,0],[-0.001,0],[0,0.001],[0,-0.001]]; //위 아래 오른쪽 왼쪽
    for(int i=0; i<4; i++){
      LatLng fourWayPos = LatLng(acciLat+fourWay[i][0],acciLng+fourWay[i][1]);
      markers.add(Marker(
        markerId: MarkerId(markers.length.toString()),
        position: fourWayPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
      var near = await TmapServices.getNearRoadInformation(fourWayPos);
      var linkPoints = near["resultData"]["linkPoints"];
      for(int j=0; j<linkPoints.length; j++){
        var posLat = linkPoints[j]["location"]["latitude"];
        var posLng = linkPoints[j]["location"]["longitude"];
        print(LatLng(posLat,posLng));
        markers.add(Marker(
          markerId: MarkerId(markers.length.toString()),
          position: LatLng(posLat,posLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ));
        acciPassList.add(LatLng(posLat,posLng)); //가능한 경유지 정보 저장
      }
    }
    setState(() {

    });
  } //사고지 정보 얻음.

  Future<void> getPossibleRoute() async{
    await getAccidentData();
    List<Color> colors = [Colors.red,Colors.orange,Colors.yellow,Colors.green,Colors.blue,Colors.indigo,Colors.purple, Colors.pink,Colors.amber,Colors.black,Colors.white,Colors.brown];
    //List<Set<LatLng>> points = [];
    for(int i=0; i<acciPassList.length; i++){
      List<LatLng> tmp =[]; // before store to points list.
      var values = await TmapServices.getRoute(source, destination,[acciPassList[i]]);
      bool isFirstLineString = true;
      bool isDuplicated = false;
      for(int j=0; j<values["features"].length; j++){ //한가지 경로의 points, linestrings.
        if(j%2!=0){//lineString
          var coord = values["features"][j]["geometry"]["coordinates"];
          int coordIndex =1;
          if(isFirstLineString == true){
            isFirstLineString = false;
            coordIndex = 0;
          }
          for(; coordIndex<coord.length; coordIndex++){  //여기서 중복을 걸러줘야함.
            LatLng pos = LatLng(coord[coordIndex][1],coord[coordIndex][0]);
            if(tmp.contains(pos)==false){ //중복 없음
              tmp.add(pos);
            }else{ //중복 있음
              isDuplicated = true;
              tmp.clear();
              break;
            }
          }
          if(isDuplicated==true){
            break;
          }
        }
      }
      if(tmp.length>2){ //모든 가능 경로는 포인트가 적어도 1개 이상일거 아냐.. 출발 도착 포함하니까.
        points.add(tmp.toSet());
      }
    }
    for(int i=0; i<points.length; i++){
      polylines.add(Polyline(
        polylineId: PolylineId(polylines.length.toString()),
        points: points[i].toList(),//List<LatLng>.from(points[i].toList()),
        color: colors[i],
        visible: false,
      ));
    }
    setState(() {

    });

  } //우회경로를 찍기위한 경유지 위치 후보들을 마커로 찍어서 보여줌.

  void makePolylineVisible(){
    int n = polylines.length;
    int cnt = visibleColorCnt%n;
    print("n: "+n.toString()+", cnt: "+cnt.toString());
    List<Polyline> polylineList = polylines.toList();
    for(int i=0; i<n; i++){
      if(i==cnt){
        polylineList[cnt] = polylineList[cnt].copyWith(visibleParam: true);
      }else{
        if(polylineList[i].visible == true){
          polylineList[i] = polylineList[i].copyWith(visibleParam: false);
        }
      }
    }
    polylines = polylineList.toSet();
    visibleColorCnt++;
    setState(() {

    });
  } //Button을 누를때마다 폴리라인 경로 하나씩 보여줌.


  double calculateDistance(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
            preferredSize: Size.fromHeight(height),
            child : SafeArea(
              child: AppBar(
                automaticallyImplyLeading: true,
                flexibleSpace: Container(
                  margin: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                      color: Colors.yellow[100],
                      borderRadius : BorderRadius.all(Radius.circular(90))
                  ),
                  child : FlatButton(
                      onPressed:  () async =>  {await getPossibleRoute()},
  ),
                ),
              )
            ),
        ),
      body: Center(
        child: Stack(
          children: <Widget>[
            Opacity(opacity: extended ? 0 : 1,
              child: GoogleMap(
                mapType: MapType.normal,
                markers: markers,
                polylines: polylines,
                circles: circles,
                initialCameraPosition: CameraPosition(target:LatLng(35.223027,129.092952),zoom: 16),
                onMapCreated: (GoogleMapController controller) {
                  _controller.complete(controller);
                  //getAccidentData();
                  //getPoints();
                },
              ),
            ),
            FlatButton(
              color: Colors.yellow,
              onPressed: makePolylineVisible,
              child: Text(
                "Button"
              ),
            )
          ],
        )
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  } //레이아웃 파트. 내가 건들일 게 없음.

}
