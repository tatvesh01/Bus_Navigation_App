import 'dart:math';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as LatLngs;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flu_wake_lock/flu_wake_lock.dart';

import 'helper.dart';


class Global {
  static String mapApiKey = "";  // Put your android map sdk key here

  static double sWidth = 0, sHeight = 0;
  static late FlutterGooglePlacesSdk places;
  static FlutterTts flutterTts = FlutterTts();
  static FluWakeLock _fluWakeLock = FluWakeLock();


  static deviceSize(BuildContext context) {
    sWidth = MediaQuery.of(context).size.width;
    sHeight = MediaQuery.of(context).size.height;
  }

  static initPlacePicker() {
    places = FlutterGooglePlacesSdk(Global.mapApiKey);
    places.isInitialized().then((value) {
      debugPrint('Places Initialized: $value');
    });
  }

  static showToast(String txt) {
    Fluttertoast.showToast(msg: txt, toastLength: Toast.LENGTH_SHORT,);
  }

  static LatLngs.LatLng latLongSeparator(String txt) {
    txt = txt.replaceAll("[", "");
    txt = txt.replaceAll("]", "");
    var splitted = txt.split(', ');

    LatLngs.LatLng sendLtLng = LatLngs.LatLng( double.parse(splitted[0]), double.parse(splitted[1]));
    return sendLtLng;
  }

  static void makeVibration()async{
    bool canVibrate = await Vibrate.canVibrate;
    if(canVibrate){
      Vibrate.vibrate();
    }
  }

  static Future speakTxt(String txt) async{
    //var result = await flutterTts.speak(txt);
    showToast(txt);
    makeVibration();
  }

  static Future<String> latLongToAddress(LatLngs.LatLng latLong) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(latLong.latitude, latLong.longitude);
    Placemark placeMark = placemarks[0];

    //debugPrint("placeMark ==>\n ${placeMark}");
    
    String locality = placeMark.locality ?? ""; // city
    String thoroughfare = placeMark.thoroughfare ?? ""; //street
    String name = placeMark.name ?? ""; // house number

    String subLocality = "${placeMark.subLocality}, ";
    String street = "${placeMark.street}, ";
    String administrativeArea = "${placeMark.administrativeArea}, ";
    String subThoroughfare = "${placeMark.subThoroughfare}, "; //sub street

    String finalAddress = "";
    if(locality.trim() != ""){
      finalAddress = "${locality}, ";
    }
    if(thoroughfare.trim() != ""){
      finalAddress = "${finalAddress}${thoroughfare}, ";
    }
    if(name.trim() != ""){
      finalAddress = "${finalAddress}${name}";
    }

    return finalAddress;
  }

  static void setAllMarkerCenterInMap(Set<Polyline> tempPolyLine,Completer<GoogleMapController> mapController) async{

    double minLat = tempPolyLine.first.points.first.latitude;
    double minLong = tempPolyLine.first.points.first.longitude;
    double maxLat = tempPolyLine.first.points.first.latitude;
    double maxLong = tempPolyLine.first.points.first.longitude;
    tempPolyLine.forEach((poly) {
      poly.points.forEach((point) {
        if(point.latitude < minLat) minLat = point.latitude;
        if(point.latitude > maxLat) maxLat = point.latitude;
        if(point.longitude < minLong) minLong = point.longitude;
        if(point.longitude > maxLong) maxLong = point.longitude;
      });
    });

    final c = await mapController.future;
    c.animateCamera(CameraUpdate.newLatLngBounds(LatLngs.LatLngBounds(
        southwest: LatLngs.LatLng(minLat, minLong),
        northeast: LatLngs.LatLng(maxLat,maxLong)
    ), 80));
  }


  static double calculateDistanceInMeter(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    var radiusOfEarth = 6371;
    return 1000 * radiusOfEarth * 2 * asin(sqrt(a));
  }

  static int? calculateDistanceBetweenEveryWayPointsInMeter(LatLngs.LatLng myLatLng, List<LatLngs.LatLng> wayPointsLatLng){
    LatLngs.LatLng latLng1 = myLatLng;
    LatLngs.LatLng latLng2 = myLatLng;

    for(int i = 0 ; i < wayPointsLatLng.length ; i++){
      latLng2 = wayPointsLatLng[i];

      var p = 0.017453292519943295;
      var c = cos;
      var a = 0.5 - c((latLng2.latitude - latLng1.latitude) * p)/2 +
          c(latLng1.latitude * p) * c(latLng2.latitude * p) *
              (1 - c((latLng2.longitude - latLng1.longitude) * p))/2;
      var radiusOfEarth = 6371;
      var distanceInMeter = 1000 * radiusOfEarth * 2 * asin(sqrt(a));

      if(distanceInMeter < Helper.destReachTimeMinMtr){
        return i;
      }
    }
    return null;
  }

  static double calculateDistanceInKM(lat1, lon1, lat2, lon2){
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 +
        c(lat1 * p) * c(lat2 * p) *
            (1 - c((lon2 - lon1) * p))/2;
    var radiusOfEarth = 6371;
    return radiusOfEarth * 2 * asin(sqrt(a));
  }


  static void keepScreenOn(){
    _fluWakeLock.enable();
  }

  static void stopKeepScreenOn(){
    _fluWakeLock.disable();
  }
}
