import 'package:flutter/material.dart';
import 'package:flutter_widgetkit/flutter_widgetkit.dart';
import 'travel_database.dart'; // Your database helper

class TravelWidgetPage extends StatefulWidget {
  const TravelWidgetPage({super.key});

  @override
  State<TravelWidgetPage> createState() => _TravelWidgetPageState();
}

class _TravelWidgetPageState extends State<TravelWidgetPage> {
  List<Map<String, dynamic>> travelList = [];

  @override
  void initState() {
    super.initState();
    _loadTravels();
  }

  Future<void> _loadTravels() async {
    List<Map<String, dynamic>> travels = await DatabaseHelper().getTravels();
    setState(() {
      travelList = travels;
    });
    _updateWidgetData();
  }

  Future<void> _updateWidgetData() async {
    // Serialize your travel data and save to UserDefaults or AppGroup
    List<Map<String, dynamic>> travels = await DatabaseHelper().getTravels();
    WidgetKit.setItem('travelData', travels, 'group.com.your.app.group');
    WidgetKit.reloadAllTimelines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel List'),
      ),
      body: ListView.builder(
        itemCount: travelList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(travelList[index]['title']),
            subtitle: Text('잔액: ${travelList[index]['balance']}'),
          );
        },
      ),
    );
  }
}
