import 'dart:convert';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../Models/saveRouteModel.dart';
import '../Utils/global.dart';
import '../Utils/sPHelper.dart';
import 'package:share_plus/share_plus.dart';

class SavedDataScreenController extends GetxController{

  RxBool refreshList = false.obs;
  List<SaveRouteModel> savedData = [];

  @override
  void onInit() {

    getSavedDataFromPref();

    super.onInit();
  }

  Future<void> getSavedDataFromPref() async {
    savedData = await SPHelper.getDataToSharedPref();
    updateList();
  }

  void deleteSingleRecord(int index){
    savedData.removeAt(index);
    SPHelper.deleteSingleDataToSharedPref(index);
    updateList();
  }

  void updateList() {
    refreshList(true);
    refreshList(false);
  }

  void shareJsonFile(SaveRouteModel routesData) async{

    Map<String, dynamic> valueMap = routesData.toJson();
    String? filePath = await saveMapToJsonTemp(valueMap,routesData.name);
    if(filePath != null){
      await shareFile(filePath);
      //await readJsonFile(filePath);
    }
  }

  Future<String?> saveMapToJsonTemp(Map<String, dynamic> map, String fileName) async {
    try {
      String jsonString = jsonEncode(map);
      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/${fileName.removeAllWhitespace}.json';
      final file = File(path);
      await file.writeAsString(jsonString);
      return file.path;
    } catch (e) {
      Global.showToast("Error saving file: $e");
      return null;
    }
  }

  Future<void> shareFile(String filePath) async {
    try {
      await Share.shareFiles([filePath], text: 'Check out this file!');
    } catch (e) {
      Global.showToast("Error sharing file: $e");
    }
  }

  Future<void> readJsonFile(String filePath) async {
    try {

      final file = File(filePath);
      final contents = await file.readAsString();

      final jsonData = jsonDecode(contents);

      print("jsonData => ${jsonData}");
    } catch (e) {
      print('Error reading JSON file: $e');
    }
  }
}