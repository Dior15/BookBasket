import 'package:flutter/material.dart';

class Basket extends StatefulWidget {
  const Basket({super.key});

  @override
  State<StatefulWidget> createState() => BasketState();
}

class BasketState extends State<Basket> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Your Basket"),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.6,
        padding: EdgeInsets.all(10.0),
        children: List.generate(
          15,
          (index) => Container(
            height: 200,
            width: 100,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 138, 101, 236),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text("Title ${index+1}")
            )
          )
        )
      )
    );
  }
}