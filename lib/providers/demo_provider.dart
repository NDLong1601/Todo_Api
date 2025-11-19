import 'package:flutter/material.dart';

class DemoProvider extends ChangeNotifier {
  /// properties -> state
  int counter = 0;
  int age = 20;
  ////
  ///
  ///

  /// logic function
  void increaseCounter() {
    counter++;
    print('counter $counter');
    notifyListeners();
  }

  void decreaseCounter() {
    counter--;
    notifyListeners();
  }

  void increaseAge() {
    age++;
    notifyListeners();
  }

  void decreaseAge() {
    age--;
    notifyListeners();
  }
}
