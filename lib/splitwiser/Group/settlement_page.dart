import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'currency_service.dart';
import '../Dashboard/activity_service.dart';

class SettlementPage extends StatefulWidget {
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> optimizedSettlement;
  final double totalTransactions;
  final double originalTransactions;
  final String displayCurrency;
  final double exchangeRate;
  final String currencySymbol;

  const SettlementPage({
    Key? key,
    required this.group,
    required this.optimizedSettlement,
    required this.totalTransactions,
    required this.originalTransactions,
    required this.displayCurrency,
    required this.exchangeRate,
    required this.currencySymbol,
  }) : super(key: key);

  @override
  _SettlementPageState createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  bool isSettled = false;
  final CurrencyService _currencyService = CurrencyService();
  String? savedDisplayCurrency;
  double? savedExchangeRate;
  String? savedCurrencySymbol;

  @override
  void initState() {
    super.initState();
    _loadSavedCurrency();
  }

  // Load saved currency preference and override widget values if different
  Future<void> _loadSavedCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('preferred_display_currency');

      if (savedCurrency != null && savedCurrency != widget.displayCurrency) {
        final rate = await _currencyService.getExchangeRate(
          'MYR',
          savedCurrency,
        );
        final symbol = _currencyService.getCurrencySymbol(savedCurrency);

        setState(() {
          savedDisplayCurrency = savedCurrency;
          savedExchangeRate = rate;
          savedCurrencySymbol = symbol;
        });
      }
    } catch (e) {
      print("Error loading saved currency in settlement, $e");
    }
  }

  // Convert amount based on exchange rate
  double _convertAmount(double amount) {
    final rate = savedExchangeRate ?? widget.exchangeRate;
    return amount * rate;
  }

  String _getCurrencySymbol() {
    return savedCurrencySymbol ?? widget.currencySymbol;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(232, 154, 134, 213),
            Color.fromARGB(209, 77, 66, 221),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Settlement Plan', style: TextStyle(color: Colors.white)),
          leading: BackButton(color: Colors.white),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optimal Settlement',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Minimized transactions for ${widget.group['name']}',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Settlement list
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 231, 227, 227),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settlement Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 16),

                      if (widget.optimizedSettlement.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 64,
                                color: Colors.green,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'All Settled!',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'No transactions needed',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: widget.optimizedSettlement.length,
                            itemBuilder: (context, index) {
                              final settlement =
                                  widget.optimizedSettlement[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.blue.shade100,
                                      child: Icon(
                                        Icons.payment,
                                        color: Colors.blue.shade700,
                                        size: 20,
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        settlement['description'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${_getCurrencySymbol()} ${_convertAmount(settlement['amount']).toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Mark as Settled button
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: widget.optimizedSettlement.isEmpty
                        ? null
                        : () {
                            _markAsSettled(context);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Mark as Settled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _markAsSettled(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mark as Settled'),
          content: Text('Are you sure all transactions have been completed?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close confirmation dialog

                // Update group status to settled
                await _updateGroupAsSettled();

                // Log settlement activity
                await ActivityService.addSettlement(
                  groupName: widget.group['name'],
                );

                if (mounted) {
                  // Navigate back to group detail page with settlement result
                  Navigator.of(context).pop(true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Group marked as settled!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateGroupAsSettled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGroups = prefs.getStringList('groups') ?? [];

      // Find and update the current group
      final updatedGroups = savedGroups.map((groupStr) {
        final groupData = json.decode(groupStr) as Map<String, dynamic>;

        if (groupData['name'] == widget.group['name']) {
          // Mark group as settled by adding a settled flag
          groupData['isSettled'] = true;
          groupData['settledDate'] = DateTime.now().toIso8601String();
        }

        return json.encode(groupData);
      }).toList();

      // Save updated groups
      await prefs.setStringList('groups', updatedGroups);

      // Add timestamp to help other pages detect settlement changes
      await prefs.setInt(
        'settlement_change_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      print("Error updating the group as settled, $e");
    }
  }
}
