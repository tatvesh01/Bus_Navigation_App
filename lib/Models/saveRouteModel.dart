import 'package:flutter/material.dart';

class SaveRouteModel{
  String name;
  List<dynamic> wayPointsForSaveData;
  List<dynamic> allAddress;
  bool routeType; //oneway = true , round trip = false

  SaveRouteModel({required this.name,required this.wayPointsForSaveData,required this.allAddress,required this.routeType});

  factory SaveRouteModel.fromJson(Map<String, dynamic> json) {
    return SaveRouteModel(
      name: json['name'] ?? "",
      wayPointsForSaveData: json['wayPointsForSaveData'] ?? [],
      allAddress: json['allAddress'] ?? [],
      routeType: json['routeType'],
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "wayPointsForSaveData": wayPointsForSaveData,
    "allAddress": allAddress,
    "routeType": routeType,
  };

}