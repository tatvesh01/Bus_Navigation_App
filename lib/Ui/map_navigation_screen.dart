import 'dart:async';
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:get/get.dart';
import 'package:map_navigation/Common/BaseAppBar.dart';
import 'package:map_navigation/Controller/map_navigation_screen_controller.dart';
import '../Utils/helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import '../Utils/global.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapNavigationScreen extends StatelessWidget {
  MapNavigationScreen({Key? key}) : super(key: key);

  MapNavigationScreenController mapNavSCont = Get.put(MapNavigationScreenController());

  @override
  Widget build(BuildContext context) {
    Global.deviceSize(context);
    return WillPopScope(
      onWillPop: () async{
        mapNavSCont.mapController = Completer();
        mapNavSCont.locationSubscription.cancel();
        try{mapNavSCont.speedCalcListner.cancel();}catch(e){}
        Global.stopKeepScreenOn();
        return true;
      },
      child: Scaffold(
        appBar: BaseAppBar(title: 'Navigation', widgets: [Obx(()=> mapNavSCont.navigationStarted.value ? !mapNavSCont.refreshKmTxt.value ? Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text("${mapNavSCont.speedInKm.value} km/h",style: TextStyle(color: Helper.whiteColor,fontSize: 15,fontWeight: FontWeight.w500),),
        ):SizedBox() :SizedBox())]),

        body: Container(
          height: Global.sHeight,
          width: Global.sWidth,
          color: Helper.bgColor,
          child: Stack(
            children: [
              mapBox(),
              navigationButton(),

            ],
          ),
        ),
      ),
    );
  }

  Widget mapBox() {
    return Obx(() => mapNavSCont.refreshMap.value
        ? SizedBox()
        : Container(
      height: Global.sHeight-100,
      width: Global.sWidth,
      child: Listener(
        onPointerDown: (PointerDownEvent event){
          mapNavSCont.isDragged(true);
        },
        child: GoogleMap(
          //myLocationEnabled: true,
          mapType: MapType.terrain,
          initialCameraPosition: mapNavSCont.camPosition,
          polylines:
          Set<Polyline>.of(mapNavSCont.polylines.values),
          markers: Set<Marker>.of(mapNavSCont.markers.values),
          onCameraMove: mapNavSCont.whenCameraMove,
          onMapCreated: (GoogleMapController controller) {
            mapNavSCont.googleMapCreated(controller);
          },
        ),
      ),
    ));
  }

  Widget navigationButton() {
    return SizedBox(
      height: Global.sHeight,
      width: Global.sWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [

          //for developer use only
          /*InkWell(
            onTap: (){

              if(mapNavSCont.navigationStartedtemp.value){
                mapNavSCont.navigationStartedtemp(false);
                mapNavSCont.routeTesting();
              }else{
                mapNavSCont.navigationStartedtemp(true);
              }
            },
            child: Container(
              height: 55,
              width: Global.sWidth * 0.4,
              decoration: BoxDecoration(
                  color: Helper.lightBlueColor,
                  borderRadius: BorderRadius.all(Radius.circular(30))
              ),
              child: Obx(()=> Center(child: Text(mapNavSCont.navigationStartedtemp.value ? "Start test" : "Stop test" ,style: TextStyle(color: Colors.white, fontSize: 17,fontWeight: FontWeight.w500),))),
            ),
          ),

          SizedBox(height: 5,),*/

          Obx(()=>
          mapNavSCont.isDragged.value ?
             InkWell(
               onTap: (){
                 mapNavSCont.recenterBtnPressed();
               },
               child: Container(
                height: 55,
                width: Global.sWidth * 0.4,
                decoration: BoxDecoration(
                    color: Helper.lightBlueColor,
                    borderRadius: BorderRadius.all(Radius.circular(30))
                ),
                child: Center(child: Text("Recenter",style: TextStyle(color: Colors.white, fontSize: 17,fontWeight: FontWeight.w500),)),
                           ),
             ):SizedBox(),
          ),
          SizedBox(height: 5,),
          InkWell(
            onTap: (){
              if(mapNavSCont.navigationStarted.value){
                mapNavSCont.navigationStarted(false);
                mapNavSCont.locationSubscription.pause();
                mapNavSCont.speedCalcListner.cancel();
              }else{
                mapNavSCont.navigationStarted(true);
                mapNavSCont.locationSubscription.resume();
                mapNavSCont.showVehicleOnMyLocation();
                mapNavSCont.speedCalculator();
              }
            },
            child: Container(
              height: 55,
              width: Global.sWidth * 0.4,
              decoration: BoxDecoration(
                  color: Helper.lightBlueColor,
                  borderRadius: BorderRadius.all(Radius.circular(30))
              ),
              child: Obx(()=> Center(child: Text(!mapNavSCont.navigationStarted.value ? "Navigation" : "Cancel",style: TextStyle(color: Colors.white, fontSize: 17,fontWeight: FontWeight.w500),))),
            ),
          ),

          SizedBox(height: 15,),

        ],
      ),
    );
  }
}
