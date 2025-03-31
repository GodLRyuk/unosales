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

class SaveFRInAppTour {
  Future<SharedPreferences> data = SharedPreferences.getInstance();

  void savedFRAppTourStatus() async {
    final value = await data;
    value.setBool("saveFRTour", true);
  }
  Future<bool> getFRAppTourStatus() async
  {
    final value = await data;
    if (value.containsKey("saveFRTour")) {
      bool? getData = value.getBool("saveFRTour");
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
class savedAppFRLeadDashboardTourStatus {
  Future<SharedPreferences> data = SharedPreferences.getInstance();

  void savedAppRFTourStatus() async {
    final value = await data;
    value.setBool("saveFRLeadDashboardTour", true);
  }
  Future<bool> getAppFRLeadDashbloardTourStatus() async
  {
    final value = await data;
    if (value.containsKey("saveFRLeadDashboardTour")) {
      bool? getData = value.getBool("saveFRLeadDashboardTour");
      return getData!;  
    }
    else
    {
      return false;
    }
  }
}
