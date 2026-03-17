import 'package:flutter/material.dart';

//////////////////////////////////////////////////////////
// EXPENSE ITEM MODEL
//////////////////////////////////////////////////////////

class ExpenseItem {
  TextEditingController billRefController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  DateTime? billDate;
  String fileName = "";
}

//////////////////////////////////////////////////////////
// EXPENSE PAGE
//////////////////////////////////////////////////////////

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {

  String _selectedExpenseType = "Select Expense Type";
  String _selectedProjectType = "Select Project Type";
  String _selectedGST = "YES";

  List<ExpenseItem> _expenseItems = [ExpenseItem()];

  //////////////////////////////////////////////////////
  // EXPENSE PAGE UI
  //////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 40),

          const Text(
            "Add Expenses",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          const Text(
            "Menu Loaded",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.green,
            ),
          ),

          const SizedBox(height: 30),

          //////////////////////////////////////////////////////
          // EXPENSE TYPE
          //////////////////////////////////////////////////////
          const Text("Expense Type",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          _buildDropdown(
            value: _selectedExpenseType,
            items: const [
              "Select Expense Type",
              "Accommodation",
              "Food",
              "Fuel Bills",
              "Local Purchase",
              "Local Transport/Courier",
              "Office Capex",
              "Office Opex",
              "Other",
              "Tech Consultation",
              "Travel",
            ],
            onChanged: (val) => setState(() => _selectedExpenseType = val),
          ),

          const SizedBox(height: 20),

          //////////////////////////////////////////////////////
          // PROJECT TYPE
          //////////////////////////////////////////////////////
          const Text("Project Type",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          _buildDropdown(
            value: _selectedProjectType,
            items: const [
              "Select Project Type",
              "ATM_DOORS",
              "ATM_HV_PANEL",
              "ATM_Fans_Filter",
              "ATM_C-Sharp",
              "ATM_RFQ",
              "ATM_Plant1",
              "EV_RnD",
              "EV_Consultaion",
              "MICROBOTSS",
              "OFFICE_EXP",
            ],
            onChanged: (val) => setState(() => _selectedProjectType = val),
          ),

          const SizedBox(height: 20),

          //////////////////////////////////////////////////////
          // GST
          //////////////////////////////////////////////////////
          const Text("GST",
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          _buildDropdown(
            value: _selectedGST,
            items: const ["YES", "NO"],
            onChanged: (val) => setState(() => _selectedGST = val),
          ),

          const SizedBox(height: 30),

          //////////////////////////////////////////////////////
          // MULTIPLE EXPENSE ITEMS
          //////////////////////////////////////////////////////

          ...List.generate(_expenseItems.length, (index) {

            final item = _expenseItems[index];

            return Container(
              margin: const EdgeInsets.only(bottom: 25),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Column(
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Text("Expense #${index + 1}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold)),

                      IconButton(
                        icon: Icon(
                          _expenseItems.length == 1
                              ? Icons.add_circle
                              : Icons.remove_circle,
                          color: _expenseItems.length == 1
                              ? Colors.green
                              : Colors.red,
                        ),
                        onPressed: () {
                          setState(() {
                            if (_expenseItems.length == 1) {
                              _expenseItems.add(ExpenseItem());
                            } else {
                              _expenseItems.removeAt(index);
                            }
                          });
                        },
                      )
                    ],
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: item.billRefController,
                    decoration: const InputDecoration(
                      labelText: "Bill / UTR Ref Number",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: item.descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  GestureDetector(
                    onTap: () async {

                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                      );

                      if (picked != null) {
                        setState(() {
                          item.billDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.billDate == null
                              ? "Select Bill Date"
                              : "${item.billDate!.day}/${item.billDate!.month}/${item.billDate!.year}"),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: item.amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        item.fileName = "File_Selected.pdf";
                      });
                    },
                    icon: const Icon(Icons.upload_file),
                    label: Text(item.fileName.isEmpty
                        ? "Upload File"
                        : item.fileName),
                  ),
                ],
              ),
            );
          }),

          //////////////////////////////////////////////////////
          // SUBMIT BUTTONS
          //////////////////////////////////////////////////////

          Row(
            children: [

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _expenseItems = [ExpenseItem()];
                    });
                  },
                  child: const Text("Cancel"),
                ),
              ),

              const SizedBox(width: 15),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("Expense Submitted")),
                    );
                  },
                  child: const Text("Submit"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  //////////////////////////////////////////////////////
  // DROPDOWN WIDGET
  //////////////////////////////////////////////////////

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          ))
              .toList(),
          onChanged: (val) => onChanged(val!),
        ),
      ),
    );
  }
}