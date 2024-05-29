import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpenseDialog extends StatefulWidget {
  final int travelId;
  final List<Map<String, dynamic>> travellerList;
  final Function(Map<String, dynamic>, List<bool>) onSave;
  final Map<String, dynamic>? expense;
  final List<bool>? selectedTravellers;

  ExpenseDialog({
    required this.travelId,
    required this.travellerList,
    required this.onSave,
    this.expense,
    this.selectedTravellers,
  });

  @override
  _ExpenseDialogState createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<ExpenseDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;
  late List<bool> _selectedTravellers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.expense?['name'] ?? '');
    _amountController = TextEditingController(text: widget.expense?['amount']?.toString() ?? '');
    _selectedTravellers = widget.selectedTravellers ?? List<bool>.filled(widget.travellerList.length, false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.expense == null ? '사용처 추가' : '사용처 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: '사용처 이름'),
            ),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: '금액'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 10),
            Text('관련 여행자들'),
            ...widget.travellerList.asMap().entries.map((entry) {
              int index = entry.key;
              var traveller = entry.value;
              return CheckboxListTile(
                title: Text(traveller['name']),
                value: _selectedTravellers[index],
                onChanged: (bool? value) {
                  setState(() {
                    _selectedTravellers[index] = value ?? false;
                  });
                },
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            Map<String, dynamic> expenseData = {
              'id': widget.expense?['id'],
              'travel_id': widget.travelId,
              'name': _nameController.text,
              'amount': int.tryParse(_amountController.text) ?? 0,
            };
            widget.onSave(expenseData, _selectedTravellers);
            Navigator.of(context).pop();
          },
          child: Text('저장'),
        ),
      ],
    );
  }
}
