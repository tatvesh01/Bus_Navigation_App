import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/saveRouteModel.dart';

class SPHelper {
  static late SharedPreferences prefs;
  static String saveRoutePrefStr = "saveRoutePref";

  static sharedPrefInit() async {
    prefs = await SharedPreferences.getInstance();
  }

  static saveDataToSharedPref(List<SaveRouteModel> saveDataModel) async {
    List<SaveRouteModel> previousSavedData = await getDataToSharedPref();
    previousSavedData.addAll(saveDataModel);
    String encodedMap = json.encode(previousSavedData);
    await prefs.setString(saveRoutePrefStr, encodedMap);
  }

  static Future<List<SaveRouteModel>> getDataToSharedPref() async {
    String tempString = await prefs.getString(saveRoutePrefStr) ?? "[]";
    List<dynamic> retrivedMap = json.decode(tempString);
    List<SaveRouteModel> getAllSavedData = [];

    retrivedMap.forEach((element) {
      SaveRouteModel retrivedData = SaveRouteModel.fromJson(element);
      getAllSavedData.add(retrivedData);
    });
    return getAllSavedData;
  }

  static void deleteSingleDataToSharedPref(int index) async {
    List<SaveRouteModel> previousSavedData = await getDataToSharedPref();
    previousSavedData.removeAt(index);
    await prefs.setString(saveRoutePrefStr, "[]");
    saveDataToSharedPref(previousSavedData);
  }

  static Future<SaveRouteModel> editSingleDataToSharedPref(int index) async {
    List<SaveRouteModel> previousSavedData = await getDataToSharedPref();
    SaveRouteModel dataForEditRoutes = previousSavedData[index];
    return dataForEditRoutes;
  }

  static updateDataToSharedPref(SaveRouteModel saveDataModel, String newName) async {
    List<SaveRouteModel> previousSavedData = await getDataToSharedPref();

    int itemIndex = previousSavedData.indexWhere((item) => item.name == saveDataModel.name);
    previousSavedData.removeAt(itemIndex);
    saveDataModel.name = newName;
    previousSavedData.insert(itemIndex,saveDataModel);
    String encodedMap = json.encode(previousSavedData);
    await prefs.setString(saveRoutePrefStr, encodedMap);
  }

}
