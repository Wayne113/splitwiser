import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:splitwiser/splitwiser/add_new_group_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreateExpenseForm extends StatefulWidget {
  final List<String> groups;
  final VoidCallback? onExpenseCreated;

  const CreateExpenseForm({
    Key? key,
    required this.groups,
    this.onExpenseCreated,
  }) : super(key: key);

  @override
  _CreateExpenseFormState createState() => _CreateExpenseFormState();
}

class _CreateExpenseFormState extends State<CreateExpenseForm> {
  final List<Map<String, dynamic>> icons = [
    {'icon': Icons.fastfood, 'label': 'Food'},
    {'icon': Icons.local_gas_station, 'label': 'Fuel'},
    {'icon': Icons.cake, 'label': 'Gift'},
    {'icon': Icons.shopping_cart, 'label': 'Shopping'},
    {'icon': Icons.home, 'label': 'Home'},
    {'icon': Icons.sports_bar, 'label': 'Bar'},
    {'icon': Icons.flight, 'label': 'Travel'},
    {'icon': Icons.movie, 'label': 'Movie'},
  ];
  int selectedIconIndex = 0;

  final List<Map<String, String>> currencies = [
    {'code': 'AED', 'name': 'UAE Dirham', 'country': 'United Arab Emirates'},
    {'code': 'ARS', 'name': 'Argentine Peso', 'country': 'Argentina'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'country': 'Australia'},
    {'code': 'BRL', 'name': 'Brazilian Real', 'country': 'Brazil'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'country': 'Canada'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'country': 'Switzerland'},
    {'code': 'CLP', 'name': 'Chilean Peso', 'country': 'Chile'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'country': 'China'},
    {'code': 'COP', 'name': 'Colombian Peso', 'country': 'Colombia'},
    {'code': 'CZK', 'name': 'Czech Koruna', 'country': 'Czech Republic'},
    {'code': 'DKK', 'name': 'Danish Krone', 'country': 'Denmark'},
    {'code': 'EGP', 'name': 'Egyptian Pound', 'country': 'Egypt'},
    {'code': 'EUR', 'name': 'Euro', 'country': 'European Union'},
    {'code': 'GBP', 'name': 'British Pound', 'country': 'United Kingdom'},
    {'code': 'HKD', 'name': 'Hong Kong Dollar', 'country': 'Hong Kong'},
    {'code': 'HUF', 'name': 'Hungarian Forint', 'country': 'Hungary'},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'country': 'Indonesia'},
    {'code': 'ILS', 'name': 'Israeli New Shekel', 'country': 'Israel'},
    {'code': 'INR', 'name': 'Indian Rupee', 'country': 'India'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'country': 'Japan'},
    {'code': 'KRW', 'name': 'South Korean Won', 'country': 'South Korea'},
    {'code': 'MXN', 'name': 'Mexican Peso', 'country': 'Mexico'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'country': 'Malaysia'},
    {'code': 'NOK', 'name': 'Norwegian Krone', 'country': 'Norway'},
    {'code': 'NZD', 'name': 'New Zealand Dollar', 'country': 'New Zealand'},
    {'code': 'PHP', 'name': 'Philippine Peso', 'country': 'Philippines'},
    {'code': 'PKR', 'name': 'Pakistani Rupee', 'country': 'Pakistan'},
    {'code': 'PLN', 'name': 'Polish Złoty', 'country': 'Poland'},
    {'code': 'RUB', 'name': 'Russian Ruble', 'country': 'Russia'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'country': 'Saudi Arabia'},
    {'code': 'SEK', 'name': 'Swedish Krona', 'country': 'Sweden'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'country': 'Singapore'},
    {'code': 'THB', 'name': 'Thai Baht', 'country': 'Thailand'},
    {'code': 'TRY', 'name': 'Turkish Lira', 'country': 'Turkey'},
    {'code': 'TWD', 'name': 'Taiwan Dollar', 'country': 'Taiwan'},
    {'code': 'UAH', 'name': 'Ukrainian Hryvnia', 'country': 'Ukraine'},
    {'code': 'USD', 'name': 'US Dollar', 'country': 'United States'},
    {'code': 'VND', 'name': 'Vietnamese Dong', 'country': 'Vietnam'},
    {'code': 'ZAR', 'name': 'South African Rand', 'country': 'South Africa'},
  ];
  String selectedCurrency = 'MYR';

  String? selectedGroup;
  String? paidByType;
  DateTime selectedDate = DateTime.now();
  final TextEditingController totalController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  late TextEditingController _paidByController;
  late TextEditingController _dateController;
  late TextEditingController _currencyController;
  late TextEditingController _splitMethodController;
  String? selectedSplitMethod;

  List<Map<String, dynamic>> groupMembers = [];
  String? selectedSinglePayer;
  Map<String, double> multiplePayers = {};

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(color: Colors.white)),
          content: Text(message, style: TextStyle(color: Colors.white70)),
          backgroundColor: Color.fromARGB(255, 39, 39, 40),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.deepPurple),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadGroupMembers() async {
    if (selectedGroup == null) return;

    final prefs = await SharedPreferences.getInstance();
    final savedGroups = prefs.getStringList('groups') ?? [];

    for (String groupStr in savedGroups) {
      final groupData = json.decode(groupStr) as Map<String, dynamic>;
      if (groupData['name'] == selectedGroup) {
        setState(() {
          groupMembers = (groupData['members'] as List)
              .map((m) => m as Map<String, dynamic>)
              .toList();
        });
        break;
      }
    }
  }

  void _updatePaidByController() {
    if (paidByType == 'Single' && selectedSinglePayer != null) {
      final selectedMember = groupMembers.firstWhere(
        (m) => m['email'] == selectedSinglePayer,
        orElse: () => {'name': 'Unknown'},
      );
      _paidByController.text = '${selectedMember['name']}';
    } else if (paidByType == 'Multiple' && multiplePayers.isNotEmpty) {
      final payerNames = multiplePayers.entries
          .map((entry) {
            final member = groupMembers.firstWhere(
              (m) => m['email'] == entry.key,
              orElse: () => {'name': 'Unknown'},
            );
            return member['name']; // Return only member name, not including amount
          })
          .join(', ');
      _paidByController.text = payerNames; // 直接显示成员名字，不加 "Multiple"
    }
  }

  bool _isFormValid() {
    return descController.text.isNotEmpty &&
        totalController.text.isNotEmpty &&
        selectedGroup != null &&
        paidByType != null &&
        selectedSplitMethod != null &&
        _dateController.text.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _paidByController = TextEditingController(text: paidByType ?? '');
    _dateController = TextEditingController(text: '');
    _currencyController = TextEditingController(text: selectedCurrency);
    _splitMethodController = TextEditingController(
      text: selectedSplitMethod ?? '',
    );
  }

  @override
  void dispose() {
    _paidByController.dispose();
    _dateController.dispose();
    totalController.dispose();
    descController.dispose();
    _currencyController.dispose();
    _splitMethodController.dispose();
    super.dispose();
  }

  String getSelectedCurrencyName() {
    final currency = currencies.firstWhere(
      (c) => c['code'] == selectedCurrency,
      orElse: () => {
        'code': 'MYR',
        'name': 'Malaysian Ringgit',
        'country': 'Malaysia',
      },
    );
    return '${currency['code']} - ${currency['name']}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Expense', style: TextStyle(color: Colors.white70)),
        backgroundColor: Color.fromARGB(255, 39, 39, 40),
        iconTheme: IconThemeData(color: Colors.white70),
      ),
      backgroundColor: Color.fromARGB(255, 39, 39, 40),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Description + Icon
            SizedBox(height: 15),
            Row(
              children: [
                // Description input
                Expanded(
                  child: TextField(
                    controller: descController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Description',
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      hintText: 'Enter description',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                    ),
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                // Icon picker
                Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      icons[selectedIconIndex]['icon'],
                      color: Color(0xFF7F55FF),
                    ),
                    onPressed: () async {
                      int? picked = await showModalBottomSheet<int>(
                        context: context,
                        builder: (_) => _buildIconPicker(context),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedIconIndex = picked;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Total + Currency
            Row(
              children: [
                // Total input
                Expanded(
                  child: TextField(
                    controller: totalController,
                    onChanged: (value) => setState(() {}),
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    decoration: InputDecoration(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total', style: TextStyle(color: Colors.white)),
                          Text(
                            ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      hintText: 'Enter total amount',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                    ),
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
                SizedBox(width: 10),
                // Currency picker
                SizedBox(
                  width: 100,
                  child: TextField(
                    readOnly: true,
                    controller: _currencyController,
                    decoration: InputDecoration(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Currency',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      hintText: 'Select currency',
                      hintStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                          color: Colors.deepPurple,
                          width: 2,
                        ),
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 20,
                      ),
                    ),
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        builder: (context) => DraggableScrollableSheet(
                          initialChildSize: 0.9,
                          minChildSize: 0.4,
                          maxChildSize: 0.9,
                          expand: false,
                          builder: (context, scrollController) =>
                              CurrencySelector(
                                currencies: currencies,
                                scrollController: scrollController,
                                onSelect: (code) {
                                  setState(() {
                                    selectedCurrency = code;
                                    _currencyController.text = selectedCurrency;
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                        ),
                      );
                    },
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Group
            TextField(
              readOnly: true,
              controller: TextEditingController(text: selectedGroup ?? ''),
              decoration: InputDecoration(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Group', style: TextStyle(color: Colors.white)),
                    Text(
                      ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                hintText: 'Select group',
                hintStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
              ),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.4,
                    maxChildSize: 0.9,
                    expand: false,
                    builder: (context, scrollController) => GroupSelector(
                      groups: widget.groups,
                      scrollController: scrollController,
                      initialSelectedGroup: selectedGroup,
                      onSelect: (g) async {
                        setState(() {
                          selectedGroup = g;
                        });
                        await _loadGroupMembers();
                      },
                    ),
                  ),
                );
              },
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),

            SizedBox(height: 24),

            // Paid by
            TextField(
              readOnly: true,
              controller: _paidByController,
              decoration: InputDecoration(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Paid by', style: TextStyle(color: Colors.white)),
                    Text(
                      ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                hintText: 'Select payer',
                hintStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
              ),
              onTap: () {
                if (totalController.text.isEmpty) {
                  _showAlertDialog(
                    'Missing Information',
                    'Please fill in the Total amount first.',
                  );
                  return;
                } else if (selectedGroup == null) {
                  _showAlertDialog(
                    'Missing Information',
                    'Please select a Group first.',
                  );
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.4,
                    maxChildSize: 0.9,
                    expand: false,
                    builder: (context, scrollController) => PaidBySelector(
                      groupMembers: groupMembers,
                      scrollController: scrollController,
                      totalAmount: double.tryParse(totalController.text) ?? 0.0,
                      currency: selectedCurrency,
                      onConfirm: (type, singlePayer, multiplePayers) {
                        setState(() {
                          paidByType = type;
                          selectedSinglePayer = singlePayer;
                          this.multiplePayers = Map.from(multiplePayers);
                          _updatePaidByController();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(height: 24),

            // Split Method
            TextField(
              readOnly: true,
              controller: _splitMethodController,
              decoration: InputDecoration(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Split', style: TextStyle(color: Colors.white)),
                    Text(
                      ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                hintText: 'Select split method',
                hintStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
              ),
              onTap: () {
                if (totalController.text.isEmpty) {
                  _showAlertDialog(
                    'Missing Information',
                    'Please fill in the Total amount first.',
                  );
                  return;
                } else if (selectedGroup == null) {
                  _showAlertDialog(
                    'Missing Information',
                    'Please select a Group first.',
                  );
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  builder: (modalContext) => DraggableScrollableSheet(
                    initialChildSize: 0.9,
                    minChildSize: 0.4,
                    maxChildSize: 0.9,
                    expand: false,
                    builder: (context, scrollController) => SplitMethodSelector(
                      onSelect: (method, selectedContext) {
                        setState(() {
                          selectedSplitMethod = method;
                          _splitMethodController.text = method;
                        });
                        Navigator.pop(selectedContext);
                      },
                      scrollController: scrollController,
                      initialSelectedMethod: selectedSplitMethod,
                      groupMembers: groupMembers,
                      totalAmount: double.tryParse(totalController.text) ?? 0.0,
                      currency: selectedCurrency,
                    ),
                  ),
                );
              },
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            SizedBox(height: 24),

            // Date
            TextField(
              readOnly: true,
              controller: _dateController,
              decoration: InputDecoration(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Date', style: TextStyle(color: Colors.white)),
                    Text(
                      ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                hintText: 'Select date',
                hintStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
              ),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                    _dateController.text = DateFormat(
                      'MMMM d, yyyy',
                    ).format(selectedDate);
                  });
                }
              },
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),

            Spacer(),

            // Create button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isFormValid()
                    ? () async {
                        // Create expense and add to selected group
                        final prefs = await SharedPreferences.getInstance();
                        final savedGroups = prefs.getStringList('groups') ?? [];

                        // Find and update the selected group
                        for (int i = 0; i < savedGroups.length; i++) {
                          final groupData =
                              json.decode(savedGroups[i])
                                  as Map<String, dynamic>;
                          if (groupData['name'] == selectedGroup) {
                            // Add expense to group details
                            final details = groupData['details'] as List;
                            details.add({
                              'name': 'You',
                              'text': 'paid for ${descController.text}',
                              'amount': double.parse(totalController.text),
                              'avatar':
                                  icons[selectedIconIndex]['icon'].codePoint,
                            });

                            // Update group total
                            groupData['total'] =
                                (groupData['total'] ?? 0.0) +
                                double.parse(totalController.text);

                            // Update group status
                            groupData['status'] = {
                              'text': 'You are owed',
                              'color': 0xFFE8F5E8,
                              'amount': double.parse(totalController.text),
                            };

                            // Save updated group
                            savedGroups[i] = json.encode(groupData);
                            break;
                          }
                        }

                        await prefs.setStringList('groups', savedGroups);

                        // Call the callback if provided
                        widget.onExpenseCreated?.call();

                        // Navigate back to group page
                        if (mounted) {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        }
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(164, 92, 56, 200),
                  disabledBackgroundColor: Color.fromARGB(36, 92, 56, 200),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Create',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 255, 255, 255),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconPicker(BuildContext context) {
    return SafeArea(
      child: GridView.builder(
        padding: EdgeInsets.all(24),
        shrinkWrap: true,
        itemCount: icons.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
        ),
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () {
              Navigator.pop(context, i);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: i == selectedIconIndex
                      ? Color(0xFF7F55FF)
                      : Colors.grey[200],
                  child: Icon(
                    icons[i]['icon'],
                    color: i == selectedIconIndex
                        ? Colors.white
                        : Color(0xFF7F55FF),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  icons[i]['label'],
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class GroupSelector extends StatefulWidget {
  final List<String> groups;
  final Function(String) onSelect;
  final ScrollController scrollController;
  final String? initialSelectedGroup;

  const GroupSelector({
    required this.groups,
    required this.onSelect,
    required this.scrollController,
    this.initialSelectedGroup,
    Key? key,
  }) : super(key: key);

  @override
  State<GroupSelector> createState() => _GroupSelectorState();
}

class _GroupSelectorState extends State<GroupSelector> {
  String? _selectedGroupInSelector;

  @override
  void initState() {
    super.initState();
    _selectedGroupInSelector = widget.initialSelectedGroup;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 39, 39, 40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Select Group',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: widget.groups.length,
              itemBuilder: (context, index) {
                final group = widget.groups[index];
                final isSelected = _selectedGroupInSelector == group;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGroupInSelector = group;
                    });
                    widget.onSelect(group);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 37, 37, 39),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.grey.shade700,
                        width: isSelected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Text(
                      group,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16), // Spacing before the button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ElevatedButton(
              onPressed: () async {
                final newGroup = await Navigator.push<Group>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddNewGroupPage(),
                  ),
                );

                if (newGroup != null) {
                  // Convert to Map and add to groups
                  final groupMap = newGroup.toJson();
                  // Get shared preferences
                  final prefs = await SharedPreferences.getInstance();
                  final savedGroups = prefs.getStringList('groups') ?? [];

                  // Add new group
                  savedGroups.add(json.encode(groupMap));
                  await prefs.setStringList('groups', savedGroups);

                  // Update the local groups list and select the new group
                  if (mounted) {
                    setState(() {
                      widget.groups.add(newGroup.name);
                    });

                    // Notify parent to select the new group
                    widget.onSelect(newGroup.name);
                    Navigator.pop(context);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(164, 92, 56, 200),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Add new group', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class CurrencySelector extends StatefulWidget {
  final List<Map<String, String>> currencies;
  final Function(String) onSelect;
  final ScrollController scrollController;

  const CurrencySelector({
    required this.currencies,
    required this.onSelect,
    required this.scrollController,
    Key? key,
  }) : super(key: key);

  @override
  State<CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<CurrencySelector> {
  String searchQuery = '';
  late List<Map<String, String>> filteredCurrencies;

  @override
  void initState() {
    super.initState();
    filteredCurrencies = widget.currencies;
  }

  void _onSearch(String value) {
    setState(() {
      searchQuery = value.toLowerCase();
      filteredCurrencies = widget.currencies.where((currency) {
        final code = currency['code']?.toLowerCase() ?? '';
        final name = currency['name']?.toLowerCase() ?? '';
        final country = currency['country']?.toLowerCase() ?? '';
        return code.contains(searchQuery) ||
            name.contains(searchQuery) ||
            country.contains(searchQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 39, 39, 40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Select Currency',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          TextField(
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search currency...',
              prefixIcon: Icon(Icons.search, color: Colors.white70),
              hintStyle: TextStyle(color: Colors.white70),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.deepPurple, width: 2),
              ),
            ),
            onChanged: _onSearch,
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 16),
          Expanded(
            child: filteredCurrencies.isEmpty
                ? Center(
                    child: Text(
                      'No currencies found',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    itemCount: filteredCurrencies.length,
                    itemBuilder: (context, index) {
                      final currency = filteredCurrencies[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${currency['code']} - ${currency['name']}',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                        subtitle: Text(
                          currency['country']!,
                          style: TextStyle(fontSize: 13, color: Colors.white70),
                        ),
                        onTap: () => widget.onSelect(currency['code']!),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SplitMethodSelector extends StatefulWidget {
  final Function(String method, BuildContext modalContext) onSelect;
  final ScrollController scrollController;
  final String? initialSelectedMethod;
  final List<Map<String, dynamic>> groupMembers;
  final double totalAmount;
  final String currency;

  const SplitMethodSelector({
    required this.onSelect,
    required this.scrollController,
    this.initialSelectedMethod,
    required this.groupMembers,
    required this.totalAmount,
    required this.currency,
    Key? key,
  }) : super(key: key);

  @override
  State<SplitMethodSelector> createState() => _SplitMethodSelectorState();
}

class _SplitMethodSelectorState extends State<SplitMethodSelector> {
  String? _selectedMethodInSelector;
  final List<String> splitMethods = const [
    'Evenly',
    'Custom Amount',
    'Percentage',
    'Shares',
  ];

  // For Evenly - track selected members
  Set<String> selectedMembers = {};

  // For Unequally - track amounts
  Map<String, double> memberAmounts = {};
  Map<String, TextEditingController> amountControllers = {};

  // For Percentage - track percentages
  Map<String, double> memberPercentages = {};
  Map<String, TextEditingController> percentageControllers = {};

  // For Shares - track shares
  Map<String, int> memberShares = {};
  Map<String, TextEditingController> shareControllers = {};

  @override
  void initState() {
    super.initState();
    _selectedMethodInSelector = widget.initialSelectedMethod;

    // Initialize all members as selected for Evenly
    for (var member in widget.groupMembers) {
      selectedMembers.add(member['email']);
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    for (var controller in amountControllers.values) {
      controller.dispose();
    }
    for (var controller in percentageControllers.values) {
      controller.dispose();
    }
    for (var controller in shareControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double get evenlyAmountPerPerson {
    if (selectedMembers.isEmpty) return 0.0;
    return widget.totalAmount / selectedMembers.length;
  }

  double get totalUnequally {
    return memberAmounts.values.fold(0.0, (sum, amount) => sum + amount);
  }

  double get totalPercentage {
    return memberPercentages.values.fold(0.0, (sum, percentage) => sum + percentage);
  }

  int get totalShares {
    return memberShares.values.fold(0, (sum, shares) => sum + shares);
  }

  Widget _buildMethodOption(String method) {
    final isSelected = _selectedMethodInSelector == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethodInSelector = method;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 37, 37, 39),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade700,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            // Method header
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    method,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Colors.deepPurple, size: 24)
                  else
                    Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 24),
                ],
              ),
            ),

            // Expanded details if selected
            if (isSelected) ...[
              // Members list
              ...widget.groupMembers.map((member) => _buildMemberItem(member)),

              // Summary
              Container(
                padding: EdgeInsets.all(16),
                child: _buildSummaryContent(),
              ),
            ],
          ],
        ),
      ),
    );
  }



  Widget _buildMemberItem(Map<String, dynamic> member) {
    final memberName = member['name'] as String;
    final memberEmail = member['email'] as String;

    switch (_selectedMethodInSelector) {
      case 'Evenly':
        return _buildEvenlyItem(memberName, memberEmail);
      case 'Custom Amount':
        return _buildUnequallyItem(memberName, memberEmail);
      case 'Percentage':
        return _buildPercentageItem(memberName, memberEmail);
      case 'Shares':
        return _buildSharesItem(memberName, memberEmail);
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildEvenlyItem(String memberName, String memberEmail) {
    final isSelected = selectedMembers.contains(memberEmail);
    final amountPerPerson = evenlyAmountPerPerson;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.currency} ${amountPerPerson.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (isSelected) {
                  selectedMembers.remove(memberEmail);
                } else {
                  selectedMembers.add(memberEmail);
                }
              });
            },
            child: Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? Colors.deepPurple : Colors.grey,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnequallyItem(String memberName, String memberEmail) {
    if (!amountControllers.containsKey(memberEmail)) {
      amountControllers[memberEmail] = TextEditingController();
    }
    final controller = amountControllers[memberEmail]!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              memberName,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade600),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade600),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              style: TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                setState(() {
                  if (amount > 0) {
                    memberAmounts[memberEmail] = amount;
                  } else {
                    memberAmounts.remove(memberEmail);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageItem(String memberName, String memberEmail) {
    if (!percentageControllers.containsKey(memberEmail)) {
      percentageControllers[memberEmail] = TextEditingController();
    }
    final controller = percentageControllers[memberEmail]!;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.currency} 0',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.0%',
                hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade600),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade600),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              style: TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (value) {
                final percentage = double.tryParse(value) ?? 0.0;
                setState(() {
                  if (percentage > 0) {
                    memberPercentages[memberEmail] = percentage;
                  } else {
                    memberPercentages.remove(memberEmail);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharesItem(String memberName, String memberEmail) {
    if (!shareControllers.containsKey(memberEmail)) {
      shareControllers[memberEmail] = TextEditingController();
    }
    final controller = shareControllers[memberEmail]!;
    final shares = memberShares[memberEmail] ?? 0;
    final amountPerShare = totalShares > 0 ? widget.totalAmount / totalShares : 0.0;
    final memberAmount = shares * amountPerShare;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${widget.currency} ${memberAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '0.0',
                hintStyle: TextStyle(color: Colors.white70, fontSize: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade600),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade600),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.deepPurple, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
              style: TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (value) {
                final shareCount = int.tryParse(value) ?? 0;
                setState(() {
                  if (shareCount > 0) {
                    memberShares[memberEmail] = shareCount;
                  } else {
                    memberShares.remove(memberEmail);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent() {
    switch (_selectedMethodInSelector) {
      case 'Evenly':
        final hasSelectedMembers = selectedMembers.isNotEmpty;
        return Text(
          '${widget.currency} ${evenlyAmountPerPerson.toStringAsFixed(2)}/person\n(${selectedMembers.length} people)',
          style: TextStyle(
            fontSize: 16,
            color: hasSelectedMembers ? Color.fromARGB(163, 14, 188, 109) : Colors.red,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        );
      case 'Custom Amount':
        final remaining = widget.totalAmount - totalUnequally;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Total', widget.totalAmount),
            _buildSummaryItem('Divided', totalUnequally),
            _buildSummaryItemWithColor('Remaining', remaining, remaining == 0.0 ? Color.fromARGB(163, 14, 188, 109) : Colors.red),
          ],
        );
      case 'Percentage':
        final remaining = 100.0 - totalPercentage;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Total Percentage', 100.0, isPercentage: true),
            _buildSummaryItem('Divided', totalPercentage, isPercentage: true),
            _buildSummaryItemWithColor('Remaining', remaining, remaining == 0.0 ? Color.fromARGB(163, 14, 188, 109) : Colors.red, isPercentage: true),
          ],
        );
      case 'Shares':
        final hasShares = totalShares > 0;
        return Text(
          '$totalShares Total Shares',
          style: TextStyle(
            fontSize: 16,
            color: hasShares ? Color.fromARGB(163, 14, 188, 109) : Colors.red,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        );
      default:
        return SizedBox.shrink();
    }
  }



  Widget _buildSummaryItem(String label, double value, {bool isPercentage = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          isPercentage
              ? '${value.toStringAsFixed(0)}%'
              : '${widget.currency} ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItemWithColor(String label, double value, Color color, {bool isPercentage = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          isPercentage
              ? '${value.toStringAsFixed(0)}%'
              : '${widget.currency} ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  bool _canConfirm() {
    switch (_selectedMethodInSelector) {
      case 'Evenly':
        return selectedMembers.isNotEmpty;
      case 'Custom Amount':
        return memberAmounts.isNotEmpty && totalUnequally == widget.totalAmount;
      case 'Percentage':
        return memberPercentages.isNotEmpty && totalPercentage == 100.0;
      case 'Shares':
        return memberShares.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 39, 39, 40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Select Split Method',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),

          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              child: Column(
                children: [
                  // Split method options with expanded details
                  ...splitMethods.map((method) => _buildMethodOption(method)),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // DONE button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canConfirm() ? () {
                widget.onSelect(_selectedMethodInSelector!, context);
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(164, 92, 56, 200),
                disabledBackgroundColor: Color.fromARGB(36, 92, 56, 200),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaidBySelector extends StatefulWidget {
  final List<Map<String, dynamic>> groupMembers;
  final ScrollController scrollController;
  final Function(
    String? type,
    String? singlePayer,
    Map<String, double> multiplePayers,
  )
  onConfirm;
  final double totalAmount;
  final String currency;

  const PaidBySelector({
    Key? key,
    required this.groupMembers,
    required this.scrollController,
    required this.onConfirm,
    required this.totalAmount,
    required this.currency,
  }) : super(key: key);

  @override
  State<PaidBySelector> createState() => _PaidBySelectorState();
}

class _PaidBySelectorState extends State<PaidBySelector> {
  String? paidByType = 'Single'; // 默认选择 Single
  String? selectedSinglePayer;
  Map<String, double> multiplePayers = {};
  Map<String, TextEditingController> controllers = {};

  Widget _buildSinglePayerItem(String memberName, String memberEmail) {
    final isSelected = selectedSinglePayer == memberEmail;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedSinglePayer = memberEmail;
        });
        // 直接确认选择并关闭，像 Select Group 一样
        widget.onConfirm('Single', memberEmail, {});
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 37, 37, 39),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade700,
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              memberName,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              memberEmail,
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiplePayerItem(String memberName, String memberEmail) {
    // 为每个成员创建独立的 controller
    if (!controllers.containsKey(memberEmail)) {
      controllers[memberEmail] = TextEditingController();
    }
    final controller = controllers[memberEmail]!;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 37, 37, 39),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade700,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberName,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  memberEmail,
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Amount',
                labelStyle: TextStyle(color: Colors.white70, fontSize: 12),
                hintText: '0.00',
                hintStyle: TextStyle(color: Colors.white70, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Color(0xFF7F55FF), width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              style: TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                setState(() {
                  if (amount > 0) {
                    // 检查是否超过总金额
                    final currentDivided = multiplePayers.values.fold(0.0, (sum, amt) => sum + amt) - (multiplePayers[memberEmail] ?? 0.0);
                    if (currentDivided + amount > widget.totalAmount) {
                      // 超过总金额时，设置为剩余金额
                      final maxAllowed = widget.totalAmount - currentDivided;
                      if (maxAllowed > 0) {
                        multiplePayers[memberEmail] = maxAllowed;
                        controller.text = maxAllowed.toString();
                      } else {
                        multiplePayers.remove(memberEmail);
                        controller.clear();
                      }
                    } else {
                      multiplePayers[memberEmail] = amount;
                    }
                  } else {
                    multiplePayers.remove(memberEmail);
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _canConfirmPaidBy() {
    if (paidByType == 'Single') {
      return selectedSinglePayer != null;
    } else if (paidByType == 'Multiple') {
      final divided = multiplePayers.values.fold(0.0, (sum, amount) => sum + amount);
      final remaining = widget.totalAmount - divided;
      return multiplePayers.isNotEmpty && remaining == 0.0;
    }
    return false;
  }

  double _getDividedAmount() {
    return multiplePayers.values.fold(0.0, (sum, amount) => sum + amount);
  }

  double _getRemainingAmount() {
    final remaining = widget.totalAmount - _getDividedAmount();
    return remaining < 0 ? 0.0 : remaining;
  }

  Widget _buildSummaryItem(String label, double amount, String currency, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          '$currency ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 14,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // 清理所有 controllers
    for (var controller in controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 39, 39, 40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag indicator
          Container(
            width: 40,
            height: 4,
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text(
            'Select Payer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),

          // Single vs Multiple payer selection
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      paidByType = 'Single';
                      selectedSinglePayer = null;
                      multiplePayers.clear();
                      // 清空所有输入框
                      for (var controller in controllers.values) {
                        controller.clear();
                      }
                      controllers.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paidByType == 'Single'
                        ? Color(0xFF7F55FF)
                        : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Single'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      paidByType = 'Multiple';
                      selectedSinglePayer = null;
                      multiplePayers.clear();
                      // 清空所有输入框
                      for (var controller in controllers.values) {
                        controller.clear();
                      }
                      controllers.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paidByType == 'Multiple'
                        ? Color(0xFF7F55FF)
                        : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Multiple'),
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Show members list if payer type is selected
          if (paidByType != null && widget.groupMembers.isNotEmpty) ...[
            Text(
              paidByType == 'Single'
                  ? 'Select who paid:'
                  : 'Select who paid and amounts:',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                controller: widget.scrollController,
                itemCount: widget.groupMembers.length,
                itemBuilder: (context, index) {
                  final member = widget.groupMembers[index];
                  final memberName = member['name'] as String;
                  final memberEmail = member['email'] as String;

                  if (paidByType == 'Single') {
                    return _buildSinglePayerItem(memberName, memberEmail);
                  } else {
                    return _buildMultiplePayerItem(memberName, memberEmail);
                  }
                },
              ),
            ),

            // 只在 Multiple 模式时显示总结信息和 Confirm 按钮
            if (paidByType == 'Multiple') ...[
              SizedBox(height: 16),

              // Total, Divided, Remaining 显示
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 39, 39, 40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Total', widget.totalAmount, widget.currency, Colors.white70),
                    _buildSummaryItem('Divided', _getDividedAmount(), widget.currency, Colors.white70),
                    _buildSummaryItem('Remaining', _getRemainingAmount(), widget.currency, _getRemainingAmount() == 0.0 ? Color.fromARGB(163, 14, 188, 109) : Colors.red),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canConfirmPaidBy()
                      ? () {
                          widget.onConfirm(
                            paidByType,
                            selectedSinglePayer,
                            multiplePayers,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(164, 92, 56, 200),
                    disabledBackgroundColor: Color.fromARGB(36, 92, 56, 200),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Confirm',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 255, 255, 255),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
