import 'dart:math' as Math;
import 'dart:math';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:location/location.dart' as aaaaaa;
import 'package:map_navigation/main.dart';
import '../Models/saveRouteModel.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../Models/addRouteModel.dart';
import '../Utils/circleMaker.dart';
import '../Utils/global.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../Utils/helper.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';


class MapNavigationScreenController extends GetxController{

  late SaveRouteModel mapDataForNavigation;
  AddRouteModel routesList = AddRouteModel();
  Completer<GoogleMapController> mapController = Completer<GoogleMapController>();
  Location location = Location();
  late StreamSubscription<LocationData> locationSubscription;
  PolylinePoints polylinePoints = PolylinePoints();
  late PointLatLng originLatLong;
  late PointLatLng destinationLatLong;
  List<LatLng> polylineCoordinates = [];
  List<PolylineWayPoint> wayPointsPoly = [];
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = <PolylineId, Polyline>{};
  late LatLng myLatLong;
  LatLng? latLongForDistCalc;
  LatLng? latLongForDistCalcWhileDriving;
  BitmapDescriptor? carBitMap;

  RxBool refreshMap = false.obs;
  RxBool navigationStarted = false.obs;
  RxBool navigationStartedtemp = true.obs;
  RxBool originLocationReached = false.obs;
  RxBool isDragged = false.obs;
  int locationReachedCounter = 0;
  RxString speedInKm = "0.0".obs;
  RxBool refreshKmTxt = false.obs;
  late StreamSubscription speedCalcListner;
  List<PolylineWayPoint> wayPointsPolyWhileDriving = [];
  List<LatLng> tempLatLongWhileDriving = [];
  double mainBearing = 0.1;
  double cameraMoveMapRotation = 0.0;
  BitmapDescriptor? rightArrowBitmap;
  double totalDistanceOfPolyLine = 0;
  LatLng currentPosition = LatLng(0.0, 0.0);
  GoogleMapController? _mapController;
  var middleOfCarImg = const Offset(0.5, 0.5);
  List<LatLng> storeArrowLatLong = [];
  DateTime? previousTime;

  CameraPosition camPosition = const CameraPosition(
    target: LatLng(21.2094892, 72.8317058),
    zoom: 15.00,
  );


  @override
  void onInit() {
    Global.keepScreenOn();
    setUpMapData();
    super.onInit();
  }

  void setUpMapData() async {
    carBitMap = BitmapDescriptor.fromBytes(await getBytesFromAsset(Helper.carImg, 100));
    mapDataForNavigation = Get.arguments[0];

    //for developer use only
    //mapDataForNavigation.routeType = !mapDataForNavigation.routeType;  // todo

    if(!mapDataForNavigation.routeType){
      mapDataForNavigation.wayPointsForSaveData.add(mapDataForNavigation.wayPointsForSaveData[0]);
      mapDataForNavigation.allAddress.add(mapDataForNavigation.allAddress[0]);
    }

    //tempLatLongForTesting.clear(); // todo

    for(int i = 0; i < mapDataForNavigation.wayPointsForSaveData.length ; i++) {
      LatLng loopingLatLong = Global.latLongSeparator(mapDataForNavigation.wayPointsForSaveData[i].toString());

      //tempLatLongForTesting.add(loopingLatLong); // todo

      if(i == 0){
        originLatLong = PointLatLng(loopingLatLong.latitude,loopingLatLong.longitude);
      }else if(i == mapDataForNavigation.wayPointsForSaveData.length-1){
        destinationLatLong = PointLatLng(loopingLatLong.latitude,loopingLatLong.longitude);
      }
      routesList.addData(PolylineWayPoint(location: "${loopingLatLong.latitude},${loopingLatLong.longitude}"), loopingLatLong, mapDataForNavigation.allAddress[i]);

      if(mapDataForNavigation.routeType){
        BitmapDescriptor bitmapDescriptor = await CircleMaker(Helper.dotImg, i+1, width: 70, height: 70);
        String tempMarkerId = "pin${i+1}";
        addPinOnMap(loopingLatLong, tempMarkerId, bitmapDescriptor,);
      }else{
        if(i != mapDataForNavigation.wayPointsForSaveData.length - 1){
          BitmapDescriptor bitmapDescriptor = await CircleMaker(Helper.dotImg, i+1, width: 70, height: 70);
          String tempMarkerId = "pin${i+1}";
          addPinOnMap(loopingLatLong, tempMarkerId, bitmapDescriptor,);
        }
      }

      if(i == mapDataForNavigation.wayPointsForSaveData.length - 1){
        //drawRouteOnMap(routesList.wayPointsPoly).then((value) {
        manageWayPointsAndDrawRoutes(routesList.wayPointsPoly).then((value) {
          Set<Polyline> tempPolyLine = {};
          polylines.forEach((key, value) {
            tempPolyLine.add(value);
          });
          Global.setAllMarkerCenterInMap(tempPolyLine,mapController);
        });
      }
    }

    wayPointsPolyWhileDriving.addAll(routesList.wayPointsPoly);
    tempLatLongWhileDriving.addAll(routesList.wayPointsLatLng); // usage of getting index for remove waypoints
  }

  googleMapCreated(GoogleMapController controller){

    if(!mapController.isCompleted){
      mapController.complete(controller);
      _mapController = controller;
    }

    location.changeSettings(accuracy: aaaaaa.LocationAccuracy.high, interval: 3000, distanceFilter: 1); // todo
    locationSubscription = location.onLocationChanged.listen((locationsData) {

      DateTime currentTime = DateTime.now();
      if(previousTime == null){
        previousTime = currentTime;
        updateLocationAndUi(locationsData);
      }

      Duration difference = currentTime.difference(previousTime!);
      if(difference.inSeconds >= 3){
        updateLocationAndUi(locationsData);
        previousTime = DateTime.now();
      }

    });
  }

  updateLocationAndUi(LocationData newLocationData) async {
    debugPrint("location update ==> onLocationChanged");

    if(navigationStarted.value){
      //for developer use only
      /*if(navigationStartedtemp.value){
        myLatLong = LatLng(newLocationData.latitude ?? 0.0, newLocationData.longitude ?? 0.0);
      }*/
      // todo
      myLatLong = LatLng(newLocationData.latitude ?? 0.0, newLocationData.longitude ?? 0.0);

      double tempBearing = newLocationData.heading ?? 0.0;
      if(tempBearing != 0.0){
        mainBearing = tempBearing;
      }

      animateCar(myLatLong);

      List<LatLng> upcomingThreeLatLong = [];
      upcomingThreeLatLong.add(routesList.wayPointsLatLng[locationReachedCounter]);

      if(originLocationReached.value){
        if(routesList.wayPointsLatLng.length - 1 > locationReachedCounter){
          upcomingThreeLatLong.add(routesList.wayPointsLatLng[locationReachedCounter+1]);
        }
        if(routesList.wayPointsLatLng.length - 2 > locationReachedCounter){
          upcomingThreeLatLong.add(routesList.wayPointsLatLng[locationReachedCounter+2]);
        }
      }

      int? destReachedNumber = Global.calculateDistanceBetweenEveryWayPointsInMeter(myLatLong,upcomingThreeLatLong);

      if(destReachedNumber != null){
        int destIndex = routesList.wayPointsLatLng.indexWhere((element) => element == upcomingThreeLatLong[destReachedNumber]);

        if(destIndex == 0){
          originLocationReached(true);
          removeDotedPolyLine();
        }

        if(locationReachedCounter == routesList.wayPointsLatLng.length - 1){
          Global.speakTxt("Your Final Destination Reached");
          navigationStarted(false);
          locationReachedCounter = 0;
          await Future.delayed(const Duration(seconds: 1));
          removeAllPolyLine();
        }else{
          Global.speakTxt("Your ${destIndex+1} Destination Reached");
          try{
            int indexForRemoveWayPoints = tempLatLongWhileDriving.indexWhere((element) => element == upcomingThreeLatLong[destReachedNumber]);
            if(indexForRemoveWayPoints != -1){
              for(int a = 0 ; a <= indexForRemoveWayPoints; a++){
                tempLatLongWhileDriving.removeAt(0);
                wayPointsPolyWhileDriving.removeAt(0);
                locationReachedCounter++;
              }
            }
          }catch(e){
            //Some Error
          }
        }
      }/*else{
        if(navigationStarted.value && originLocationReached.value){
          originLatLong = PointLatLng(myLatLong.latitude,myLatLong.longitude);
          drawRouteOnMap(wayPointsPolyWhileDriving);
          latLongForDistCalcWhileDriving = myLatLong;
        }
      }*/

      if(navigationStarted.value && originLocationReached.value){
        if(latLongForDistCalcWhileDriving != null){
          double distanceInMeter = Global.calculateDistanceInMeter(myLatLong.latitude, myLatLong.longitude, latLongForDistCalcWhileDriving!.latitude, latLongForDistCalcWhileDriving!.longitude);
          if(distanceInMeter >= Helper.drawReRouteTimeMinMtr){
            originLatLong = PointLatLng(myLatLong.latitude,myLatLong.longitude);
            //drawRouteOnMap(wayPointsPolyWhileDriving);
            manageWayPointsAndDrawRoutes(wayPointsPolyWhileDriving);
            latLongForDistCalcWhileDriving = myLatLong;
          }
        }else{
          latLongForDistCalcWhileDriving = myLatLong;
        }
      }

      if(!originLocationReached.value){
        if(latLongForDistCalc != null){
          double distanceInMeter = Global.calculateDistanceInMeter(myLatLong.latitude, myLatLong.longitude, latLongForDistCalc?.latitude, latLongForDistCalc?.longitude);
          if(distanceInMeter > Helper.drawDotedRouteAgainAfterDriveMeters){
            drawDotedRouteOnMap();
            latLongForDistCalc = LatLng(newLocationData.latitude ?? 0.0, newLocationData.longitude ?? 0.0);
          }
        }else{
          drawDotedRouteOnMap();
          latLongForDistCalc = LatLng(myLatLong.latitude, myLatLong.longitude);
        }
      }
    }else{
      myLatLong = LatLng(newLocationData.latitude ?? 0.0, newLocationData.longitude ?? 0.0);
      currentPosition = myLatLong;
    }
  }

  moveCameraOnMyLocation(LatLng myLatLong, double mainBearings) async {
    final c = await mapController.future;
    camPosition = CameraPosition(
      target: myLatLong,
      zoom: 17,
      bearing: mainBearings,
    );
    c.animateCamera(CameraUpdate.newCameraPosition(camPosition));
  }

  speedCalculator(){
    speedCalcListner = Geolocator.getPositionStream().listen((speedPositions) {
      double speedMps = speedPositions.speed;
      double speedInKmDbl = speedMps * 3.6;
      speedInKm = (speedInKmDbl.toStringAsFixed(2)).obs;
      refreshKmTxt(true);
      refreshKmTxt(false);
    });
  }

  updateMap(){
    refreshMap(true);
    refreshMap(false);
  }


  manageWayPointsAndDrawRoutes(List<PolylineWayPoint> wayPointsPolyNew) async {

    for (int i = 0; i < wayPointsPolyNew.length; i += 20) {
      final batch = wayPointsPolyNew.sublist(i, i + 20 > wayPointsPolyNew.length ? wayPointsPolyNew.length : i + 20);
      if(i != 0){
        batch.insert(0,wayPointsPolyNew[i-1]);
      }

      bool isLastCall = i+20 >= wayPointsPolyNew.length;
      await drawRouteOnMap(batch, isLastCall, i == 0);
    }
  }

  Future<bool> drawRouteOnMap(List<PolylineWayPoint> waypointsBatch,bool isLastCall, bool firstLooping) async {

    //if(navigationStarted.value && originLocationReached.value){
    if(navigationStarted.value && originLocationReached.value && firstLooping){
      waypointsBatch.insert(0, PolylineWayPoint(location: "${myLatLong.latitude},${myLatLong.longitude}"));
    }

    var firstWay = waypointsBatch.first.toString().split(',');
    var lastWay = waypointsBatch.last.toString().split(',');
    LatLng firstLatLong = LatLng(double.parse(firstWay[0]), double.parse(firstWay[1]));
    LatLng lastLatLong = LatLng(double.parse(lastWay[0]), double.parse(lastWay[1]));
    PointLatLng originPlace = PointLatLng(firstLatLong.latitude, firstLatLong.longitude);
    late PointLatLng destPlace;

    if(mapDataForNavigation.routeType){
      destPlace = PointLatLng(lastLatLong.latitude, lastLatLong.longitude);
    }else{
      if(routesList.wayPointsLatLng.length >= 3){
        if(isLastCall){
          //destPlace = originPlace;
          destPlace = PointLatLng(routesList.wayPointsLatLng.first.latitude, routesList.wayPointsLatLng.first.longitude);
        }else{
          destPlace = PointLatLng(lastLatLong.latitude, lastLatLong.longitude);
        }
      }else{
        destPlace = PointLatLng(lastLatLong.latitude, lastLatLong.longitude);
      }
    }

    debugPrint("locationData ==>  ${originPlace}       ${destPlace}");

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: Global.mapApiKey,
      request: PolylineRequest(
          //origin: originLatLong,
          origin: originPlace,
          destination: destPlace,
          mode: TravelMode.driving,
          wayPoints: routesList.wayPointsPoly.length >= 3 ?  waypointsBatch
              .sublist(1, waypointsBatch.length)
              .map((point) => point)
              .toList() : []
      ),
    );

    if(firstLooping){
      removeAllPolyLine();
    }

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      Global.showToast("Error From Google Api : ${result.errorMessage}");
    }

    PolylineId id = PolylineId("poly");
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinates,
      color: Helper.blackColor,
      width: 7,
    );
    polylines[id] = polyline;
    updateMap();
    if(totalDistanceOfPolyLine == 0){
      calculateDistanceOfPolyLineInMtr();
    }
    await Future.delayed(const Duration(milliseconds: 1));
    return true;
  }

  addPinOnMap(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }

  void showVehicleOnMyLocation() async{
    MarkerId markerId = MarkerId("myVehicle");
    if(carBitMap == null){
      carBitMap = BitmapDescriptor.fromBytes(await getBytesFromAsset(Helper.carImg, 100));
      markers[markerId] = Marker(markerId: markerId, icon: carBitMap!, position: myLatLong,anchor: middleOfCarImg);
      updateMap();
    }else{
      markers[markerId] = Marker(markerId: markerId, icon: carBitMap!, position: myLatLong,anchor: middleOfCarImg);
      updateMap();
    }
  }

  Future<bool> drawDotedRouteOnMap() async {

    PolylinePoints polylinePointsTemp = PolylinePoints();
    List<LatLng> polylineCoordinatesTemp = [];
    PolylineResult result = await polylinePointsTemp.getRouteBetweenCoordinates(
      googleApiKey: Global.mapApiKey,
      request: PolylineRequest(
          origin: PointLatLng(myLatLong.latitude,myLatLong.longitude),
          destination: PointLatLng(originLatLong.latitude,originLatLong.longitude),
          mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinatesTemp.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      Global.showToast("Error From Google Api : ${result.errorMessage}");
    }

    PolylineId id = PolylineId("dotedPolyLine");
    Polyline polyline = Polyline(
      polylineId: id,
      points: polylineCoordinatesTemp,
      color: Helper.lightGreenColor,
      width: 3,
      patterns: [PatternItem.dash(10), PatternItem.gap(10)],
    );
    polylines[id] = polyline;
    updateMap();
    return true;
  }

  removeDotedPolyLine(){
    polylines.removeWhere((key, value) => key.value == "dotedPolyLine");
    updateMap();
  }

  void recenterBtnPressed() {
    isDragged(false);
    if(navigationStarted.value){
      moveCameraOnMyLocation(myLatLong, mainBearing);
    }else{
      Set<Polyline> tempPolyLine = {};
      polylines.forEach((key, value) {
        tempPolyLine.add(value);
      });
      Global.setAllMarkerCenterInMap(tempPolyLine, mapController);
    }
  }

  void removeAllPolyLine(){
    polylineCoordinates = [];
    polylines.clear();
    wayPointsPoly = [];
    updateMap();
  }


  void animateCar(LatLng targetPosition) async{

    double angleOfCar = mainBearing - cameraMoveMapRotation;
    const duration = Duration(milliseconds: 3000);
    int steps = 20;
    double stepDuration = duration.inMilliseconds / steps;

    LatLng start = currentPosition;
    LatLng end = targetPosition;

    Timer.periodic(Duration(milliseconds: (stepDuration).toInt()), (Timer timer) async {
      double t = timer.tick / steps;
      if (t > 1) {
        timer.cancel();
        t = 1;
      }

      double lat = start.latitude + (end.latitude - start.latitude) * t;
      double lng = start.longitude + (end.longitude - start.longitude) * t;

      LatLng newPosition = LatLng(lat, lng);

      markers.removeWhere((key, value) => key.value.startsWith("myVehicle"));

      MarkerId markerId = MarkerId("myVehicle");
      if(isDragged.value){
        markers[markerId] = Marker(markerId: markerId, icon: carBitMap!, position: newPosition, anchor: middleOfCarImg, rotation: angleOfCar,);
      }else{
        markers[markerId] = Marker(markerId: markerId, icon: carBitMap!, position: newPosition, anchor: middleOfCarImg);
      }
      updateMap();



      if (t == 1) {
        currentPosition = end;

        if (_mapController != null) {

          if(!isDragged.value){
            _mapController!.animateCamera(CameraUpdate.newLatLng(newPosition));

            var c = await mapController.future;
            camPosition = CameraPosition(
              target: currentPosition,
              zoom: 17,
              bearing: mainBearing,
            );
            c.animateCamera(CameraUpdate.newCameraPosition(camPosition));
          }
        }

        updateMap();
      }
    });
  }


  void whenCameraMove(CameraPosition position) {
    cameraMoveMapRotation = position.bearing;
    addDirectionWiseArrow(position.zoom.toInt()+5);
  }

  addDirectionWiseArrow(int arrowSize) async{
    storeArrowLatLong = [];
    markers.removeWhere((key, value) => key.value.startsWith("arrow_"));
    rightArrowBitmap ??= BitmapDescriptor.fromBytes(await getBytesFromAsset(Helper.upArrowImg, arrowSize));

    double calculateForShowArrow = (totalDistanceOfPolyLine * 15)/1000;

    for(int i = 0 ; i < polylineCoordinates.length -1 ; i++){

      var start = polylineCoordinates[i];
      var end = polylineCoordinates[i + 1];
      double distanceInMtr = Global.calculateDistanceInMeter(start.latitude,start.longitude, end.latitude,end.longitude);

      if(distanceInMtr > calculateForShowArrow){
        double angel = calculateBearingForArrow(start, end) - cameraMoveMapRotation;

        int indexOfLstLong = storeArrowLatLong.indexWhere((element) => element == end);
        if(indexOfLstLong == -1){
          storeArrowLatLong.add(end);
        }else{
          LatLng destination = addDestinationInLatLong(start, 10, angel);
          end = destination;
          storeArrowLatLong.add(destination);
        }

        try{
          var tempMarkerId = MarkerId("arrow_${i}");
          var tempMarker = Marker(
            markerId: tempMarkerId,
            position: end,
            icon: rightArrowBitmap!,
            rotation: angel,
            anchor: const Offset(0.5, 0.5),
          );

          markers[tempMarkerId] = tempMarker;
        }catch(r){}
      }
    }

    updateMap();
  }


  LatLng addDestinationInLatLong(LatLng start, double distance, double bearing) {
    double earthRadius = 6371000;

    double lat1 = start.latitude * pi / 180;
    double lon1 = start.longitude * pi / 180;
    double bearingRad = bearing * pi / 180;

    double lat2 = asin(sin(lat1) * cos(distance / earthRadius) +
        cos(lat1) * sin(distance / earthRadius) * cos(bearingRad));

    double lon2 = lon1 + atan2(
      sin(bearingRad) * sin(distance / earthRadius) * cos(lat1),
      cos(distance / earthRadius) - sin(lat1) * sin(lat2),
    );

    return LatLng(lat2 * 180 / pi, lon2 * 180 / pi);
  }

  calculateDistanceOfPolyLineInMtr(){
    for(int i = 0 ; i < polylineCoordinates.length -1 ; i++){
      final start = polylineCoordinates[i];
      final end = polylineCoordinates[i + 1];
      double distance = Geolocator.distanceBetween(start.latitude,start.longitude, end.latitude,end.longitude);

      totalDistanceOfPolyLine = totalDistanceOfPolyLine + distance;
    }
    debugPrint("totalDistance ==> ${totalDistanceOfPolyLine}");
  }


  double calculateBearingForArrow(LatLng startPoint, LatLng endPoint) {
    final double startLat = toRadians(startPoint.latitude);
    final double startLng = toRadians(startPoint.longitude);
    final double endLat = toRadians(endPoint.latitude);
    final double endLng = toRadians(endPoint.longitude);

    final double deltaLng = endLng - startLng;

    final double y = Math.sin(deltaLng) * Math.cos(endLat);
    final double x = Math.cos(startLat) * Math.sin(endLat) -
        Math.sin(startLat) * Math.cos(endLat) * Math.cos(deltaLng);

    final double bearing = Math.atan2(y, x);

    return (toDegrees(bearing) + 360) % 360;
  }

  double toRadians(double degrees) {
    return degrees * (Math.pi / 180.0);
  }

  double toDegrees(double radians) {
    return radians * (180.0 / Math.pi);
  }



  //for developer use only
  /*List<LatLng> tempLatLongForTesting = [
    LatLng(21.234442, 72.876450),
    LatLng(21.234572, 72.877030),
    LatLng(21.234462, 72.875839),
    //LatLng(21.235143, 72.875694),
    LatLng(21.234758, 72.873720),
    LatLng(21.235623, 72.875592),
    LatLng(21.236903, 72.875903),
    LatLng(21.236903, 72.876359),
    LatLng(21.236883, 72.877513),
    LatLng(21.236183, 72.877625),
    LatLng(21.235603, 72.877598),
    LatLng(21.234572, 72.877030),//
    LatLng(21.234572, 72.877030),
    LatLng(21.234462, 72.875839),
  ];

  routeTesting() async {
    for (int x = 0; x < tempLatLongForTesting.length; x++) {
      if(x == 0){
        myLatLong = tempLatLongForTesting[x];
      }else{
        await Future.delayed(Duration(seconds: 5)).then((_) {
          print("dfdfdfdfdfdf----------   ${x}");
          myLatLong = tempLatLongForTesting[x];
        });
      }
    }
  }*/

}