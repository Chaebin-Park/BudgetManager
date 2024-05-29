import 'package:flutter/material.dart';
import 'travel_database.dart';
import 'expense_dialog.dart';

class DetailOfUsePage extends StatefulWidget {
  final int travelId;
  final String currency;

  const DetailOfUsePage({super.key, required this.travelId, required this.currency});

  @override
  State<DetailOfUsePage> createState() => _DetailOfUsePageState();
}

class _DetailOfUsePageState extends State<DetailOfUsePage> {
  List<Map<String, dynamic>> expenseList = [];
  List<Map<String, dynamic>> travellerList = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadTravellers();
  }

  Future<void> _loadExpenses() async {
    List<Map<String, dynamic>> expenses = await DatabaseHelper().getExpenses(widget.travelId);
    setState(() {
      expenseList = expenses;
    });
  }

  Future<void> _loadTravellers() async {
    List<Map<String, dynamic>> travellers = await DatabaseHelper().getTravellers(widget.travelId);
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
          onSave: (Map<String, dynamic> expenseData, List<bool> selectedTravellers) async {
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
          },
        );
      },
    );
  }

  void _editExpense(Map<String, dynamic> expense) async {
    List<Map<String, dynamic>> expenseTravellers = await DatabaseHelper().getExpenseTravellers(expense['id']);
    List<bool> selectedTravellers = travellerList.map((traveller) {
      return expenseTravellers.any((expenseTraveller) => expenseTraveller['traveller_id'] == traveller['id']);
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ExpenseDialog(
          travelId: widget.travelId,
          travellerList: travellerList,
          expense: expense,
          selectedTravellers: selectedTravellers,
          onSave: (Map<String, dynamic> expenseData, List<bool> selectedTravellers) async {
            await DatabaseHelper().updateExpenseWithTravellers(expenseData, selectedTravellers, travellerList);
            _loadExpenses();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: expenseList.length,
        itemBuilder: (context, index) {
          var expense = expenseList[index];
          return ListTile(
            title: Text(expense['name']),
            subtitle: Text('${expense['amount']} ${widget.currency}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _editExpense(expense),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteExpense(expense['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExpense,
        child: Icon(Icons.add),
      ),
    );
  }

  void _deleteExpense(int expenseId) async {
    await DatabaseHelper().deleteExpense(expenseId);
    _loadExpenses();
  }
}
