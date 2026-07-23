import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';

class ExpenseProvider with ChangeNotifier {
  late Box<Expense> _expenseBox;
  String _selectedCategory = 'Hamısı';

  String get selectedCategory => _selectedCategory;

  List<Expense> get expenses {
    final allExpenses = _expenseBox.values.toList();
    // Sıralama (Tarixə görə ən yenilər yuxarıda)
    allExpenses.sort((a, b) => b.date.compareTo(a.date));

    // Filtrasiya
    if (_selectedCategory == 'Hamısı') return allExpenses;
    return allExpenses.where((e) => e.category == _selectedCategory).toList();
  }

  Future<void> initDB() async {
    _expenseBox = await Hive.openBox<Expense>('expenses');
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _expenseBox.put(expense.id, expense);
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await expense.save();
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
    notifyListeners();
  }

  void setCategoryFilter(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  double get totalAmount {
    return expenses.fold(0.0, (sum, item) => sum + item.amount);
  }
}
