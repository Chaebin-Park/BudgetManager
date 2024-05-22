import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'travel_database.dart';

class PublicFundsPage extends StatefulWidget {
  final int travelId;
  final String currency;

  const PublicFundsPage({super.key, required this.travelId, required this.currency});

  @override
  State<PublicFundsPage> createState() => _PublicFundsPageState();
}

class _PublicFundsPageState extends State<PublicFundsPage> {
  List<Map<String, dynamic>> travellerList = [];
  final NumberFormat currencyFormatter = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    _loadTravellers();
  }

  Future<void> _loadTravellers() async {
    List<Map<String, dynamic>> travellers = await DatabaseHelper().getTravellers(widget.travelId);
    setState(() {
      travellerList = travellers;
    });
  }

  void _addTraveller() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController();
        TextEditingController contributionController = TextEditingController();

        return AlertDialog(
          title: const Text('여행자 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '이름'),
                ),
                TextField(
                  controller: contributionController,
                  decoration: const InputDecoration(labelText: '기여금'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Map<String, dynamic> travellerData = {
                  'travel_id': widget.travelId,
                  'name': nameController.text,
                  'contribution': int.tryParse(contributionController.text) ?? 0,
                };
                _saveTraveller(travellerData);
                Navigator.of(context).pop();
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _editTraveller(Map<String, dynamic> traveller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController(text: traveller['name']);
        TextEditingController contributionController = TextEditingController(text: traveller['contribution'].toString());

        return AlertDialog(
          title: const Text('여행자 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '이름'),
                ),
                TextField(
                  controller: contributionController,
                  decoration: const InputDecoration(labelText: '기여금'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () {
                Map<String, dynamic> updatedTraveller = {
                  'id': traveller['id'],
                  'name': nameController.text,
                  'contribution': int.tryParse(contributionController.text) ?? 0,
                };
                _updateTraveller(updatedTraveller);
                Navigator.of(context).pop();
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  void _saveTraveller(Map<String, dynamic> travellerData) async {
    await DatabaseHelper().insertTraveller(travellerData);
    _loadTravellers();
  }

  void _updateTraveller(Map<String, dynamic> travellerData) async {
    await DatabaseHelper().updateTraveller(travellerData);
    _loadTravellers();
  }

  void _deleteTraveller(int travellerId) async {
    await DatabaseHelper().deleteTraveller(travellerId);
    _loadTravellers();
  }

  void _showDeleteConfirmationDialog(BuildContext context, int travellerId) {
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
                _deleteTraveller(travellerId);
                Navigator.of(context).pop();
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: travellerList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(travellerList[index]['name']),
            subtitle: Text('기여금: ${currencyFormatter.format(travellerList[index]['contribution'])} ${widget.currency}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editTraveller(travellerList[index]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteConfirmationDialog(context, travellerList[index]['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTraveller,
        tooltip: '여행자 추가',
        child: const Icon(Icons.add),
      ),
    );
  }
}
