import 'package:flutter/material.dart';
import 'travel_database.dart';
import 'budget_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TravelPage(),
    );
  }
}

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  List<Map<String, dynamic>> travelList = [];

  @override
  void initState() {
    super.initState();
    _loadTravels();
  }

  Future<void> _loadTravels() async {
    List<Map<String, dynamic>> travels = await DatabaseHelper().getTravels();
    List<Map<String, dynamic>> travelListWithTravellers = [];

    for (var travel in travels) {
      List<Map<String, dynamic>> travellers =
          await DatabaseHelper().getTravellers(travel['id']);
      var travelWithTravellers = Map<String, dynamic>.from(travel);
      travelWithTravellers['travellers'] = travellers;
      travelListWithTravellers.add(travelWithTravellers);
    }

    setState(() {
      travelList = travelListWithTravellers;
    });
  }

  void _addTravel(Map<String, dynamic> travelData) async {
    int travelId = await DatabaseHelper().insertTravel({
      'title': travelData['title'],
      'currency': travelData['currency'],
    });
    for (var traveller in travelData['travellers']) {
      await DatabaseHelper().insertTraveller({
        'travel_id': travelId,
        'name': traveller['name'],
        'contribution': traveller['contribution'],
      });
    }
    _loadTravels();
  }

  void _deleteTravel(int travelId) async {
    await DatabaseHelper().deleteTravel(travelId);
    _loadTravels();
  }

  void _showDeleteConfirmationDialog(BuildContext context, int travelId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: const Text('정말 삭제 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () {
                _deleteTravel(travelId);
                Navigator.of(context).pop();
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToBudgetPage(
      BuildContext context, String travelTitle, int travelId, String currency) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetPage(
            travelTitle: travelTitle, travelId: travelId, currency: currency),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Budget Manager')),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: travelList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(travelList[index]['title']),
                  subtitle:
                      Text('여행자 수: ${travelList[index]['travellers'].length}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmationDialog(
                        context, travelList[index]['id']),
                  ),
                  onTap: () => _navigateToBudgetPage(
                      context,
                      travelList[index]['title'],
                      travelList[index]['id'],
                      travelList[index]['currency']),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _showAddTravelDialog(context),
              child: const Text('여행 추가'),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTravelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddTravelDialog(onAddTravel: _addTravel);
      },
    );
  }
}

class AddTravelDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAddTravel;

  const AddTravelDialog({super.key, required this.onAddTravel});

  @override
  State<AddTravelDialog> createState() => _AddTravelDialogState();
}

class _AddTravelDialogState extends State<AddTravelDialog> {
  final TextEditingController _travelController = TextEditingController();
  final List<TextEditingController> _travellerControllers = [];
  final List<TextEditingController> _contributionControllers = [];
  String _selectedCurrency = 'KRW';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('여행 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _travelController,
              decoration: const InputDecoration(labelText: '여행 이름'),
            ),
            DropdownButton<String>(
              value: _selectedCurrency,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCurrency = newValue!;
                });
              },
              items: <String>['KRW', 'USD', 'EUR', 'JPY', 'MNT']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            ..._travellerControllers.map((controller) {
              int index = _travellerControllers.indexOf(controller);
              return Column(
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: '여행자 이름'),
                  ),
                ],
              );
            }).toList(),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _travellerControllers.add(TextEditingController());
                  _contributionControllers.add(TextEditingController());
                });
              },
              child: const Text('여행자 추가'),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            List<Map<String, dynamic>> travellers = [];
            for (int i = 0; i < _travellerControllers.length; i++) {
              travellers.add({
                'name': _travellerControllers[i].text,
                'contribution':
                    int.tryParse(_contributionControllers[i].text) ?? 0,
              });
            }
            Map<String, dynamic> travelData = {
              'title': _travelController.text,
              'currency': _selectedCurrency,
              'travellers': travellers,
            };
            widget.onAddTravel(travelData);
            Navigator.of(context).pop();
          },
          child: const Text('여행 추가'),
        ),
      ],
    );
  }
}
