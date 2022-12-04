import 'dart:ffi';

import 'package:bukukita/models/database.dart';
import 'package:bukukita/models/transaction_with_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  final TransactionWithCategory? transactionWithCategory;
  const TransactionPage({Key? key, required this.transactionWithCategory})
      : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final AppDb database = AppDb(); //variabel / object database
  bool isPengeluaran = true;
  late int type;
  List<String> list = ['Makan', 'Transportasi', 'Hotel', 'Bioskop'];
  late String dropDownValue = list.first;
  TextEditingController jumlahController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController detailController = TextEditingController();
  Category? selectedCategory;

  // insert ke database
  Future insert(
      int jumlah, DateTime date, String nameDetail, int categoryId) async {
    DateTime now = DateTime.now();
    final row = await database.into(database.transactions).insertReturning(
        TransactionsCompanion.insert(
            name: nameDetail,
            category_id: categoryId,
            transaction_date: date,
            amount: jumlah,
            createdAt: now,
            updateAt: now));
    print('TEST SAVE : ' + row.toString());
  }

  Future<List<Category>> getAllCategory(int type) async {
    return await database.getAllCategoryRepo(type);
  }

  Future update(int transactionId, int jumlah, int categoryId,
      DateTime transactionDate, String nameDetail) async {
    await database.updateTransactionRepo(
        transactionId, jumlah, categoryId, transactionDate, nameDetail);
  }

  @override
  void initState() {
    // TODO: implement initState
    if (widget.transactionWithCategory != null) {
      updateTransactionView(widget.transactionWithCategory!);
    } else {
      type = 2;
    }

    super.initState();
  }

  void updateTransactionView(TransactionWithCategory transactionWithCategory) {
    jumlahController.text =
        transactionWithCategory.transaction.amount.toString();
    detailController.text = transactionWithCategory.transaction.name;
    dateController.text = DateFormat("yyyy-MM-dd")
        .format(transactionWithCategory.transaction.transaction_date);
    type = transactionWithCategory.category.type;
    (type == 2) ? isPengeluaran = true : isPengeluaran = false;
    selectedCategory = transactionWithCategory.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Tambah Transaksi")),
      body: SingleChildScrollView(
          child: SafeArea(
              child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Switch(
                value: isPengeluaran,
                onChanged: (bool value) {
                  setState(() {
                    isPengeluaran = value;
                    type = (isPengeluaran) ? 2 : 1;
                    selectedCategory = null;
                  });
                },
                inactiveTrackColor: Colors.green[200],
                inactiveThumbColor: Colors.green,
                activeColor: Colors.red,
              ),
              Text(
                isPengeluaran ? 'Pengeluaran' : 'Pemasukan',
                style: GoogleFonts.montserrat(fontSize: 14),
              )
            ],
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  border: UnderlineInputBorder(), labelText: "Jumlah"),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Kategori',
              style: GoogleFonts.montserrat(fontSize: 16),
            ),
          ),
          FutureBuilder<List<Category>>(
              future: getAllCategory(type),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child:
                        CircularProgressIndicator(), //membuat loading saat memperoses jika ada data
                  );
                } else {
                  if (snapshot.hasData) {
                    if (snapshot.data!.length > 0) {
                      selectedCategory = (selectedCategory == null)
                          ? snapshot.data!.first
                          : selectedCategory;
                      print('apanihhh : ' + snapshot.toString());
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        //membuat dropdown button dengan mengambil data di database
                        child: DropdownButton<Category>(
                            value: (selectedCategory == null)
                                ? snapshot.data!.first
                                : selectedCategory,
                            isExpanded: true,
                            icon: Icon(Icons.arrow_downward),
                            items: snapshot.data!.map((Category item) {
                              return DropdownMenuItem<Category>(
                                value: item,
                                child: Text(item.name),
                              );
                            }).toList(),
                            onChanged: (Category? value) {
                              setState(() {
                                selectedCategory = value;
                              });
                            }),
                      );
                    } else {
                      return Center(
                        child: Text("Data Kosong"),
                      );
                    }
                  }
                  return Center(
                    child: Text("Tidak Ada Data"),
                  );
                }
              }),
          SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              readOnly: true,
              controller: dateController,
              decoration: InputDecoration(labelText: "Masukan Tanggal"),
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2099));

                if (pickedDate != null) {
                  String formattedDate =
                      DateFormat('yyyy-MM-dd').format(pickedDate);

                  dateController.text = formattedDate;
                }
              },
            ),
          ),
          SizedBox(height: 25),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextFormField(
              controller: detailController,
              decoration: InputDecoration(
                  border: UnderlineInputBorder(), labelText: "Detail"),
            ),
          ),
          SizedBox(height: 25),
          Center(
              child: ElevatedButton(
                  onPressed: () async {
                    (widget.transactionWithCategory == null)
                        ? insert(
                            int.parse(jumlahController.text),
                            DateTime.parse(dateController.text),
                            detailController.text,
                            selectedCategory!.id)
                        : await update(
                            widget.transactionWithCategory!.transaction.id,
                            int.parse(jumlahController.text),
                            selectedCategory!.id,
                            DateTime.parse(jumlahController.text),
                            detailController.text);
                    setState(() {});
                    Navigator.pop(context, true);
                  },
                  child: Text("Simpan")))
        ],
      ))),
    );
  }
}
