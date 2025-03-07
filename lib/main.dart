import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
   double monthlyBudget = 1000.0;
  List<Expense> expenses = [];
  final TextEditingController amountController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedCategory = 'Food';

  final List<String> categories = [
    'Food',
    'Transportation',
    'Entertainment',
    'Shopping',
    'Bills',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    loadExpenses();
    loadMonthlyBudget();
  }
  void loadMonthlyBudget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      monthlyBudget = prefs.getDouble('monthlyBudget') ?? 1000.0;
    });
  }
   void saveMonthlyBudget(double newBudget) async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.setDouble('monthlyBudget', newBudget);
   }
   void _showEditBudgetDialog() {
     final TextEditingController budgetController = TextEditingController(
       text: monthlyBudget.toStringAsFixed(2),
     );

     showDialog(
       context: context,
       builder: (context) {
         return AlertDialog(
           title: const Text('Update Monthly Budget'),
           content: TextField(
             controller: budgetController,
             keyboardType: TextInputType.number,
             decoration: const InputDecoration(
               labelText: 'New Budget (₹)',
               border: OutlineInputBorder(),
             ),
           ),
           actions: [
             TextButton(
               onPressed: () {
                 Navigator.pop(context);
               },
               child: const Text('Cancel'),
             ),
             TextButton(
               onPressed: () {
                 final newBudget = double.tryParse(budgetController.text) ?? monthlyBudget;
                 setState(() {
                   monthlyBudget = newBudget;
                 });
                 saveMonthlyBudget(newBudget); // Save the new budget
                 Navigator.pop(context);
               },
               child: const Text('Save'),
             ),
           ],
         );
       },
     );
   }
   void loadExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = prefs.getString('expenses') ?? '[]';

    setState(() {
      final List<dynamic> decodedJson = json.decode(expensesJson);
      expenses = decodedJson.map((item) => Expense.fromJson(item)).toList();
    });
  }

  void saveExpenses() async {
    final prefs = await SharedPreferences.getInstance();
    final expensesJson = json.encode(expenses.map((e) => e.toJson()).toList());
    await prefs.setString('expenses', expensesJson);
  }

  void addExpense() {
    if (amountController.text.isEmpty) return;

    final double amount = double.parse(amountController.text);
    final String description = descriptionController.text;
    final DateTime now = DateTime.now();

    setState(() {
      expenses.add(Expense(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: amount,
        description: description,
        category: selectedCategory,
        date: now,
      ));
    });

    saveExpenses();

    amountController.clear();
    descriptionController.clear();
    Navigator.pop(context); // Close the bottom sheet
  }

  void deleteExpense(String id) {
    setState(() {
      expenses.removeWhere((expense) => expense.id == id);
    });

    saveExpenses();
  }

  double get remainingBudget {
    final double spent = expenses.fold(0, (sum, expense) => sum + expense.amount);
    return monthlyBudget - spent;
  }

  Map<String, double> get expensesByCategory {
    final Map<String, double> result = {};

    for (var expense in expenses) {
      result[expense.category] = (result[expense.category] ?? 0) + expense.amount;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AnalyticsPage(
                    expenses: expenses,
                    monthlyBudget: monthlyBudget,
                  ),
                ),
              );
            },
            tooltip: 'View analytics',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildBudgetCard(),
          const Divider(),
          Expanded(child: _buildExpenseList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddExpenseForm(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBudgetCard() {
    final double spent = monthlyBudget - remainingBudget;
    final double spentPercentage = (spent / monthlyBudget) * 100;

    return GestureDetector(
      onLongPress: _showEditBudgetDialog,
      child: Card(

        margin: const EdgeInsets.all(16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.black45)
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Monthly Budget:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '₹${monthlyBudget.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Spent:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '₹${spent.toStringAsFixed(2)} (${spentPercentage.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: spentPercentage > 90 ? Colors.red : Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Remaining:',
                    style: TextStyle(fontSize: 16),
                  ),
                  Text(
                    '₹${remainingBudget.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: remainingBudget < 100 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: spent / monthlyBudget,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  spentPercentage > 90 ? Colors.red : Colors.green,
                ),
                minHeight: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddExpenseForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add Expense',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount (₹)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: addExpense,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Add Expense'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpenseList() {
    if (expenses.isEmpty) {
      return const Center(
        child: Text(
          'No expenses yet. Start adding some!',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final sortedExpenses = [...expenses]..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      itemCount: sortedExpenses.length,
      itemBuilder: (context, index) {
        final expense = sortedExpenses[index];
        return Dismissible(
          key: Key(expense.id),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) {
            deleteExpense(expense.id);
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.black45),
            ),
            // elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(_getCategoryIcon(expense.category)),
                backgroundColor: _getCategoryColor(expense.category).withOpacity(0.2),
              ),
              title: Text(expense.description.isEmpty ? expense.category : expense.description),
              subtitle: Text(
                '${DateFormat('MMM d, yyyy').format(expense.date)} - ${expense.category}',
              ),
              trailing: Text(
                '₹${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_bus;
      case 'Entertainment':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt;
      default:
        return Icons.attach_money;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.red;
      case 'Transportation':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      case 'Shopping':
        return Colors.orange;
      case 'Bills':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Analytics Page for visualizing spending
class AnalyticsPage extends StatelessWidget {
  final List<Expense> expenses;
  final double monthlyBudget;

  const AnalyticsPage({
    Key? key,
    required this.expenses,
    required this.monthlyBudget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      categoryTotals[expense.category] = (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final double totalSpent = expenses.fold(0, (sum, expense) => sum + expense.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.black45),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Budget Summary',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Budget:'),
                        Text(
                          '₹${monthlyBudget.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Spent:'),
                        Text(
                          '₹${totalSpent.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Remaining:'),
                        Text(
                          '₹${(monthlyBudget - totalSpent).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: monthlyBudget - totalSpent < 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: totalSpent / monthlyBudget,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        totalSpent > monthlyBudget ? Colors.red : Colors.green,
                      ),
                      minHeight: 10,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Used ${(totalSpent / monthlyBudget * 100).toStringAsFixed(1)}% of budget',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (sortedCategories.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No expense data yet'),
                ),
              )
            else
              for (var entry in sortedCategories)
                _buildCategoryBar(
                  context,
                  entry.key,
                  entry.value,
                  totalSpent,
                ),
            const SizedBox(height: 24),
            const Text(
              'Recent Expenses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRecentExpenses(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(
      BuildContext context,
      String category,
      double amount,
      double totalSpent,
      ) {
    final double percentage = totalSpent > 0 ? amount / totalSpent * 100 : 0;
    final Color categoryColor = _getCategoryColor(category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: totalSpent > 0 ? amount / totalSpent : 0,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExpenses() {
    if (expenses.isEmpty) {
      return const Center(
        child: Text(
          'No expenses recorded yet',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final recentExpenses = [...expenses]
      ..sort((a, b) => b.date.compareTo(a.date));

    final displayExpenses = recentExpenses.length > 5
        ? recentExpenses.sublist(0, 5)
        : recentExpenses;

    return Column(
        children: displayExpenses.map((expense) {
      return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.black45),
          ),
          // elevation: 2,
          child: ListTile(
          leading: CircleAvatar(
          child: Icon(_getCategoryIcon(expense.category)),
    backgroundColor: _getCategoryColor(expense.category).withOpacity(0.2),
    ),
    title: Text(
    expense.description.isEmpty ? expense.category : expense.description,
    ),
    subtitle: Text(DateFormat('MMM d, yyyy').format(expense.date)),
    trailing: Text(
    '₹${expense.              amount.toStringAsFixed(2)}',
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
          ),
      );
        }).toList(),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.red;
      case 'Transportation':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      case 'Shopping':
        return Colors.orange;
      case 'Bills':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_bus;
      case 'Entertainment':
        return Icons.movie;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Bills':
        return Icons.receipt;
      default:
        return Icons.attach_money;
    }
  }
}

// Expense Model
class Expense {
  final String id;
  final double amount;
  final String description;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.amount,
    required this.description,
    required this.category,
    required this.date,
  });

  // Convert Expense to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
      'category': category,
      'date': date.toIso8601String(),
    };
  }

  // Create Expense from JSON
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: json['amount'],
      description: json['description'],
      category: json['category'],
      date: DateTime.parse(json['date']),
    );
  }
}