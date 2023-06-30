import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/screens/AccountScreen.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:mobile_app/screens/analytics_screen.dart';


import 'AccountScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late Stream<QuerySnapshot<Map<String, dynamic>>> _expensesStream = FirebaseFirestore.instance
      .collection('expenses')
      .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
      .orderBy('createdAt', descending: true)
      .snapshots();




  Future<void> _addExpense(BuildContext context) async {
    String expenseAmount = '';
    String expenseType = 'Food'; // Default type is Food

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: expenseType,
                onChanged: (String? newValue) {
                  setState(() {
                    expenseType = newValue!;
                  });
                },
                items: <String>['Food', 'Bills', 'Entertainment', 'Other'].map<DropdownMenuItem<String>>((String value) {
                  Color color;
                  switch (value) {
                    case 'Food':
                      color = Colors.red;
                      break;
                    case 'Bills':
                      color = Colors.blue;
                      break;
                    case 'Entertainment':
                      color = Colors.green;
                      break;
                    case 'Other':
                    default:
                      color = Colors.grey;
                      break;
                  }
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        Icon(Icons.circle, color: color),
                        SizedBox(width: 8),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
              ),
              TextFormField(
                onChanged: (value) {
                  expenseAmount = value;
                },
                decoration: InputDecoration(
                  labelText: 'Expense Amount',
                  hintText: '\$ 0.00',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                String userId = FirebaseAuth.instance.currentUser!.uid;

                await _firestore.collection('expenses').add({
                  'userId': userId,
                  'type': expenseType,
                  'amount': expenseAmount,
                  'createdAt': DateTime.now(), // Add the createdAt field with the current timestamp
                });


                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }



  double calculateTotalExpenses(List<QueryDocumentSnapshot<Map<String, dynamic>>> expenses) {
    double total = 0;
    for (var expense in expenses) {
      total += double.parse(expense['amount']);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
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
        currentIndex: 0,
        onTap: (int index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AnalyticsScreen(),
              ),
            );
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
      body:
      Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => _addExpense(context),
              child: const Text('Add Expense'),
            ),
          ),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _expensesStream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final expenses = snapshot.data!.docs;
                final totalExpenses = calculateTotalExpenses(expenses);

                if (expenses.isNotEmpty) {
                  return Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final expense = expenses[index].data();
                              return Container(
                                height: 75,
                                margin: const EdgeInsets.all(8.0),
                                color: _getExpenseColor(expense['type']), // Get the color based on expense type
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text('Type: ${expense['type']}', style: TextStyle(color: Colors.white, fontSize: 16.0)), // Display expense type with white color
                                            Text('Amount: \$${double.parse(expense['amount']).toStringAsFixed(2)}', style: TextStyle(color: Colors.white, fontSize: 15.0)), // Display expense amount with white color
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          height: 50,
                          color: Colors.blue,
                          child: Center(
                            child: Text(
                              'Total Expenses: \$${totalExpenses.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Expanded(
                    child: Center(
                      child: Text('Add an expense to start tracking'),
                    ),
                  );
                }
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getExpenseColor(String expenseType) {
    switch (expenseType) {
      case 'Food':
        return Colors.red;
      case 'Bills':
        return Colors.blue;
      case 'Entertainment':
        return Colors.green;
      case 'Other':
      default:
        return Colors.grey;
    }
  }



}
