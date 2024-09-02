import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';


class AddRouteModel{
  List<PolylineWayPoint> wayPointsPoly = [];
  List<LatLng> wayPointsLatLng = [];
  List<String> allAddress = [];

  AddRouteModel();

  addData(PolylineWayPoint wayPoint, LatLng wayPointLatLong, String address){
    wayPointsPoly.add(wayPoint);
    wayPointsLatLng.add(wayPointLatLong);
    allAddress.add(address);
  }

  removeSingleData(int index){
    wayPointsPoly.removeAt(index);
    wayPointsLatLng.removeAt(index);
    allAddress.removeAt(index);
  }

  removeAllData(){
    wayPointsPoly = [];
    wayPointsLatLng = [];
    allAddress = [];
  }


  /*factory AddRouteModel.fromJson(Map<String, dynamic> json) {
    return AddRouteModel(
      wayPoints: json['wayPoints'],
      wayPointsForSaveData: json['wayPointsForSaveData'],
      allAddress: json['allAddress'],
    );
  }

  Map<String, dynamic> toJson() => {
    "wayPoints": wayPoints,
    "wayPointsForSaveData": wayPointsForSaveData,
    "allAddress": allAddress,
  };*/


}