import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'travel_database.dart';
import 'expense_dialog.dart';

class DetailOfUsePage extends StatefulWidget {
  final int travelId;
  final String currency;

  const DetailOfUsePage(
      {super.key, required this.travelId, required this.currency});

  @override
  State<DetailOfUsePage> createState() => _DetailOfUsePageState();
}

class _DetailOfUsePageState extends State<DetailOfUsePage> {
  List<Map<String, dynamic>> expenseList = [];
  List<Map<String, dynamic>> travellerList = [];
  final NumberFormat currencyFormatter = NumberFormat('#,##0');

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadTravellers();
  }

  Future<void> _loadExpenses() async {
    List<Map<String, dynamic>> expenses =
        await DatabaseHelper().getExpenses(widget.travelId);
    setState(() {
      expenseList = expenses;
    });
  }

  Future<void> _loadTravellers() async {
    List<Map<String, dynamic>> travellers =
        await DatabaseHelper().getTravellers(widget.travelId);
    setState(() {
      travellerList = travellers;
    });
  }

  void _addExpense() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExpenseDialog(
          travelId: widget.travelId,
          travellerList: travellerList,
          onSave: (expenseData, selectedTravellers) {
            _saveExpense(expenseData, selectedTravellers);
          },
        );
      },
    );
  }

  void _editExpense(Map<String, dynamic> expense) async {
    List<Map<String, dynamic>> expenseTravellers =
        await DatabaseHelper().getExpenseTravellers(expense['id']);
    List<bool> selectedTravellers = travellerList.map((traveller) {
      return expenseTravellers.any((expenseTraveller) =>
          expenseTraveller['traveller_id'] == traveller['id']);
    }).toList();

    if (mounted) {
      return showDialog(
        context: context,
        builder: (BuildContext context) {
          return ExpenseDialog(
            travelId: widget.travelId,
            travellerList: travellerList,
            expense: expense,
            selectedTravellers: selectedTravellers,
            onSave: (expenseData, selectedTravellers) {
              _updateExpense(expenseData, selectedTravellers);
            },
          );
        },
      );
    }
  }

  void _saveExpense(
      Map<String, dynamic> expenseData, List<bool> selectedTravellers) async {
    int expenseId = await DatabaseHelper().insertExpense(expenseData);
    for (int i = 0; i < selectedTravellers.length; i++) {
      if (selectedTravellers[i]) {
        await DatabaseHelper().insertExpenseTraveller({
          'expense_id': expenseId,
          'traveller_id': travellerList[i]['id'],
        });
      }
    }
    _loadExpenses();
  }

  void _updateExpense(
      Map<String, dynamic> expenseData, List<bool> selectedTravellers) async {
    List<Map<String, dynamic>> expenseTravellerList = [];
    for (int i = 0; i < selectedTravellers.length; i++) {
      if (selectedTravellers[i]) {
        expenseTravellerList.add({
          'expense_id': expenseData['id'],
          'traveller_id': travellerList[i]['id'],
        });
      }
    }
    await DatabaseHelper()
        .updateExpenseWithTravellers(expenseData, expenseTravellerList);
    _loadExpenses();
  }

  void _showDeleteConfirmationDialog(BuildContext context, int expenseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('삭제 확인'),
          content: const Text('정말 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('아니오'),
            ),
            TextButton(
              onPressed: () {
                _deleteExpense(expenseId);
                Navigator.of(context).pop();
              },
              child: const Text('예'),
            ),
          ],
        );
      },
    );
  }

  void _deleteExpense(int expenseId) async {
    await DatabaseHelper().deleteExpense(expenseId);
    _loadExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: expenseList.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(expenseList[index]['name']),
            subtitle: Text(
                '금액: ${currencyFormatter.format(expenseList[index]['amount'])} ${widget.currency}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editExpense(expenseList[index]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _showDeleteConfirmationDialog(
                      context, expenseList[index]['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: const Icon(Icons.add),
      ),
    );
  }
}
