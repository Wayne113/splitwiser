import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:splitwiser/splitwiser/add_new_group_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CreateExpenseForm extends StatefulWidget {
  final List<String> groups;
  final VoidCallback? onExpenseCreated;
  final String? preSelectedGroup;
  final Map<String, dynamic>? editingExpense;

  const CreateExpenseForm({
    Key? key,
    required this.groups,
    this.onExpenseCreated,
    this.preSelectedGroup,
    this.editingExpense,
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
  late TextEditingController _groupController;
  String? selectedSplitMethod;

  List<Map<String, dynamic>> groupMembers = [];
  String? selectedSinglePayer;
  Map<String, double> multiplePayers = {};

  // Store split data for editing
  Map<String, double> editingSplitAmounts = {};
  Set<String> editingSelectedMembers = {};
  Map<String, double> editingPercentages = {};
  Map<String, int> editingShares = {};

  // Store actual split data from split method selector
  List<Map<String, dynamic>>? actualSplitData;

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

        // Update paid by controller after loading members (especially important for editing mode)
        if (widget.editingExpense != null && paidByType != null) {
          _updatePaidByController();
        }
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

  bool _isValidAmount(String text) {
    if (text.isEmpty) return false;

    // Check for leading zeros (except for "0" itself and "0.xx" format)
    if (text.length > 1 && text.startsWith('0') && !text.startsWith('0.')) {
      return false;
    }

    double? amount = double.tryParse(text);
    return amount != null && amount > 0;
  }

  bool _isFormValid() {
    return descController.text.isNotEmpty &&
        totalController.text.isNotEmpty &&
        _isValidAmount(totalController.text) &&
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
    _groupController = TextEditingController(text: selectedGroup ?? '');

    // Check if we're editing an existing expense
    if (widget.editingExpense != null) {
      _populateFieldsForEditing();
      // Load group members for editing mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadGroupMembers();
      });
    } else {
      // Set default date to today for new expenses
      final now = DateTime.now();
      final formattedDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      _dateController.text = formattedDate;

      // Set pre-selected group if provided
      if (widget.preSelectedGroup != null) {
        selectedGroup = widget.preSelectedGroup;
        // Load group members for the pre-selected group
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _loadGroupMembers();
        });
      }
    }
  }

  void _populateFieldsForEditing() {
    final expense = widget.editingExpense!;

    // Populate basic fields
    descController.text = expense['name'] ?? '';
    totalController.text = expense['amount']?.toString() ?? '';
    _dateController.text = expense['date'] ?? '';

    // Set group (should be non-editable)
    selectedGroup = widget.preSelectedGroup;

    // Set currency if available
    if (expense['currency'] != null) {
      selectedCurrency = expense['currency'];
      _currencyController.text = selectedCurrency;
    }

    // Set icon if available
    if (expense['avatar'] != null) {
      final avatarCodePoint = expense['avatar'] as int;
      // Find the matching icon index
      for (int i = 0; i < icons.length; i++) {
        if (icons[i]['icon'].codePoint == avatarCodePoint) {
          selectedIconIndex = i;
          break;
        }
      }
    }

    // Handle paid by information
    if (expense.containsKey('paidBy')) {
      final paidBy = expense['paidBy'] as Map<String, dynamic>;
      if (paidBy['type'] == 'single') {
        paidByType = 'Single';
        selectedSinglePayer = paidBy['payer'];
      } else if (paidBy['type'] == 'multiple') {
        paidByType = 'Multiple';
        final payers = paidBy['payers'] as Map<String, dynamic>;
        multiplePayers = Map<String, double>.from(payers);
      }
      // Don't call _updatePaidByController() here - will be called after group members are loaded
    }

    // Handle split information
    if (expense.containsKey('split')) {
      final split = expense['split'] as List<dynamic>;
      if (split.isNotEmpty) {
        final firstSplit = split.first;
        final method = firstSplit['method'] as String? ?? 'custom';

        // Store split data for editing
        editingSplitAmounts.clear();
        editingSelectedMembers.clear();
        editingPercentages.clear();
        editingShares.clear();

        for (var splitItem in split) {
          final email = splitItem['email'] as String;
          editingSelectedMembers.add(email);

          if (method == 'equally') {
            selectedSplitMethod = 'Evenly';
          } else if (method == 'custom') {
            selectedSplitMethod = 'Custom Amount';
            editingSplitAmounts[email] = (splitItem['amount'] as double? ?? 0.0);
          } else if (method == 'percentage') {
            selectedSplitMethod = 'Percentage';
            editingPercentages[email] = (splitItem['percentage'] as double? ?? 0.0);
          } else if (method == 'shares') {
            selectedSplitMethod = 'Shares';
            editingShares[email] = (splitItem['shares'] as int? ?? 1);
          }
        }

        // Also store the actual split data for immediate use
        actualSplitData = List<Map<String, dynamic>>.from(split);

        _splitMethodController.text = selectedSplitMethod ?? '';
      }
    }
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
        title: Text(
          widget.editingExpense != null ? 'Edit Expense' : 'Create Expense',
          style: TextStyle(color: Colors.white70)
        ),
        backgroundColor: Color.fromARGB(255, 39, 39, 40),
        iconTheme: IconThemeData(color: Colors.white70),
      ),
      backgroundColor: Color.fromARGB(255, 39, 39, 40),
      body: GestureDetector(
        onTap: () {
          // Dismiss keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: 24.0,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
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
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}'),
                              ),
                            ],
                            decoration: InputDecoration(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Total',
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
                              hintText: 'Enter total amount',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: (totalController.text.isNotEmpty && !_isValidAmount(totalController.text))
                                    ? Colors.red
                                    : Colors.grey,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(
                                  color: (totalController.text.isNotEmpty && !_isValidAmount(totalController.text))
                                    ? Colors.red
                                    : Colors.deepPurple,
                                  width: 2,
                                ),
                              ),
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
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
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
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
                                            _currencyController.text =
                                                selectedCurrency;
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
                    // Error message for invalid total amount
                    if (totalController.text.isNotEmpty && !_isValidAmount(totalController.text))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                        child: Text(
                          totalController.text.length > 1 &&
                          totalController.text.startsWith('0') &&
                          !totalController.text.startsWith('0.')
                            ? 'Leading zeros are not allowed'
                            : 'Amount must be greater than 0',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    SizedBox(height: 24),

                    // Group
                    TextField(
                      readOnly: true,
                      enabled: widget.editingExpense == null && widget.preSelectedGroup == null, // Disable when editing OR when group is pre-selected
                      controller: TextEditingController(
                        text: selectedGroup ?? '',
                      ),
                      decoration: InputDecoration(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Group',
                              style: TextStyle(
                                color: (widget.editingExpense != null || widget.preSelectedGroup != null)
                                  ? Colors.grey
                                  : Colors.white
                              ),
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
                        hintText: 'Select group',
                        hintStyle: TextStyle(color: Colors.white70),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: (widget.editingExpense != null || widget.preSelectedGroup != null)
                              ? Colors.grey.shade600
                              : Colors.grey
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: Colors.grey.shade600),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(
                            color: Color(0xFF7F55FF),
                            width: 2,
                          ),
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 20,
                        ),
                      ),
                      onTap: widget.editingExpense != null ? null : () {
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
                                GroupSelector(
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
                      style: TextStyle(
                        fontSize: 16,
                        color: (widget.editingExpense != null || widget.preSelectedGroup != null)
                          ? Colors.grey
                          : Colors.white
                      ),
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
                            Text(
                              'Paid by',
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
                        if (totalController.text.isEmpty) {
                          _showAlertDialog(
                            'Missing Information',
                            'Please fill in the Total amount first.',
                          );
                          return;
                        }

                        if (!_isValidAmount(totalController.text)) {
                          String errorMessage = 'Please enter a valid amount greater than 0.';
                          if (totalController.text.length > 1 &&
                              totalController.text.startsWith('0') &&
                              !totalController.text.startsWith('0.')) {
                            errorMessage = 'Leading zeros are not allowed. Please enter a valid amount.';
                          }
                          _showAlertDialog(
                            'Invalid Amount',
                            errorMessage,
                          );
                          return;
                        }

                        if (selectedGroup == null) {
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
                            builder: (context, scrollController) =>
                                PaidBySelector(
                                  groupMembers: groupMembers,
                                  scrollController: scrollController,
                                  totalAmount:
                                      double.tryParse(totalController.text) ??
                                      0.0,
                                  currency: selectedCurrency,
                                  onConfirm:
                                      (type, singlePayer, multiplePayers) {
                                        setState(() {
                                          paidByType = type;
                                          selectedSinglePayer = singlePayer;
                                          this.multiplePayers = Map.from(
                                            multiplePayers,
                                          );
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
                            Text(
                              'Split',
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
                        if (totalController.text.isEmpty) {
                          _showAlertDialog(
                            'Missing Information',
                            'Please fill in the Total amount first.',
                          );
                          return;
                        }

                        if (!_isValidAmount(totalController.text)) {
                          String errorMessage = 'Please enter a valid amount greater than 0.';
                          if (totalController.text.length > 1 &&
                              totalController.text.startsWith('0') &&
                              !totalController.text.startsWith('0.')) {
                            errorMessage = 'Leading zeros are not allowed. Please enter a valid amount.';
                          }
                          _showAlertDialog(
                            'Invalid Amount',
                            errorMessage,
                          );
                          return;
                        }

                        if (selectedGroup == null) {
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
                            builder: (context, scrollController) =>
                                SplitMethodSelector(
                                  onSelect: (method, selectedContext, splitData) {
                                    setState(() {
                                      selectedSplitMethod = method;
                                      _splitMethodController.text = method;
                                      actualSplitData = splitData; // Store the actual split data
                                    });
                                    Navigator.pop(selectedContext);
                                  },
                                  scrollController: scrollController,
                                  initialSelectedMethod: selectedSplitMethod,
                                  groupMembers: groupMembers,
                                  totalAmount:
                                      double.tryParse(totalController.text) ??
                                      0.0,
                                  currency: selectedCurrency,
                                  // Pass editing data
                                  editingSplitAmounts: widget.editingExpense != null ? editingSplitAmounts : null,
                                  editingSelectedMembers: widget.editingExpense != null ? editingSelectedMembers : null,
                                  editingPercentages: widget.editingExpense != null ? editingPercentages : null,
                                  editingShares: widget.editingExpense != null ? editingShares : null,
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

                    SizedBox(height: 40),

                    // Create button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isFormValid()
                            ? () async {
                                if (widget.editingExpense != null) {
                                  // Update existing expense
                                  await _updateExpense();
                                } else {
                                  // Create new expense
                                  await _createExpense();
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(164, 92, 56, 200),
                          disabledBackgroundColor: Color.fromARGB(
                            36,
                            92,
                            56,
                            200,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          widget.editingExpense != null ? 'Done' : 'Create',
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
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createExpense() async {
    // Create expense and add to selected group
    final prefs = await SharedPreferences.getInstance();
    final savedGroups = prefs.getStringList('groups') ?? [];

    // Find and update the selected group
    for (int i = 0; i < savedGroups.length; i++) {
      final groupData = json.decode(savedGroups[i]) as Map<String, dynamic>;
      if (groupData['name'] == selectedGroup) {
        // Create expense data with detailed payment and split info
        final expenseData = {
          'name': descController.text,
          'amount': double.parse(totalController.text),
          'currency': selectedCurrency,
          'date': selectedDate.toString().split(' ')[0],
          'avatar': icons[selectedIconIndex]['icon'].codePoint,
          'paidBy': _getPaidByData(),
          'split': _getSplitData(),
        };

        // Add expense to group expenses list
        if (groupData['expenses'] == null) {
          groupData['expenses'] = [];
        }
        (groupData['expenses'] as List).add(expenseData);

        // Update group total
        groupData['total'] = (groupData['total'] ?? 0.0) + double.parse(totalController.text);

        // Calculate and update settlement details
        _updateGroupSettlement(groupData);

        // Save updated group
        savedGroups[i] = json.encode(groupData);
        break;
      }
    }

    await prefs.setStringList('groups', savedGroups);

    // Call the callback if provided
    widget.onExpenseCreated?.call();

    // Navigate back appropriately
    if (mounted) {
      if (widget.preSelectedGroup != null) {
        // If we came from group detail page, just go back to it
        Navigator.of(context).pop();
      } else {
        // If we came from main group page, go back to main page
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _updateExpense() async {
    final prefs = await SharedPreferences.getInstance();
    final savedGroups = prefs.getStringList('groups') ?? [];
    final originalExpense = widget.editingExpense!;

    // Find and update the selected group
    for (int i = 0; i < savedGroups.length; i++) {
      final groupData = json.decode(savedGroups[i]) as Map<String, dynamic>;
      if (groupData['name'] == selectedGroup) {
        final expenses = groupData['expenses'] as List<dynamic>? ?? [];

        // Find the expense to update by matching original data more precisely
        final expenseIndex = expenses.indexWhere((expense) {
          // Match by multiple fields to ensure we get the exact expense
          bool nameMatch = expense['name'] == originalExpense['name'];
          bool dateMatch = expense['date'] == originalExpense['date'];
          bool amountMatch = (expense['amount'] as double).toStringAsFixed(2) ==
                           (originalExpense['amount'] as double).toStringAsFixed(2);

          // Also check avatar if available
          bool avatarMatch = true;
          if (expense.containsKey('avatar') && originalExpense.containsKey('avatar')) {
            avatarMatch = expense['avatar'] == originalExpense['avatar'];
          }

          return nameMatch && dateMatch && amountMatch && avatarMatch;
        });

        if (expenseIndex != -1) {
          // Update the expense data
          final updatedExpenseData = {
            'name': descController.text,
            'amount': double.parse(totalController.text),
            'currency': selectedCurrency,
            'date': selectedDate.toString().split(' ')[0], // Use consistent date format
            'avatar': icons[selectedIconIndex]['icon'].codePoint,
            'paidBy': _getPaidByData(),
            'split': _getSplitData(),
          };

          // Replace the old expense with updated data
          expenses[expenseIndex] = updatedExpenseData;

          // Recalculate group total and settlement details
          _recalculateGroupData(groupData);

          // Save updated group
          savedGroups[i] = json.encode(groupData);

          await prefs.setStringList('groups', savedGroups);

          // Call the callback if provided
          widget.onExpenseCreated?.call();

          // Navigate back to group detail page
          if (mounted) {
            Navigator.of(context).pop(updatedExpenseData);
          }
          return;
        }
        break;
      }
    }
  }

  void _recalculateGroupData(Map<String, dynamic> groupData) {
    // Recalculate total from all expenses
    final expenses = groupData['expenses'] as List<dynamic>? ?? [];
    double total = 0.0;
    for (var expense in expenses) {
      total += (expense['amount'] as double? ?? 0.0);
    }
    groupData['total'] = total;

    // Recalculate settlement details
    _updateGroupSettlement(groupData);
  }

  Map<String, dynamic> _getPaidByData() {
    if (selectedSinglePayer != null) {
      // Find the payer's email from group members
      String payerEmail = selectedSinglePayer!;
      for (var member in groupMembers) {
        if (member['name'] == selectedSinglePayer ||
            member['email'] == selectedSinglePayer) {
          payerEmail = member['email'];
          break;
        }
      }

      return {
        'type': 'single',
        'payer': payerEmail,
        'amount': double.parse(totalController.text),
      };
    } else if (multiplePayers.isNotEmpty) {
      return {'type': 'multiple', 'payers': multiplePayers};
    }

    // Default to current user
    String currentUserEmail = 'You';
    for (var member in groupMembers) {
      if (member['isCurrentUser'] == true) {
        currentUserEmail = member['email'];
        break;
      }
    }

    return {
      'type': 'single',
      'payer': currentUserEmail,
      'amount': double.parse(totalController.text),
    };
  }

  List<Map<String, dynamic>> _getSplitData() {
    // If we have actual split data from the split method selector, use it
    if (actualSplitData != null && actualSplitData!.isNotEmpty) {
      return actualSplitData!;
    }

    // Fallback to generating split data (for editing or when no split data is available)
    final splitData = <Map<String, dynamic>>[];
    final totalAmount = double.parse(totalController.text);

    if (selectedSplitMethod == 'Evenly') {
      final amountPerPerson = totalAmount / groupMembers.length;
      for (var member in groupMembers) {
        splitData.add({
          'email': member['email'],
          'name': member['name'],
          'amount': amountPerPerson,
          'method': 'evenly',
        });
      }
    } else if (selectedSplitMethod == 'Custom Amount') {
      // Use stored custom amounts if editing, otherwise default to equal split
      if (widget.editingExpense != null && editingSplitAmounts.isNotEmpty) {
        // Use the stored custom amounts from editing
        for (var member in groupMembers) {
          final memberEmail = member['email'];
          if (editingSelectedMembers.contains(memberEmail)) {
            splitData.add({
              'email': memberEmail,
              'name': member['name'],
              'amount': editingSplitAmounts[memberEmail] ?? 0.0,
              'method': 'custom',
            });
          }
        }
      } else {
        // Default behavior for new expenses
        for (var member in groupMembers) {
          splitData.add({
            'email': member['email'],
            'name': member['name'],
            'amount': totalAmount / groupMembers.length,
            'method': 'custom',
          });
        }
      }
    } else if (selectedSplitMethod == 'Percentage') {
      // Use stored percentages if editing, otherwise default to equal percentage
      if (widget.editingExpense != null && editingPercentages.isNotEmpty) {
        for (var member in groupMembers) {
          final memberEmail = member['email'];
          if (editingSelectedMembers.contains(memberEmail)) {
            final percentage = editingPercentages[memberEmail] ?? 0.0;
            splitData.add({
              'email': memberEmail,
              'name': member['name'],
              'percentage': percentage,
              'amount': totalAmount * percentage / 100,
              'method': 'percentage',
            });
          }
        }
      } else {
        for (var member in groupMembers) {
          splitData.add({
            'email': member['email'],
            'name': member['name'],
            'percentage': 100.0 / groupMembers.length,
            'amount': totalAmount * (100.0 / groupMembers.length) / 100,
            'method': 'percentage',
          });
        }
      }
    } else if (selectedSplitMethod == 'Shares') {
      // Use stored shares if editing, otherwise default to equal shares
      if (widget.editingExpense != null && editingShares.isNotEmpty) {
        final totalShares = editingShares.values.fold(0, (sum, shares) => sum + shares);
        for (var member in groupMembers) {
          final memberEmail = member['email'];
          if (editingSelectedMembers.contains(memberEmail)) {
            final shares = editingShares[memberEmail] ?? 1;
            splitData.add({
              'email': memberEmail,
              'name': member['name'],
              'shares': shares,
              'amount': totalAmount * shares / totalShares,
              'method': 'shares',
            });
          }
        }
      } else {
        for (var member in groupMembers) {
          splitData.add({
            'email': member['email'],
            'name': member['name'],
            'shares': 1,
            'amount': totalAmount / groupMembers.length,
            'method': 'shares',
          });
        }
      }
    } else {
      // Default to evenly split
      final amountPerPerson = totalAmount / groupMembers.length;
      for (var member in groupMembers) {
        splitData.add({
          'email': member['email'],
          'name': member['name'],
          'amount': amountPerPerson,
          'method': 'evenly',
        });
      }
    }

    return splitData;
  }

  void _updateGroupSettlement(Map<String, dynamic> groupData) {
    // Calculate who owes whom based on all expenses
    final expenses = groupData['expenses'] as List? ?? [];
    final memberBalances = <String, double>{};

    // Find current user's email
    String currentUserEmail = 'You';
    for (var member in groupMembers) {
      if (member['isCurrentUser'] == true) {
        currentUserEmail = member['email'];
        break;
      }
    }

    // Initialize balances for all members
    for (var member in groupMembers) {
      memberBalances[member['email']] = 0.0;
    }

    // Calculate balances from all expenses
    for (var expense in expenses) {
      final paidBy = expense['paidBy'] as Map<String, dynamic>;
      final split = expense['split'] as List<dynamic>;

      // Add amounts paid
      if (paidBy['type'] == 'single') {
        final payer = paidBy['payer'] as String;
        final amount = paidBy['amount'] as double;
        memberBalances[payer] = (memberBalances[payer] ?? 0.0) + amount;
      } else if (paidBy['type'] == 'multiple') {
        final payers = paidBy['payers'] as Map<String, dynamic>;
        payers.forEach((email, amount) {
          memberBalances[email] =
              (memberBalances[email] ?? 0.0) + (amount as double);
        });
      }

      // Subtract amounts owed
      for (var splitItem in split) {
        final email = splitItem['email'] as String;
        final amount = splitItem['amount'] as double;
        memberBalances[email] = (memberBalances[email] ?? 0.0) - amount;
      }
    }

    // Update group details and status
    final details = <Map<String, dynamic>>[];
    double userBalance = memberBalances[currentUserEmail] ?? 0.0;

    memberBalances.forEach((email, balance) {
      if (balance != 0 && email != currentUserEmail) {
        // Find member name by email
        String memberName = email;
        for (var member in groupMembers) {
          if (member['email'] == email) {
            memberName = member['name'];
            break;
          }
        }

        if (balance > 0) {
          // This member has positive balance (they paid more than their share)
          // So you owe them
          details.add({
            'name': 'You owe $memberName',
            'text': '',
            'amount': balance.abs(),
          });
        } else {
          // This member has negative balance (they paid less than their share)
          // So they owe you
          details.add({
            'name': '$memberName owes you',
            'text': '',
            'amount': balance.abs(),
          });
        }
      }
    });

    groupData['details'] = details;
    groupData['status'] = {
      'text': userBalance >= 0 ? 'You are owed' : 'You owe',
      'color': userBalance >= 0 ? 0xFFE8F5E8 : 0xFFFFE0E0,
      'amount': userBalance.abs(),
    };
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
                  final groupMap = await newGroup.toJson();
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
  final Function(String method, BuildContext modalContext, List<Map<String, dynamic>> splitData) onSelect;
  final ScrollController scrollController;
  final String? initialSelectedMethod;
  final List<Map<String, dynamic>> groupMembers;
  final double totalAmount;
  final String currency;
  final Map<String, double>? editingSplitAmounts;
  final Set<String>? editingSelectedMembers;
  final Map<String, double>? editingPercentages;
  final Map<String, int>? editingShares;

  const SplitMethodSelector({
    required this.onSelect,
    required this.scrollController,
    this.initialSelectedMethod,
    required this.groupMembers,
    required this.totalAmount,
    required this.currency,
    this.editingSplitAmounts,
    this.editingSelectedMembers,
    this.editingPercentages,
    this.editingShares,
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

    // Initialize data based on editing state
    if (widget.editingSelectedMembers != null && widget.editingSelectedMembers!.isNotEmpty) {
      // Use editing data
      selectedMembers = Set.from(widget.editingSelectedMembers!);

      if (widget.editingSplitAmounts != null) {
        memberAmounts = Map.from(widget.editingSplitAmounts!);
        // Initialize controllers with existing amounts
        for (var entry in memberAmounts.entries) {
          amountControllers[entry.key] = TextEditingController(text: entry.value.toStringAsFixed(2));
        }
      }

      if (widget.editingPercentages != null) {
        memberPercentages = Map.from(widget.editingPercentages!);
        // Initialize controllers with existing percentages
        for (var entry in memberPercentages.entries) {
          percentageControllers[entry.key] = TextEditingController(text: entry.value.toStringAsFixed(2));
        }
      }

      if (widget.editingShares != null) {
        memberShares = Map.from(widget.editingShares!);
        // Initialize controllers with existing shares
        for (var entry in memberShares.entries) {
          shareControllers[entry.key] = TextEditingController(text: entry.value.toString());
        }
      }
    } else {
      // Initialize all members as selected for Evenly (default behavior)
      for (var member in widget.groupMembers) {
        selectedMembers.add(member['email']);
      }
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
    return memberPercentages.values.fold(
      0.0,
      (sum, percentage) => sum + percentage,
    );
  }

  int get totalShares {
    return memberShares.values.fold(0, (sum, shares) => sum + shares);
  }

  List<Map<String, dynamic>> _generateSplitData() {
    final splitData = <Map<String, dynamic>>[];

    switch (_selectedMethodInSelector) {
      case 'Evenly':
        final amountPerPerson = evenlyAmountPerPerson;
        for (var member in widget.groupMembers) {
          final memberEmail = member['email'];
          if (selectedMembers.contains(memberEmail)) {
            splitData.add({
              'email': memberEmail,
              'name': member['name'],
              'amount': amountPerPerson,
              'method': 'equally',
            });
          }
        }
        break;

      case 'Custom Amount':
        for (var member in widget.groupMembers) {
          final memberEmail = member['email'];
          final amount = memberAmounts[memberEmail];
          if (amount != null && amount > 0) {
            splitData.add({
              'email': memberEmail,
              'name': member['name'],
              'amount': amount,
              'method': 'custom',
            });
          }
        }
        break;

      case 'Percentage':
        for (var member in widget.groupMembers) {
          final memberEmail = member['email'];
          final percentage = memberPercentages[memberEmail];
          if (percentage != null && percentage > 0) {
            splitData.add({
              'email': memberEmail,
              'name': member['name'],
              'percentage': percentage,
              'amount': (percentage / 100.0) * widget.totalAmount,
              'method': 'percentage',
            });
          }
        }
        break;

      case 'Shares':
        final totalSharesCount = totalShares;
        for (var member in widget.groupMembers) {
          final memberEmail = member['email'];
          final shares = memberShares[memberEmail];
          if (shares != null && shares > 0) {
            splitData.add({
              'email': memberEmail,
              'name': member['name'],
              'shares': shares,
              'amount': totalSharesCount > 0 ? (shares / totalSharesCount) * widget.totalAmount : 0.0,
              'method': 'shares',
            });
          }
        }
        break;
    }

    return splitData;
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
            color: isSelected ? Color(0xFF7F55FF) : Colors.grey.shade700,
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
                    Icon(
                      Icons.radio_button_unchecked,
                      color: Colors.grey,
                      size: 24,
                    ),
                ],
              ),
            ),

            if (isSelected) ...[
              ...widget.groupMembers.map((member) => _buildMemberItem(member)),
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              style: TextStyle(color: Colors.white, fontSize: 14),
              onTap: () {
                // 延迟滚动，等待键盘弹出
                Future.delayed(Duration(milliseconds: 300), () {
                  if (widget.scrollController.hasClients) {
                    widget.scrollController.animateTo(
                      widget.scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              },
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
    final percentage = memberPercentages[memberEmail] ?? 0.0;
    final memberAmount = (percentage / 100.0) * widget.totalAmount;

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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '0.00%',
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              style: TextStyle(color: Colors.white, fontSize: 14),
              onTap: () {
                // 延迟滚动，等待键盘弹出
                Future.delayed(Duration(milliseconds: 300), () {
                  if (widget.scrollController.hasClients) {
                    widget.scrollController.animateTo(
                      widget.scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              },
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
    final amountPerShare = totalShares > 0
        ? widget.totalAmount / totalShares
        : 0.0;
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
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: '0.00',
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
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
                isDense: true,
              ),
              style: TextStyle(color: Colors.white, fontSize: 14),
              onTap: () {
                // 延迟滚动，等待键盘弹出
                Future.delayed(Duration(milliseconds: 300), () {
                  if (widget.scrollController.hasClients) {
                    widget.scrollController.animateTo(
                      widget.scrollController.position.maxScrollExtent,
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              },
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
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem('Per Person', evenlyAmountPerPerson),
            _buildEvenlyPeopleItem('People', selectedMembers.length, hasSelectedMembers),
          ],
        );
      case 'Custom Amount':
        final remaining = widget.totalAmount - totalUnequally;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItemWithColor('Total', widget.totalAmount, Colors.white70),
            _buildSummaryItemWithColor('Divided', totalUnequally, Colors.white70),
            _buildSummaryItemWithColor(
              'Remaining',
              remaining,
              remaining == 0.0 ? Color.fromARGB(163, 14, 188, 109) : Colors.red,
            ),
          ],
        );
      case 'Percentage':
        final remaining = 100.0 - totalPercentage;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItemWithColor('Total', 100.0, Colors.white70, isPercentage: true),
            _buildSummaryItemWithColor('Divided', totalPercentage, Colors.white70, isPercentage: true),
            _buildSummaryItemWithColor(
              'Remaining',
              remaining,
              remaining == 0.0 ? Color.fromARGB(163, 14, 188, 109) : Colors.red,
              isPercentage: true,
            ),
          ],
        );
      case 'Shares':
        return Text(
          '$totalShares Total Shares',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        );
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildSummaryItem(
    String label,
    double value, {
    bool isPercentage = false,
  }) {
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
            color: Color.fromARGB(163, 14, 188, 109),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItemWithColor(
    String label,
    double value,
    Color color, {
    bool isPercentage = false,
  }) {
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

  Widget _buildEvenlyPeopleItem(String label, int count, bool hasSelectedMembers) {
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
          '$count',
          style: TextStyle(
            fontSize: 14,
            color: hasSelectedMembers ? Colors.white : Colors.red,
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
    // Check if keyboard is visible
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 39, 39, 40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Column(
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
                  padding: EdgeInsets.only(
                    bottom: isKeyboardVisible ? 300 : 20, // 为浮动总结和键盘留出空间
                  ),
                  child: Column(
                    children: [
                      // Split method options with expanded details
                      ...splitMethods.map(
                        (method) => _buildMethodOption(method),
                      ),
                    ],
                  ),
                ),
              ),

              // Summary section (only when method is selected and keyboard is not visible)
              if (_selectedMethodInSelector != null && !isKeyboardVisible) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 39, 39, 40),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildSummaryContent(),
                ),
                SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canConfirm()
                      ? () {
                          final splitData = _generateSplitData();
                          widget.onSelect(_selectedMethodInSelector!, context, splitData);
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
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Floating summary when keyboard is visible
          if (_selectedMethodInSelector != null && isKeyboardVisible)
            Positioned(
              bottom: keyboardHeight - 16,
              left: -20,
              right: -10,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 39, 39, 40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildSummaryContent()),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Dismiss keyboard
                        FocusScope.of(context).unfocus();
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.keyboard_hide,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
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
          border: Border.all(color: Colors.grey.shade700, width: 1.0),
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
        border: Border.all(color: Colors.grey.shade700, width: 1.0),
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
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
              onTap: () {
                // 延迟滚动，等待键盘弹出
                Future.delayed(Duration(milliseconds: 500), () {
                  if (widget.scrollController.hasClients) {
                    // 滚动到最大位置，确保最后的输入框可见
                    final maxScroll = widget.scrollController.position.maxScrollExtent;
                    widget.scrollController.animateTo(
                      maxScroll,
                      duration: Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                });
              },
              onChanged: (value) {
                final amount = double.tryParse(value) ?? 0.0;
                setState(() {
                  if (amount > 0) {
                    // 检查是否超过总金额
                    final currentDivided =
                        multiplePayers.values.fold(
                          0.0,
                          (sum, amt) => sum + amt,
                        ) -
                        (multiplePayers[memberEmail] ?? 0.0);
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
      final divided = multiplePayers.values.fold(
        0.0,
        (sum, amount) => sum + amount,
      );
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

  Widget _buildSummaryItem(
    String label,
    double amount,
    String currency,
    Color color,
  ) {
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
    // Check if keyboard is visible
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 39, 39, 40),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          Column(
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
                    padding: EdgeInsets.only(
                      bottom: isKeyboardVisible ? 400 : 20, // 为浮动总结和键盘留出空间
                    ),
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
                if (paidByType == 'Multiple' && !isKeyboardVisible) ...[
                  SizedBox(height: 16),

                  // Total, Divided, Remaining 显示（只在键盘不可见时显示）
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 39, 39, 40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total',
                          widget.totalAmount,
                          widget.currency,
                          Colors.white70,
                        ),
                        _buildSummaryItem(
                          'Divided',
                          _getDividedAmount(),
                          widget.currency,
                          Colors.white70,
                        ),
                        _buildSummaryItem(
                          'Remaining',
                          _getRemainingAmount(),
                          widget.currency,
                          _getRemainingAmount() == 0.0
                              ? Color.fromARGB(163, 14, 188, 109)
                              : Colors.red,
                        ),
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
                        disabledBackgroundColor: Color.fromARGB(
                          36,
                          92,
                          56,
                          200,
                        ),
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

          // 浮动的 Total/Divided/Remaining 显示（只在 Multiple 模式且键盘可见时显示）
          if (paidByType == 'Multiple' && isKeyboardVisible)
            Positioned(
              bottom: keyboardHeight - 16,
              left: -20,
              right: -10,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 39, 39, 40),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem(
                            'Total',
                            widget.totalAmount,
                            widget.currency,
                            Colors.white70,
                          ),
                          _buildSummaryItem(
                            'Divided',
                            _getDividedAmount(),
                            widget.currency,
                            Colors.white70,
                          ),
                          _buildSummaryItem(
                            'Remaining',
                            _getRemainingAmount(),
                            widget.currency,
                            _getRemainingAmount() == 0.0
                                ? Color.fromARGB(163, 14, 188, 109)
                                : Colors.red,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        // Dismiss keyboard
                        FocusScope.of(context).unfocus();
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(
                          Icons.keyboard_hide,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
