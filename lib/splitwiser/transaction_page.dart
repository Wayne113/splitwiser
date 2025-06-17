import 'package:flutter/material.dart';

class TransactionPage extends StatelessWidget {
  final List<Map<String, dynamic>> transactions = [
    {'title': 'Lunch', 'subtitle': 'Paid by John', 'amount': 25.50},
    {'title': 'Groceries', 'subtitle': 'Paid by Kim', 'amount': 80.00},
    {'title': 'Taxi', 'subtitle': 'Paid by Wade', 'amount': 15.75},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return Card(
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                title: Text(tx['title'], style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(tx['subtitle']),
                trailing: Text('RM ${tx['amount'].toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          },
        ),
      ),
    );
  }
} 