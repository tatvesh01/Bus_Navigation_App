import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:map_navigation/Controller/saved_data_screen_controller.dart';
import 'package:map_navigation/Ui/test_screen.dart';
import '../Common/BaseAppBar.dart';
import '../Models/saveRouteModel.dart';
import '../Utils/helper.dart';
import '../Controller/splash_screen_controller.dart';
import '../Utils/global.dart';
import '../Utils/sPHelper.dart';
import 'map_navigation_screen.dart';

class SavedDataScreen extends StatelessWidget {
  SavedDataScreen({Key? key}) : super(key: key);

  SavedDataScreenController savedDataScreenController = Get.put(SavedDataScreenController());

  @override
  Widget build(BuildContext context) {

    Global.deviceSize(context);

    return Scaffold(
      appBar: const BaseAppBar(title: 'Saved Data', widgets: [],),

      body: Container(
        height: Global.sHeight,
        width: Global.sWidth,
        color: Helper.bgColor,
        child: Center(child:
        Obx(()=> savedDataScreenController.refreshList.value?
        const SizedBox() :
        savedDataScreenController.savedData.isEmpty ?
        Text(
          "No Data Found",
          style: TextStyle(color: Helper.blackColor, fontSize: 18,fontWeight: FontWeight.w500),
        ):
        Padding(
          padding: const EdgeInsets.all(10),
          child: ListView.builder(
              itemCount: savedDataScreenController.savedData.length,
              itemBuilder: (BuildContext context, int index) {

                SaveRouteModel indexedData = savedDataScreenController.savedData[index];

                return Padding(
                  padding: const EdgeInsets.all(5),
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        height: 100,
                        color: Helper.lightGreyColor,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                flex: 7,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${indexedData.name}",
                                      style: TextStyle(color: Helper.blackColor, fontSize: 16,fontWeight: FontWeight.w500),
                                      maxLines: 1,
                                    ),
                                    Text(
                                      "${indexedData.wayPointsForSaveData.length} WayPoints",
                                      style: TextStyle(color: Helper.blackColor, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),


                              Flexible(
                                flex: 3,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [

                                    InkWell(
                                        onTap: () async{

                                          SaveRouteModel mapDataForNavigation = await SPHelper.editSingleDataToSharedPref(index);
                                          Get.to(()=>MapNavigationScreen(),arguments: [mapDataForNavigation]);

                                        },
                                        child: const Icon(Icons.directions_bus,size: 30,)),

                                    SizedBox(height: 15,),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        InkWell(
                                          onTap: () async {
                                            SaveRouteModel singleData = await SPHelper.editSingleDataToSharedPref(index);
                                            Get.back(result: singleData);
                                          },
                                            child: const Icon(Icons.edit,size: 25,)),

                                        const SizedBox(width: 7,),

                                        InkWell(
                                          onTap: (){
                                            showDeleteDialog(context,index);
                                          },
                                            child: const Icon(Icons.delete,size: 25,)),

                                        const SizedBox(width: 7,),

                                        InkWell(
                                          onTap: ()async{
                                            SaveRouteModel singleData = await SPHelper.editSingleDataToSharedPref(index);
                                            savedDataScreenController.shareJsonFile(singleData);
                                          },
                                            child: const Icon(Icons.share,size: 25,)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            ],
                          ),
                        ),
                      )
                  ),
                );

              }),
        )
        ),

        ),
      ),
    );
  }

  showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Alert!",
            style: TextStyle(color: Helper.redColor,fontWeight: FontWeight.w500, fontSize: 20),
          ),
          content: Container(
            height: 50,
            width: 200,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 9.0),
                  child: Text(
                    "Are your sure to delete?",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                  ),
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
                'No',
                style: TextStyle(color: Helper.whiteColor, fontSize: 15),
              ),
              onPressed: () {
                Get.back();
              },
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Helper.lightBlueColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Text(
                'Yes',
                style: TextStyle(color: Helper.whiteColor, fontSize: 15),
              ),
              onPressed: () {
                savedDataScreenController.deleteSingleRecord(index);
                Get.back();
              },
            ),
          ],
        );
      },
    );
  }
}
