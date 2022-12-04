import 'dart:io';

import 'package:drift/drift.dart';
// These imports are used to open the database
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:bukukita/models/category.dart';
import 'package:bukukita/models/transaction.dart';
import 'package:bukukita/models/transaction_with_category.dart';

part 'database.g.dart';

@DriftDatabase(
  // relative import for the drift file. Drift also supports `package:`
  // imports
  tables: [Categories, Transactions],
)
class AppDb extends _$AppDb {
  AppDb() : super(_openConnection());

  @override
  int get schemaVersion => 1;

//crud category
  Future<List<Category>> getAllCategoryRepo(int type) async {
    return await (select(categories)..where((tbl) => tbl.type.equals(type)))
        .get();
  }

//update katagory
  Future updateCategoryRepo(int id, String name) async {
    return (update(categories)..where((tbl) => tbl.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
      ),
    );
  }

//delete
  Future deleteCategoryRepo(int id) async {
    return (delete(categories)..where((tbl) => tbl.id.equals(id))).go();
  }

//TRANSACTION
  Stream<List<TransactionWithCategory>> getTransactionByDateRepo(
      DateTime date) {
    final query = (select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.category_id))
    ])
      ..where(transactions.transaction_date.equals(date)));
    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          row.readTable(transactions),
          row.readTable(categories),
        );
      }).toList();
    });
  }

// update transaksi
  Future updateTransactionRepo(int id, int jumlah, int categoryId,
      DateTime transactionDate, String nameDetail) async {
    return (update(transactions)..where((tbl) => tbl.id.equals(id))).write(
      TransactionsCompanion(
        name: Value(nameDetail),
        amount: Value(jumlah),
        category_id: Value(categoryId),
        transaction_date: Value(transactionDate),
      ),
    );
  }

  Future deleteTransactionRepo(int id) async {
    return (delete(transactions)..where((tbl) => tbl.id.equals(id))).go();
  }
}

// PR BUAT SELANJUTNYA
// UPDATE BELUM AUTO RESPON
// TOTAL PEMASUKAN DAN PENGELUARAN PERBULAN

// SELECT SUM (jumlah) FROM transactions WHERE type 1 and MONTH ('2022-1-12') AND YEAR()

LazyDatabase _openConnection() {
  // the LazyDatabase util lets us find the right location for the file async.
  return LazyDatabase(() async {
    // put the database file, called db.sqlite here, into the documents folder
    // for your app.
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));

    return NativeDatabase.createInBackground(file);
  });
}
