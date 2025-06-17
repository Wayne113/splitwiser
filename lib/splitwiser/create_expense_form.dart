import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:splitwiser/splitwiser/add_new_group_page.dart';

class CreateExpenseForm extends StatefulWidget {
  final List<String> groups;

  const CreateExpenseForm({Key? key, required this.groups}) : super(key: key);

  @override
  _CreateExpenseFormState createState() => _CreateExpenseFormState();
}

class _CreateExpenseFormState extends State<CreateExpenseForm> {
  // Icon picker
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

  // Currency picker
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
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
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
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.8,
                    minChildSize: 0.4,
                    maxChildSize: 0.8,
                    expand: false,
                    builder: (context, scrollController) => GroupSelector(
                      groups: widget.groups,
                      scrollController: scrollController,
                      initialSelectedGroup: selectedGroup,
                      onSelect: (g) {
                        setState(() {
                          selectedGroup = g;
                        });
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
                  _showAlertDialog('Missing Information', 'Please fill in the Total amount first.');
                  return;
                } else if (selectedGroup == null) {
                  _showAlertDialog('Missing Information', 'Please select a Group first.');
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.8,
                    minChildSize: 0.4,
                    maxChildSize: 0.8,
                    expand: false,
                    builder: (context, scrollController) =>
                        _buildPaidBySelector(context, scrollController),
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
                  _showAlertDialog('Missing Information', 'Please fill in the Total amount first.');
                  return;
                } else if (selectedGroup == null) {
                  _showAlertDialog('Missing Information', 'Please select a Group first.');
                  return;
                }
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (modalContext) => DraggableScrollableSheet(
                    initialChildSize: 0.8,
                    minChildSize: 0.4,
                    maxChildSize: 0.8,
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
                    ? () {
                        // TODO: Implement create expense logic here
                        print('Create button pressed');
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

  Widget _buildPaidBySelector(
    BuildContext context,
    ScrollController scrollController,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Color.fromARGB(255, 39, 39, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Select Payer',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      paidByType = 'Single payer';
                      _paidByController.text = paidByType!;
                    });
                    print('Paid by controller text: ${_paidByController.text}');
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paidByType == 'Single payer'
                        ? Color(0xFF7F55FF)
                        : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Single payer'),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      paidByType = 'Multiple payer';
                      _paidByController.text = paidByType!;
                    });
                    print('Paid by controller text: ${_paidByController.text}');
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: paidByType == 'Multiple payer'
                        ? Color(0xFF7F55FF)
                        : Colors.grey.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Multiple payer'),
                ),
              ),
            ],
          ),
        ],
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
      color: Color.fromARGB(255, 39, 39, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddNewGroupPage(),
                  ),
                );
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
      color: Color.fromARGB(255, 39, 39, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

  const SplitMethodSelector({
    required this.onSelect,
    required this.scrollController,
    this.initialSelectedMethod,
    Key? key,
  }) : super(key: key);

  @override
  State<SplitMethodSelector> createState() => _SplitMethodSelectorState();
}

class _SplitMethodSelectorState extends State<SplitMethodSelector> {
  String? _selectedMethodInSelector;
  final List<String> splitMethods = const [
    'Evenly',
    'By percentage',
    'By shares',
    'By exact amounts',
  ];

  @override
  void initState() {
    super.initState();
    _selectedMethodInSelector = widget.initialSelectedMethod;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      color: Color.fromARGB(255, 39, 39, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            child: ListView.builder(
              controller: widget.scrollController,
              itemCount: splitMethods.length,
              itemBuilder: (context, index) {
                final method = splitMethods[index];
                final isSelected = _selectedMethodInSelector == method;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMethodInSelector = method;
                    });
                    widget.onSelect(method, context);
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
                      method,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
