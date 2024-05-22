import 'package:flutter/material.dart';
import 'public_funds_page.dart';
import 'detail_of_use_page.dart';
import 'total_budget_page.dart';

class BudgetPage extends StatelessWidget {
  final String travelTitle;
  final int travelId;
  final String currency;

  BudgetPage({required this.travelTitle, required this.travelId, required this.currency});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(travelTitle),
          bottom: const TabBar(
            tabs: [
              Tab(text: '공금 정보'),
              Tab(text: '사용 내역'),
              Tab(text: '총 예산'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            PublicFundsPage(travelId: travelId, currency: currency),
            DetailOfUsePage(travelId: travelId, currency: currency),
            TotalBudgetPage(travelId: travelId, currency: currency),
          ],
        ),
      ),
    );
  }
}
