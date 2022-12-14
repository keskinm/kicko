import 'package:flutter/material.dart';
import 'package:kicko/pages/my_account.dart';

AppBar protoAppBar(String text) {
  return AppBar(
    // backgroundColor: Colors.deepOrangeAccent,
    // No need backgroundColor because done in ThemData of MaterialApp.
    title: Center(child: Text(text)),
  );
}

AppBar menuAppBar(String text, BuildContext pageContext) {
  return AppBar(
    title: Text(text),
    centerTitle: true,
    // backgroundColor: Colors.orange,
    // No need backgroundColor because done in ThemData of MaterialApp. ??
    actions: [
      PopupMenuButton(itemBuilder: (context) {
        return [
          const PopupMenuItem<int>(
            value: 0,
            child: Text("Mon compte"),
          ),
          const PopupMenuItem<int>(
            value: 1,
            child: Text("Mes paramètres"),
          ),
          const PopupMenuItem<int>(
            value: 2,
            child: Text("Se déconnecter"),
          ),
        ];
      }, onSelected: (value) {
        if (value == 0) {
          Navigator.push(pageContext, MaterialPageRoute(builder: (context) {
            return const MyAccount();
          }));
        } else if (value == 1) {
        } else if (value == 2) {}
      }),
    ],
  );
}
