import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:safewaydirection/tMap.dart';
import 'package:flutter/material.dart';
import 'package:safewaydirection/api/store.dart';
import 'package:safewaydirection/route.dart' as way;

class Detour{
  List<Color> colors = [Colors.red,Colors.orange,Colors.yellow,Colors.green,Colors.blue,Colors.indigo,Colors.purple, Colors.pink,Colors.amber,Colors.black,Colors.white,Colors.brown];
//  LatLng source = LatLng(35.2464852,129.090551);
//  LatLng destination = LatLng(35.2487721, 129.091708);
  Set<Polyline> polylines = {};
  List<List<LatLng>> polylinePoints = [];
  way.Route route = way.Route();
  Set<way.Route> routes ={};
  List<LatLng> passPoints = [];
  LatLng source;
  LatLng destination;

  Detour();

  Detour.map(this.source, this.destination);


  void getRouteOrDetour() async{ //이 함수가 호출되면, polylinePoints 리스트의 값이 채워짐.
    route = await TmapServices.getRoute(source, destination);  // get route infomation

    Set<way.BadPoint> accidentAreas = {};
    await way.BadPoint.updateBadPointbyStore(accidentAreas, await findNearStoresInRectangle(source, destination));
    await route.updateDanger(accidentAreas);

    List<List<double>> fourWay = [[0.001,0],[-0.001,0],[0,0.001],[0,-0.001]]; //위 아래 오른쪽 왼쪽 100m
    LatLng dp; // danger point

    for(int i=0; i<route.locations.length; i++){ //받은 값들중에 danger값이 있는지 판별.
      if(route.locations[i].danger>0){
        dp=route.locations[i].location;
        break;
      }
    }

    if(dp!=null){//more than 1 danger point
      for(int direction =0; direction<4; direction++){ //위험 포인트에서 경유 후보 뽑아냄.
        LatLng fourWayPos = LatLng(dp.latitude+fourWay[direction][0],dp.longitude+fourWay[direction][1]);
        var near = await TmapServices.getNearRoadInformation(fourWayPos);
        for(int passPoint =0; passPoint<near.length; passPoint++){
          passPoints.add(LatLng(near[passPoint].latitude,near[passPoint].longitude));
        }
      }
      for(int pp = 0; pp<passPoints.length; pp++){ // 뽑아낸 경유 후보들에서 새로운 경로후보들 뽑음
        route = await TmapServices.getRoute(source, destination,[passPoints[pp]]);
        List<LatLng> tmp=[];
        int start=-1;
        int end=-1;
        for(int p = 0; p<route.locations.length; p++){
          if(tmp.contains(route.locations[p].location)){ //중복 제거를 위한 범위 검사.
            tmp.add(route.locations[p].location);
            end = p;
            start = tmp.indexOf(route.locations[p].location);
          }else{
            tmp.add(route.locations[p].location);
          }
        }
        if(start!=-1&&end!=-1){
          for(int cnt=0; cnt<end-start; cnt++){
            tmp.removeAt(start);
            route.locations.removeAt(start);
          }
        }
        int len = routes.length;
        routes.add(route);

        if(len<routes.length){
          polylinePoints.add(tmp.toList());
        }
      }
    }else{ //처음부터 안전경로일 경우.
      List<LatLng> oneWay=[];
      for(var point in route.locations){
        oneWay.add(point.location);
      }
      polylinePoints.add(oneWay);
    }
  }

  void drawAllPolyline() async{
    await getRouteOrDetour();
    for(int i=0; i<polylinePoints.length; i++){
      polylines.add(Polyline(
        polylineId: PolylineId(polylines.length.toString()),
        points:polylinePoints[i],
        color: colors[i],
        visible: true,
      ));
    }
  }
}