import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_google_places_sdk_platform_interface/src/types/place_field.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../Models/addRouteModel.dart';
import '../Models/saveRouteModel.dart';
import '../Utils/circleMaker.dart';
import '../Utils/global.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../Utils/helper.dart';
import '../Utils/sPHelper.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';


class MainScreenController extends GetxController {
  TextEditingController locationSearchTF = TextEditingController();
  TextEditingController nameForSaveDataTF = TextEditingController();
  PanelController slidingPanelController = new PanelController();

  Completer<GoogleMapController> mapController = Completer<GoogleMapController>();
  Map<MarkerId, Marker> markers = {};
  Map<PolylineId, Polyline> polylines = <PolylineId, Polyline>{};
  PolylinePoints polylinePoints = PolylinePoints();
  late BuildContext tempContext;

  LatLng initLatLong = LatLng(21.2094892, 72.8317058);
  LatLng firstLatLong = LatLng(21.2094892, 72.8317058);
  late PointLatLng originLatLong;
  late PointLatLng destinationLatLong;
  List<LatLng> polylineCoordinates = [];
  AddRouteModel routesList = AddRouteModel();

  RxBool refreshMap = false.obs;
  RxBool refreshListData = false.obs;
  RxBool enablePlanBtn= false.obs;
  RxBool enableClearBtn = true.obs;
  RxBool enableSaveBtn = true.obs;
  RxBool refreshBtnView = false.obs;

  RxBool isOneWaySelected = true.obs;
  RxBool wayDialogRefresh = false.obs;
  RxBool isEditTime = false.obs;
  RxBool isAddPlanTime = false.obs;
  RxBool refreshBottomSheet = false.obs;
  RxBool openBottomSheet = false.obs;
  String routeSelectedValue = "One Way";

  CameraPosition camPosition = const CameraPosition(
    target: LatLng(21.2094892, 72.8317058),
    zoom: 15.00,
  );


  @override
  void onInit() {
    Global.initPlacePicker();
    askPermissionAndGetLocation();
    super.onInit();
  }


  askPermissionAndGetLocation()async{
    var status = await Permission.location.status;
    if (status != PermissionStatus.granted) {
      var permissionStatus = await Permission.location.request();
      if(permissionStatus.isGranted){
        whenPermissionGranted();
      }else{
        Global.showToast("Please allow permission in setting");
      }
    }else{
      whenPermissionGranted();
    }
  }

  whenPermissionGranted() async{
    var position = await GeolocatorPlatform.instance.getCurrentPosition(locationSettings: AndroidSettings(accuracy: LocationAccuracy.high));
    initLatLong = LatLng(position.latitude, position.longitude);
    moveMapCamera(15);
  }

  addPinOnMap(LatLng position, String id, BitmapDescriptor descriptor) {
    MarkerId markerId = MarkerId(id);
    Marker marker = Marker(markerId: markerId, icon: descriptor, position: position);
    markers[markerId] = marker;
  }


  Future<bool> addWayPointsOnMap(LatLng latLong) async{
    String clickAddress = await Global.latLongToAddress(latLong);
    routesList.addData(PolylineWayPoint(location: "${latLong.latitude},${latLong.longitude}"), latLong, clickAddress);
    int wayPointsLength = routesList.wayPointsPoly.length;

    if(wayPointsLength >= 2){
      isAddPlanTime(false);
      isAddPlanTime(true);
    }
    updateBottomSheet();

    BitmapDescriptor bitmapDescriptor = await CircleMaker(Helper.dotImg,wayPointsLength,width: 70,height: 70);
    String tempMarkerId = "pin${wayPointsLength}";
    addPinOnMap(
      latLong,
      tempMarkerId,
      bitmapDescriptor,
    );
    updateMap();

    if(wayPointsLength == 1){
      firstLatLong = LatLng(latLong.latitude, latLong.longitude);
      return true;
    }else if(wayPointsLength == 2){
      originLatLong = PointLatLng(firstLatLong.latitude,firstLatLong.longitude);
      destinationLatLong = PointLatLng(latLong.latitude,latLong.longitude);

      await manageWayPointsWhileAdding(false);
      enableSaveBtn(false);
      return true;
    }else if(wayPointsLength >= 3){
      originLatLong = PointLatLng(firstLatLong.latitude,firstLatLong.longitude);

      if(isOneWaySelected.value){
        destinationLatLong = PointLatLng(latLong.latitude,latLong.longitude);
      }else{
        destinationLatLong = originLatLong;
      }

      polylineCoordinates = [];
      polylines.clear();
      updateMap();

      await manageWayPointsWhileAdding(false);
      return true;
    }else{
      return true;
    }
  }


  manageWayPointsWhileAdding(bool isEditOrDelete) async {

    if(isEditOrDelete){

      for (int i = 0; i < routesList.wayPointsLatLng.length; i++) {
        int wayPointsLength = i+1;
        BitmapDescriptor bitmapDescriptor = await CircleMaker(Helper.dotImg,wayPointsLength,width: 70,height: 70);
        String tempMarkerId = "pin${wayPointsLength}";
        MarkerId markerId = MarkerId(tempMarkerId);
        Marker marker = Marker(markerId: markerId, icon: bitmapDescriptor, position: routesList.wayPointsLatLng[i]);
        markers[markerId] = marker;
      }
      updateMap();
    }

    for (int i = 0; i < routesList.wayPointsLatLng.length; i += 20) {
      final batch = routesList.wayPointsLatLng.sublist(i, i + 20 > routesList.wayPointsLatLng.length ? routesList.wayPointsLatLng.length : i + 20);
      if(i != 0){
        batch.insert(0,routesList.wayPointsLatLng[i-1]);
      }
      bool isLastCall = i+20 >= routesList.wayPointsLatLng.length;
      await drawRouteOnMap(batch,isLastCall);
    }
  }

  Future<bool> drawRouteOnMap(List<LatLng> waypointsBatch, bool isLastCall) async {

    PointLatLng originPlace = PointLatLng(waypointsBatch.first.latitude, waypointsBatch.first.longitude);
    late PointLatLng destPlace;

    if(isOneWaySelected.value){
      destPlace = PointLatLng(waypointsBatch.last.latitude, waypointsBatch.last.longitude);
    }else{
      if(routesList.wayPointsLatLng.length >= 3){
        if(isLastCall){
          destPlace = originLatLong;
        }else{
          destPlace = PointLatLng(waypointsBatch.last.latitude, waypointsBatch.last.longitude);
        }
      }else{
        destPlace = PointLatLng(waypointsBatch.last.latitude, waypointsBatch.last.longitude);
      }
    }

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: Global.mapApiKey,
      request: PolylineRequest(
          origin: originPlace,
          destination: destPlace,
          mode: TravelMode.driving,
          wayPoints: routesList.wayPointsPoly.length >= 3 ?  waypointsBatch
              .sublist(1, waypointsBatch.length)
              .map((point) => PolylineWayPoint(location: '${point.latitude},${point.longitude}'))
              .toList() : []
      ),
    );

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
      color: Helper.polyLineColor,
      width: 4,
    );
    polylines[id] = polyline;
    updateMap();
    await Future.delayed(const Duration(milliseconds: 1));
    return true;
  }


  void fetchPlace(
      String placeName, String placeId, List<PlaceField> placeFields) async {
    try {
      final result = await Global.places.fetchPlace(placeId, fields: placeFields);

      var placeData = result.place;

      initLatLong = LatLng(placeData!.latLng!.lat, placeData.latLng!.lng);
      locationSearchTF.text = placeName;
      moveMapCamera(15);

      refreshListData(true);
      refreshListData(false);
    } catch (err) {
      refreshListData(true);
      refreshListData(false);
    }
  }

  moveMapCamera(double zoomValue) async {
    final c = await mapController.future;

    camPosition = CameraPosition(
      target: initLatLong,
      zoom: zoomValue,
    );
    c.animateCamera(CameraUpdate.newCameraPosition(camPosition));
  }

  makePlanBtnDeactive(){
    enablePlanBtn(true);
    enableClearBtn(false);
    refreshBtnView(true);
    refreshBtnView(false);
  }

  makePlanBtnActive(){
    enablePlanBtn(false);
    enableClearBtn(true);
    enableSaveBtn(true);
    isEditTime(false);
    isAddPlanTime(false);
    openBottomSheet(false);
    polylineCoordinates = [];
    routesList.removeAllData();
    polylines.clear();
    markers.clear();
    updateMap();
    refreshBtnView(true);
    refreshBtnView(false);
  }

  saveBtnPressed(){
    List<SaveRouteModel> tempDataForSave = [];
    tempDataForSave.add(SaveRouteModel(name: nameForSaveDataTF.text.trim().toString(), wayPointsForSaveData: routesList.wayPointsLatLng,allAddress: routesList.allAddress,routeType: isOneWaySelected.value));
    SPHelper.saveDataToSharedPref(tempDataForSave);
    nameForSaveDataTF.text = "";
    Get.back();
    makePlanBtnActive();
  }

  updateMap(){
    refreshMap(true);
    refreshMap(false);
  }

  updateRouteTypeValue(String s, bool bool) {
    routeSelectedValue = s;
    isOneWaySelected(bool);
    wayDialogRefresh(true);
    wayDialogRefresh(false);
  }

  late SaveRouteModel editTimeData;
  editRoute(SaveRouteModel savedRouteDatas) async{
    makePlanBtnDeactive();
    editTimeData = savedRouteDatas;
    List tempWays = editTimeData.wayPointsForSaveData;

    isOneWaySelected(editTimeData.routeType);
    LatLng firstLatLong = Global.latLongSeparator(tempWays[0].toString());
    initLatLong = LatLng(firstLatLong.latitude,firstLatLong.longitude);
    originLatLong = PointLatLng(firstLatLong.latitude,firstLatLong.longitude);
    isEditTime(true);

    manageWayPointsWhileEdit();

  }

  manageWayPointsWhileEdit() async {

    for (int i = 0; i < editTimeData.wayPointsForSaveData.length; i++) {
      LatLng tempLatLong;
      if(editTimeData.wayPointsForSaveData[i].runtimeType != LatLng){
        tempLatLong = Global.latLongSeparator(editTimeData.wayPointsForSaveData[i].toString());
      }else{
        tempLatLong = editTimeData.wayPointsForSaveData[i];
      }
      routesList.addData(PolylineWayPoint(location: "${tempLatLong.latitude},${tempLatLong.longitude}"), tempLatLong, editTimeData.allAddress[i]);

      BitmapDescriptor bitmapDescriptor = await CircleMaker(Helper.dotImg, routesList.wayPointsLatLng.length, width: 70, height: 70);
      String tempMarkerId = "pin${routesList.wayPointsLatLng.length}";
      addPinOnMap(
        tempLatLong,
        tempMarkerId,
        bitmapDescriptor,
      );
    }
    updateMap();

    for (int i = 0; i < routesList.wayPointsLatLng.length; i += 20) {
      final batch = routesList.wayPointsLatLng.sublist(i, i + 20 > routesList.wayPointsLatLng.length ? routesList.wayPointsLatLng.length : i + 20);
      if(i != 0){
        batch.insert(0,routesList.wayPointsLatLng[i-1]);
      }

      bool isLastCall = i+20 >= routesList.wayPointsLatLng.length;
      await editTimeDrawRouteOnMap(batch,isLastCall);
    }

    updateBottomSheet();
    enableSaveBtn(false);
    Set<Polyline> tempPolyLine = {};
    polylines.forEach((key, value) {
      tempPolyLine.add(value);
    });
    Global.setAllMarkerCenterInMap(tempPolyLine,mapController);
  }

  Future<bool> editTimeDrawRouteOnMap(List<LatLng> waypointsBatch, bool isLastCall) async {

    PointLatLng originPlace = PointLatLng(waypointsBatch.first.latitude, waypointsBatch.first.longitude);
    late PointLatLng destPlace;

    if(isOneWaySelected.value){
      destPlace = PointLatLng(waypointsBatch.last.latitude, waypointsBatch.last.longitude);
    }else{
      if(routesList.wayPointsLatLng.length >= 3){
        if(isLastCall){
          destPlace = originLatLong;
        }else{
          destPlace = PointLatLng(waypointsBatch.last.latitude, waypointsBatch.last.longitude);
        }
      }else{
        destPlace = PointLatLng(waypointsBatch.last.latitude, waypointsBatch.last.longitude);
      }
    }

    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      googleApiKey: Global.mapApiKey,
      request: PolylineRequest(
          origin: originPlace,
          destination: destPlace,
          mode: TravelMode.driving,
          wayPoints: routesList.wayPointsPoly.length >= 3 ?  waypointsBatch
              .sublist(1, waypointsBatch.length)
              .map((point) => PolylineWayPoint(location: '${point.latitude},${point.longitude}'))
              .toList() : []
      ),
    );

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
      color: Helper.polyLineColor,
      width: 4,
    );
    polylines[id] = polyline;
    updateMap();
    await Future.delayed(const Duration(milliseconds: 1));
    return true;
  }


  void updateRoute() async{
    SaveRouteModel tempData = SaveRouteModel(name: editTimeData.name, wayPointsForSaveData: routesList.wayPointsLatLng, allAddress: routesList.allAddress,routeType: editTimeData.routeType);
    isOneWaySelected(tempData.routeType);
    editTimeData = tempData;
    routesList.removeAllData();
    polylineCoordinates = [];
    polylines.clear();
    markers.clear();

    LatLng firstLatLong = tempData.wayPointsForSaveData[0];
    initLatLong = LatLng(firstLatLong.latitude,firstLatLong.longitude);
    manageWayPointsWhileEdit();
  }

  editAndUpdateData(){
    SaveRouteModel tempData = SaveRouteModel(name: editTimeData.name, wayPointsForSaveData: routesList.wayPointsLatLng,allAddress: routesList.allAddress ,routeType: editTimeData.routeType);
    SPHelper.updateDataToSharedPref(tempData,nameForSaveDataTF.text.trim().toString());
    nameForSaveDataTF.text = "";
    Get.back();
    makePlanBtnActive();
    Global.showToast("Route Updated SuccessFully");
  }


  deleteItemFromBottomSheet(dynamic item,int index) async {
    if(routesList.wayPointsLatLng.length > 2){

      if(isEditTime.value){
        routesList.removeSingleData(index);
        updateRoute();
      }else {
        routesList.removeSingleData(index);
        List waysForEditRoutes = routesList.wayPointsLatLng;
        isOneWaySelected(isOneWaySelected.value);
        polylineCoordinates = [];
        polylines.clear();
        markers.clear();

        LatLng firstLatLong = waysForEditRoutes[0];
        initLatLong = LatLng(firstLatLong.latitude,firstLatLong.longitude);
        await manageWayPointsWhileAdding(true);
      }

      updateBottomSheet();
      updateMap();
    }else{
      Global.showToast("Min 2 Location Required");
    }
  }

  void updateBottomSheetSwipeUpDown() async{
    if(isEditTime.value){
      updateRoute();
    }else{
      isOneWaySelected(isOneWaySelected.value);
      SaveRouteModel tempData = SaveRouteModel(name: "tempName", wayPointsForSaveData: routesList.wayPointsLatLng, allAddress: routesList.allAddress,routeType: isOneWaySelected.value);
      polylineCoordinates = [];
      polylines.clear();
      markers.clear();
      LatLng firstLatLong = tempData.wayPointsForSaveData[0];
      initLatLong = LatLng(firstLatLong.latitude,firstLatLong.longitude);
      await manageWayPointsWhileAdding(true);
    }
    updateBottomSheet();
    updateMap();
  }

  updateBottomSheet(){
    refreshBottomSheet(true);
    refreshBottomSheet(false);
  }

  void editTimeAddWaypoints(LatLng tempLatLong) async{
    String clickAddress = await Global.latLongToAddress(tempLatLong);
    routesList.addData(PolylineWayPoint(location: "${tempLatLong.latitude},${tempLatLong.longitude}"), tempLatLong, clickAddress);
    updateRoute();
  }
}
