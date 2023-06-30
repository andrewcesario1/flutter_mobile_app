import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'AccountScreen.dart';
import 'home_screen.dart';


class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _expensesStream;
  List<charts.Series<dynamic, String>> _chartData = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _expensesStream = FirebaseFirestore.instance
        .collection('expenses')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .snapshots();
    _loadChartData();
  }

  void _loadChartData() {
    _expensesStream.listen((QuerySnapshot<Map<String, dynamic>> snapshot) {
      Map<String, double> expenseTotals = {};

      for (var doc in snapshot.docs) {
        String type = doc['type'];
        double amount = double.parse(doc['amount']);

        expenseTotals.update(type, (value) => value + amount, ifAbsent: () => amount);
      }

      List<Expense> expenses = expenseTotals.entries.map((entry) => Expense(
        type: entry.key,
        amount: entry.value,
      )).toList();

      expenses.sort((a, b) => a.amount.compareTo(b.amount));

      setState(() {
        _chartData = [
          charts.Series<Expense, String>(
            id: 'expenses',
            colorFn: (Expense expense, _) {
              if (expense.type == 'Food') {
                return charts.MaterialPalette.red.shadeDefault;
              } else if (expense.type == 'Entertainment') {
                return charts.MaterialPalette.green.shadeDefault;
              } else if (expense.type == 'Bills') {
                return charts.MaterialPalette.blue.shadeDefault;
              } else {
                return charts.MaterialPalette.gray.shadeDefault;
              }
            },
            domainFn: (Expense expense, _) => expense.type,
            measureFn: (Expense expense, _) => expense.amount,
            data: expenses,
            labelAccessorFn: (Expense expense, _) => '\$${expense.amount.toStringAsFixed(2)}',
          ),
        ];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Graphs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: 1,
        onTap: (int index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            ); // Navigate back to the HomeScreen
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccountScreen(),
              ),
            );
          }
        },
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Expense Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: charts.BarChart(
                _chartData,
                animate: true,
                vertical: false,
                defaultRenderer: charts.BarRendererConfig(
                  // Customize the chart labels
                  barRendererDecorator: charts.BarLabelDecorator<String>(
                    insideLabelStyleSpec: charts.TextStyleSpec(
                      color: charts.Color.white,
                      fontSize: 12,
                    ),
                    outsideLabelStyleSpec: charts.TextStyleSpec(
                      color: charts.Color.black,
                      fontSize: 12,
                    ),
                    labelAnchor: charts.BarLabelAnchor.end,
                    labelPosition: charts.BarLabelPosition.auto,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class Expense {
  final String type;
  final double amount;

  Expense({required this.type, required this.amount});
}