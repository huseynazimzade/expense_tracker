import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final expenses = expenseProvider.expenses;

    return Scaffold(
      appBar: AppBar(
        title: Text('Cəmi: ${expenseProvider.totalAmount.toStringAsFixed(2)} AZN', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DropdownButton<String>(
                dropdownColor: Colors.indigo,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                iconEnabledColor: Colors.white,
                value: expenseProvider.selectedCategory,
                items: ['Hamısı', 'Qida', 'Nəqliyyat', 'Əyləncə', 'Digər']
                .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                .toList(),
                onChanged: (val) {
                  if (val != null) expenseProvider.setCategoryFilter(val);
                },
              ),
            )
          ],
      ),
      // EMPTY STATE Yoxlanması (Əgər siyahı boşdursa)
      body: expenses.isEmpty
      ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Hələ heç bir xərc əlavə olunmayıb 📭',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      )
      : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final tx = expenses[index];
          return Card(
            elevation: 2,
            child: Dismissible(
              key: Key(tx.id),
              direction: DismissDirection.endToStart,
              // SİLMƏDƏN ƏVVƏL TƏSDİQ DİALOQU
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Diqqət!'),
                    content: const Text('Bu xərci silmək istədiyinizdən əminsiniz?'),
                    actions: [
                      TextButton(
                        child: const Text('İmtina'),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('Sil', style: TextStyle(color: Colors.white)),
                        onPressed: () => Navigator.of(ctx).pop(true),
                      ),
                    ],
                  ),
                );
              },
              onDismissed: (_) {
                expenseProvider.deleteExpense(tx.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Xərc silindi!')),
                );
              },
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.indigo[100],
                  child: Icon(_getCategoryIcon(tx.category), color: Colors.indigo),
                ),
                title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${tx.category} • ${DateFormat('dd MMM yyyy').format(tx.date)}'),
                trailing: Text('${tx.amount} AZN', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Xərc Əlavə Et', style: TextStyle(color: Colors.white)),
        onPressed: () => _showAddExpenseModal(context),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Qida': return Icons.fastfood;
      case 'Nəqliyyat': return Icons.directions_car;
      case 'Əyləncə': return Icons.movie;
      default: return Icons.money;
    }
  }

  void _showAddExpenseModal(BuildContext context) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCat = 'Qida';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(builder: (BuildContext context, StateSetter setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Yeni Xərc', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // FORM VALİDASİYASI
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Xərcin adı', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.isEmpty ? 'Başlıq mütləq yazılmalıdır' : null,
                  ),
                  const SizedBox(height: 16),
                  // FORM VALİDASİYASI (Rəqəm yoxlanışı)
                  TextFormField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Məbləğ (AZN)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Məbləği daxil edin';
                  if (double.tryParse(value) == null || double.parse(value) <= 0) return 'Düzgün rəqəm daxil edin';
                  return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCat,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: ['Qida', 'Nəqliyyat', 'Əyləncə', 'Digər']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedCat = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                      child: const Text('Əlavə et', style: TextStyle(color: Colors.white, fontSize: 18)),
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          final newExpense = Expense(
                            id: DateTime.now().toString(),
                            title: titleController.text,
                            amount: double.parse(amountController.text),
                            date: DateTime.now(),
                            category: selectedCat,
                          );

                          await Provider.of<ExpenseProvider>(context, listen: false).addExpense(newExpense);

                          // ASYNC GAP YOXLANMASI (ƏN VACİB!)
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}
