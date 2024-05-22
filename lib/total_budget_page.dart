import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'travel_database.dart';
import 'currency_converter.dart';

class TotalBudgetPage extends StatefulWidget {
  final int travelId;
  final String currency;

  const TotalBudgetPage({super.key, required this.travelId, required this.currency});

  @override
  State<TotalBudgetPage> createState() => _TotalBudgetPageState();
}

class _TotalBudgetPageState extends State<TotalBudgetPage> {
  double totalBudget = 0.0;
  double totalExpense = 0.0;
  double balance = 0.0;
  List<Map<String, dynamic>> travellerList = [];
  Map<int, double> travellerExpenses = {};
  Map<int, double> travellerRefunds = {};
  double exchangeRate = 1.0; // Default exchange rate (1:1)
  late String baseCurrency;
  late String displayCurrency;
  String errorMessage = ''; // Error message for exchange rate

  final NumberFormat currencyFormatter = NumberFormat('#,##0.00');
  final NumberFormat exchangeRateFormatter = NumberFormat('#,##0.00');

  @override
  void initState() {
    super.initState();
    baseCurrency = widget.currency;
    displayCurrency = baseCurrency;
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    List<Map<String, dynamic>> travellers =
        await DatabaseHelper().getTravellers(widget.travelId);
    List<Map<String, dynamic>> expenses =
        await DatabaseHelper().getExpenses(widget.travelId);

    double budget = travellers.fold(
        0,
        (sum, traveller) =>
            sum + (traveller['contribution'] as int).toDouble());
    double expense = 0.0;
    Map<int, double> expensesByTraveller = {};

    for (var expenseItem in expenses) {
      List<Map<String, dynamic>> expenseTravellers =
          await DatabaseHelper().getExpenseTravellers(expenseItem['id']);
      int numTravellers = expenseTravellers.length;
      double amountPerTraveller =
          (expenseItem['amount'] / numTravellers).toDouble();

      for (var expenseTraveller in expenseTravellers) {
        expensesByTraveller.update(
          expenseTraveller['traveller_id'],
          (existing) => existing + amountPerTraveller,
          ifAbsent: () => amountPerTraveller,
        );
      }

      expense += (expenseItem['amount'] as int).toDouble();
    }

    double balance = budget - expense;
    Map<int, double> refundsByTraveller = {};

    for (var traveller in travellers) {
      double contribution = (traveller['contribution'] as int).toDouble();
      double travellerExpense = expensesByTraveller[traveller['id']] ?? 0.0;
      refundsByTraveller[traveller['id']] = contribution - travellerExpense;
    }

    if (mounted) {
      setState(() {
        totalBudget = budget;
        totalExpense = expense;
        this.balance = balance;
        travellerList = travellers;
        travellerExpenses = expensesByTraveller;
        travellerRefunds = refundsByTraveller;
      });
    }
  }

  Future<void> _updateExchangeRate(String newCurrencyCode) async {
    try {
      double newExchangeRate = await CurrencyConverter.getExchangeRate(
          baseCurrency, newCurrencyCode);
      setState(() {
        exchangeRate = newExchangeRate;
        displayCurrency = newCurrencyCode;
        errorMessage = '';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load exchange rates: ${e.toString()}';
      });
    }
  }

  List<PieChartSectionData> showingContributionSections() {
    return travellerList.asMap().entries.map((entry) {
      int index = entry.key;
      var traveller = entry.value;
      double percentage = (traveller['contribution'] / totalBudget) * 100;
      const fontSize = 14.0;
      const radius = 40.0;

      return PieChartSectionData(
        color: Colors.primaries[index % Colors.primaries.length],
        value: traveller['contribution'].toDouble() * exchangeRate,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Color(0xffffffff),
        ),
      );
    }).toList();
  }

  List<PieChartSectionData> showingExpenseSections() {
    return travellerList.asMap().entries.map((entry) {
      int index = entry.key;
      var traveller = entry.value;
      double expense = travellerExpenses[traveller['id']] ?? 0.0;
      double percentage = (expense / totalExpense) * 100;
      const fontSize = 14.0;
      const radius = 40.0;

      return PieChartSectionData(
        color: Colors.accents[index % Colors.accents.length],
        value: expense.toDouble() * exchangeRate,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: radius,
        titleStyle: const TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Color(0xffffffff),
        ),
      );
    }).toList();
  }

  Widget buildLegend() {
    return Column(
      children: travellerList.asMap().entries.map((entry) {
        int index = entry.key;
        var traveller = entry.value;
        Color color = Colors.primaries[index % Colors.primaries.length];

        return Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(traveller['name']),
          ],
        );
      }).toList(),
    );
  }

  Widget buildExpenseLegend() {
    return Column(
      children: travellerList.asMap().entries.map((entry) {
        int index = entry.key;
        var traveller = entry.value;
        Color color = Colors.accents[index % Colors.accents.length];

        return Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(traveller['name']),
          ],
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                      '총 예산: ${currencyFormatter.format(totalBudget * exchangeRate)} $displayCurrency',
                      style: TextStyle(fontSize: 18)),
                  DropdownButton<String>(
                    value: displayCurrency,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _updateExchangeRate(newValue);
                      }
                    },
                    items: <String>['KRW', 'USD', 'EUR', 'JPY', 'MNT']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ],
              ),
              if (errorMessage.isNotEmpty)
                Text(errorMessage, style: const TextStyle(color: Colors.red)),
              Text(
                  '총 사용액: ${currencyFormatter.format(totalExpense * exchangeRate)} $displayCurrency',
                  style: const TextStyle(fontSize: 18)),
              Text(
                  '잔액: ${currencyFormatter.format(balance * exchangeRate)} $displayCurrency',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              Text(
                  '환율: 1000 $baseCurrency = ${exchangeRateFormatter.format(exchangeRate * 1000)} $displayCurrency',
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 20),
              const Text('종합', style: TextStyle(fontSize: 18)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: travellerList.length,
                itemBuilder: (context, index) {
                  var traveller = travellerList[index];
                  double expense = travellerExpenses[traveller['id']] ?? 0.0;
                  double refund = travellerRefunds[traveller['id']] ?? 0.0;
                  return ListTile(
                    title: Text(traveller['name']),
                    subtitle: Text(
                        '기여금: ${currencyFormatter.format(traveller['contribution'].toDouble() * exchangeRate)} $displayCurrency\n사용액: ${currencyFormatter.format(expense * exchangeRate)} $displayCurrency\n돌려받을 금액: ${currencyFormatter.format(refund * exchangeRate)} $displayCurrency'),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('기여금 비율', style: TextStyle(fontSize: 18)),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: showingContributionSections(),
                    centerSpaceRadius: 40,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              buildLegend(),
              const SizedBox(height: 20),
              const Text('사용금액 비율', style: TextStyle(fontSize: 18)),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: showingExpenseSections(),
                    centerSpaceRadius: 40,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
              buildExpenseLegend(),
            ],
          ),
        ),
      ),
    );
  }
}
