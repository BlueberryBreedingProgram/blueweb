import 'package:flutter/material.dart';
import 'score.dart';

class NavigationRailWidget extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const NavigationRailWidget({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      labelType: NavigationRailLabelType.all,
      leading: Column(
        children: <Widget>[
          SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.transparent,
              backgroundImage: AssetImage('berries.png'),
            ),
          ),
          SizedBox(height: 8),
        ],
      ),
      onDestinationSelected: onDestinationSelected,
      destinations: const <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.grain),
          label: Text('Fruit Quality'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.grid_4x4_rounded),
          label: Text('Database'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.camera),
          label: Text('Sensory Panels'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.ballot), 
          label: Text('BlueScore'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.apps),
          label: Text('App Store'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],

    );
  }
}

