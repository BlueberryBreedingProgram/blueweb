import 'package:flutter/material.dart';
import 'dashboard.dart';
import 'fq.dart'; 
import 'score.dart';
import 'app.dart';
import 'settings.dart';
import 'database.dart';
import 'sensory.dart';

void navigateToPage(int index, BuildContext context) {
  Widget nextPage;
  nextPage = Dashboard();

  switch (index) {
    case 0:
      nextPage = Dashboard();
      break;
    case 1:
      nextPage = FruitQuality();
      break;
    case 2:
      nextPage = DatabasePage(selectedIndex: index, onDestinationSelected: (int index) => navigateToPage(index, context));
      break;
    case 3:
      nextPage = SensoryPage(selectedIndex: index, onDestinationSelected: (int index) => navigateToPage(index, context));
      break;
    case 4:
      nextPage = ScorePage(selectedIndex: index, onDestinationSelected: (int index) => navigateToPage(index, context));
      break;
    case 5:
      nextPage = AppPage(selectedIndex: index, onDestinationSelected: (int index) => navigateToPage(index, context));
      break;
    case 6:
      nextPage = SettingsPage(selectedIndex: index, onDestinationSelected: (int index) => navigateToPage(index, context));
      break;
  }

  if (nextPage != null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => nextPage),
    );
  }
}
