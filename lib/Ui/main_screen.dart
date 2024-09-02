import 'package:flutter/cupertino.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:map_navigation/Ui/saved_data_screen.dart';
import '../Utils/helper.dart';
import '../Utils/global.dart';
import 'package:map_navigation/Controller/main_screen_controller.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class MainScreen extends StatelessWidget {
  MainScreen({Key? key}) : super(key: key);

  MainScreenController mainSCont = Get.put(MainScreenController());


  final List<PlaceField> _placeFields = [
    PlaceField.Address,
    PlaceField.AddressComponents,
    PlaceField.BusinessStatus,
    PlaceField.Id,
    PlaceField.Location,
    PlaceField.Name,
  ];
  List<AutocompletePrediction>? _predictions;

  @override
  Widget build(BuildContext context) {
    Global.deviceSize(context);
    mainSCont.tempContext = context;
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(),
          child: Container(
            height: Global.sHeight,
            width: Global.sWidth,
            color: Helper.bgColor,
            child: Stack(
              children: [
                mapBox(),
                Column(
                  children: [
                    allButton(),
                    searchBar(),
                    locationList(),
                  ],
                ),
                bottomSheetView(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget locationList() {
    return Obx(() => mainSCont.refreshListData.value
        ? SizedBox()
        : Column(
            mainAxisSize: MainAxisSize.min,
            children:
            (_predictions ?? []).map(locationItem).toList(growable: false),
          ));
  }

  Widget searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Container(
        height: 50,
        width: Global.sWidth,
        decoration: BoxDecoration(
            border: Border.all(color: Helper.greyColor, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(5))),
        child: TextField(
          controller: mainSCont.locationSearchTF,
          decoration: InputDecoration(
              hintText: 'Search Location Here',
              contentPadding: EdgeInsets.only(left: 10)),
          onSubmitted: (value) async {
            final places = FlutterGooglePlacesSdk(Global.mapApiKey);
            var predictions = await places.findAutocompletePredictions(value);
            _predictions = predictions.predictions;
            mainSCont.refreshListData(true);
            mainSCont.refreshListData(false);
          },
        ),
      ),
    );
  }

  Widget mapBox() {
    return Obx(() => mainSCont.refreshMap.value
        ? SizedBox()
        : Container(
            height: Global.sHeight - 150,
            width: Global.sWidth,
            margin: EdgeInsets.only(top: 100),
            child: GoogleMap(
              myLocationEnabled: true,
              mapType: MapType.terrain,
              polylines:
                  Set<Polyline>.of(mainSCont.polylines.values),
              markers: Set<Marker>.of(mainSCont.markers.values),
              initialCameraPosition: mainSCont.camPosition,
              onTap: (argument) {
                if (mainSCont.enablePlanBtn.value) {
                  if(!mainSCont.isEditTime.value){
                    mainSCont.addWayPointsOnMap(argument);
                  }else{
                    mainSCont.editTimeAddWaypoints(argument);
                  }
                }
              },
              onMapCreated: (GoogleMapController controller) {
                mainSCont.mapController.complete(controller);
              },
            ),
          ));
  }

  Widget locationItem(AutocompletePrediction item) {
    return InkWell(
      onTap: () => _onItemClicked(item),
      child: Container(
        color: Helper.whiteColor,
        padding: EdgeInsets.symmetric(horizontal: 15),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            item.fullText,
            style: TextStyle(fontSize: 15, color: Helper.blackColor),
            maxLines: 1,
          ),
          Text('${item.primaryText} - ${item.secondaryText}',
              style: TextStyle(fontSize: 12, color: Helper.greyColor),
              maxLines: 1),
          Divider(
            thickness: 1,
            color: Helper.greyColor,
          ),
        ]),
      ),
    );
  }

  void _onItemClicked(AutocompletePrediction item) {
    mainSCont.fetchPlace(item.fullText, item.placeId, _placeFields);
    _predictions = [];
  }

  Widget allButton() {
    return Obx(() => !mainSCont.refreshBtnView.value
        ? SizedBox(
            height: 50,
            width: Global.sWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Helper.lightBlueColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: mainSCont.enablePlanBtn.value
                      ? null
                      : showRouteTypeDialog,
                  child: const Text(
                    'Plan',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Helper.lightBlueColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: mainSCont.enableClearBtn.value
                      ? null
                      : mainSCont.makePlanBtnActive,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Helper.lightBlueColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onPressed: mainSCont.enableSaveBtn.value
                      ? null
                      : showSaveDataDialog,
                  child: Text(
                    !mainSCont.isEditTime.value? 'Save':'Update',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Helper.lightBlueColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text(
                    '->',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                  onPressed: () async{
                    var savedRouteData = await Get.to(() => SavedDataScreen());
                    if(savedRouteData != null){
                      mainSCont.editRoute(savedRouteData);
                    }
                  },
                ),
              ],
            ),
          )
        : SizedBox());
  }

  showSaveDataDialog() {

    if(mainSCont.isEditTime.value){
      mainSCont.nameForSaveDataTF.text = mainSCont.editTimeData.name;
    }

    showDialog(
      context: mainSCont.tempContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Enter Name",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
          ),
          content: Container(
            height: 80,
            width: 200,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 9.0),
                  child: TextField(
                      controller: mainSCont.nameForSaveDataTF,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8),
                          ),
                        ),
                        labelText: "Enter Name",
                      )),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Helper.lightBlueColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text(
                'SAVE',
                style: TextStyle(color: Helper.whiteColor, fontSize: 15),
              ),
              onPressed: () {
                if(!mainSCont.isEditTime.value){
                  mainSCont.saveBtnPressed();
                }else{
                  mainSCont.editAndUpdateData();
                }
              },
            ),
          ],
        );
      },
    );
  }

  showRouteTypeDialog() {
    showDialog(
      context: mainSCont.tempContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Select Route Type",
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
          ),
          content: Obx(()=>mainSCont.wayDialogRefresh.value ? SizedBox():Container(
            height: 100,
            width: 200,
            child: Column(
              children: [

                GestureDetector(
                  onTap: (){
                    mainSCont.updateRouteTypeValue("One Way",true);
                  },
                  child: Row(
                    children: [
                      Radio<String>(
                          activeColor: Helper.lightBlueColor,
                          value: "One Way",
                          groupValue: mainSCont.routeSelectedValue,
                          onChanged: (value){
                            mainSCont.updateRouteTypeValue("One Way",true);
                          }
                      ),

                      Text(
                        "One Way",
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                      )
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: (){
                    mainSCont.updateRouteTypeValue("Round Trip",false);
                  },
                  child: Row(
                    children: [
                      Radio<String>(
                          activeColor: Helper.lightBlueColor,
                          value: "Round Trip",
                          groupValue: mainSCont.routeSelectedValue,
                          onChanged: (value){
                            mainSCont.updateRouteTypeValue("Round Trip",false);
                          }
                      ),
                      Text(
                        "Round Trip",
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                      )
                    ],
                  ),
                ),

              ],
            ),
          )),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Helper.lightBlueColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text(
                'OK',
                style: TextStyle(color: Helper.whiteColor, fontSize: 15),
              ),
              onPressed: () {
                if(mainSCont.routeSelectedValue == "One Way"){
                  mainSCont.updateRouteTypeValue("One Way",true);
                }else{
                  mainSCont.updateRouteTypeValue("Round Trip",false);
                }
                Get.back();
                mainSCont.makePlanBtnDeactive();
              },
            ),
          ],
        );
      },
    );
  }


  Widget bottomSheetView() {

    return Obx(()=> mainSCont.isEditTime.value || mainSCont.isAddPlanTime.value ? SlidingUpPanel(
        controller: mainSCont.slidingPanelController,
        minHeight: 200,
        maxHeight: 500,
        borderRadius: BorderRadius.only(topRight: Radius.circular(20),topLeft: Radius.circular(20)),
        isDraggable: true,
        onPanelClosed: (){
          mainSCont.openBottomSheet(false);
        },
        onPanelOpened: (){
          mainSCont.openBottomSheet(true);
        },
        panel: !mainSCont.refreshBottomSheet.value? Column(
          children: [
            SizedBox(height: 15,),
            Stack(
              alignment: Alignment.center,
              children: [

                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 7,
                    width: 35,
                    decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(Radius.circular(10))
                    ),
                  ),
                ),

                Align(
                  alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 15),
                      child: InkWell(
                        onTap: (){
                          if(mainSCont.slidingPanelController.isPanelOpen){
                            mainSCont.slidingPanelController.close();
                            mainSCont.openBottomSheet(false);
                          }else{
                            mainSCont.slidingPanelController.open();
                            mainSCont.openBottomSheet(true);
                          }
                        },
                          child: Icon(!mainSCont.openBottomSheet.value ? Icons.arrow_circle_up : Icons.arrow_circle_down, size: 30,)),
                    )),
              ],
            ),
            SizedBox(height: 10,),

            SizedBox(
              height: 400,
              child: ReorderableListView(
                children: mainSCont.routesList.wayPointsLatLng.map((item) {
                  var tempIndex = mainSCont.routesList.wayPointsLatLng.indexOf(item);

                  return ListTile(key: Key("${item}"), title: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        height: 22,
                        width: 22,
                        decoration: BoxDecoration(
                          color: Helper.blackColor,
                          borderRadius: BorderRadius.circular(50)
                        ),
                          child: Center(child: Text("${tempIndex+1}",style: TextStyle(fontSize: 14,fontWeight: FontWeight.w500,color: Helper.whiteColor),))),

                      SizedBox(width: 5,),
                      Flexible(child: Text("${mainSCont.routesList.allAddress[tempIndex]}", maxLines: 2,style: TextStyle(fontSize: 15,fontWeight: FontWeight.w500),)),
                    ],
                  ), trailing: InkWell(onTap: (){

                    mainSCont.deleteItemFromBottomSheet(item,tempIndex);

                  },child: Icon(Icons.delete,)),leading: Icon(Icons.menu,size: 30),);
                }).toList(),

                onReorder: (int start, int current) {
                  if (start < current) {
                    int end = current - 1;
                    dynamic startItem = mainSCont.routesList.wayPointsLatLng[start];
                    int i = 0;
                    int local = start;
                    do {
                      //int tempNumber = ++local;
                      mainSCont.routesList.wayPointsLatLng[local] = mainSCont.routesList.wayPointsLatLng[++local];
                      i++;
                    } while (i < end - start);
                    mainSCont.routesList.wayPointsLatLng[end] = startItem;
                  } else if (start > current) {
                    dynamic startItem = mainSCont.routesList.wayPointsLatLng[start];
                    for (int i = start; i > current; i--) {
                      mainSCont.routesList.wayPointsLatLng[i] = mainSCont.routesList.wayPointsLatLng[i - 1];
                    }
                    mainSCont.routesList.wayPointsLatLng[current] = startItem;
                  }
                  mainSCont.updateBottomSheetSwipeUpDown();
                },
              ),
            ),
          ],
        ):SizedBox()
    ) :SizedBox());
  }



}
