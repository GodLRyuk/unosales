import 'package:shared_preferences/shared_preferences.dart';

class SaveInAppTour {
  Future<SharedPreferences> data = SharedPreferences.getInstance();

  void savedAppTourStatus() async {
    final value = await data;
    value.setBool("saveTour", true);
  }
  Future<bool> getAppTourStatus() async
  {
    final value = await data;
    if (value.containsKey("saveTour")) {
      bool? getData = value.getBool("saveTour");
      return getData!;  
    }
    else
    {
      return false;
    }
  }
}

class savedAppLeadDashboardTourStatus {
  Future<SharedPreferences> data = SharedPreferences.getInstance();

  void savedAppLeadDashbTourStatus() async {
    final value = await data;
    value.setBool("saveLeadDashboardTour", true);
  }
  Future<bool> getAppLeadDashbloardTourStatus() async
  {
    final value = await data;
    if (value.containsKey("saveLeadDashboardTour")) {
      bool? getData = value.getBool("saveLeadDashboardTour");
      return getData!;  
    }
    else
    {
      return false;
    }
  }
}
