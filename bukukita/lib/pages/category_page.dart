import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/database.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({Key? key}) : super(key: key);

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  bool isPengeluaran = true;
  int type = 2; //pengeluaran
  final AppDb database = AppDb();
  TextEditingController categoryNameController = TextEditingController();

  Future insert(String name, int type) async {
    DateTime now = DateTime.now();
    final row = await database.into(database.categories).insertReturning(
        CategoriesCompanion.insert(
            name: name, type: type, createdAt: now, updateAt: now));

    print('MASUK :' + row.toString());
  }

  Future<List<Category>> getAllCategory(int type) async {
    return await database.getAllCategoryRepo(type);
  }

  Future update(int categoryId, String newName) async {
    await database.updateCategoryRepo(categoryId, newName);
  }

  void openDialog(Category? category) {
    if (category != null) {
      categoryNameController.text = category.name;
    }
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
              child: Center(
                  child: Column(
                children: [
                  Text(
                    (isPengeluaran)
                        ? "Tambah Pengeluaran"
                        : "Tambah Pendapatan",
                    style: GoogleFonts.montserrat(
                        fontSize: 18,
                        color: (isPengeluaran) ? Colors.red : Colors.green),
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: categoryNameController,
                    decoration: InputDecoration(
                        border: OutlineInputBorder(), hintText: "Name"),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                      onPressed: () {
                        if (category == null) {
                          insert(categoryNameController.text,
                              isPengeluaran ? 2 : 1);
                        } else {
                          update(category.id, categoryNameController.text);
                        }

                        Navigator.of(context, rootNavigator: true)
                            .pop('dialog');
                        setState(() {});
                        categoryNameController.clear();
                      },
                      child: Text("Simpan"))
                ],
              )),
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Switch(
                value: isPengeluaran,
                onChanged: (bool value) {
                  setState(() {
                    isPengeluaran = value;
                    type = value ? 2 : 1;
                  });
                },
                inactiveTrackColor: Colors.green[200],
                inactiveThumbColor: Colors.green,
                activeColor: Colors.red,
              ),
              IconButton(
                  onPressed: () {
                    openDialog(null);
                  },
                  icon: Icon(Icons.add))
            ],
          ),
        ),
        FutureBuilder<List<Category>>(
            future: getAllCategory(type),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              } else {
                if (snapshot.hasData) {
                  if (snapshot.data!.length > 0) {
                    return ListView.builder(
                        shrinkWrap: true,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Card(
                              elevation: 10,
                              child: ListTile(
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.delete),
                                        onPressed: () {
                                          database.deleteCategoryRepo(
                                              snapshot.data![index].id);
                                          setState(() {});
                                        },
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          openDialog(snapshot.data![index]);
                                        },
                                      )
                                    ],
                                  ),
                                  leading: Container(
                                      padding: EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: (isPengeluaran)
                                          ? Icon(Icons.upload,
                                              color: Colors.redAccent[400])
                                          : Icon(
                                              Icons.download,
                                              color: Colors.greenAccent[400],
                                            )),
                                  title: Text(snapshot.data![index].name)),
                            ),
                          );
                        });
                  } else {
                    return Center(
                      child: Text("No has Data"),
                    );
                  }
                } else {
                  return Center(
                    child: Text("No has Data"),
                  );
                }
              }
            }),
      ],
    ));
  }
}
