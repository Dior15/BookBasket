import 'package:flutter/material.dart';

class Catalog extends StatefulWidget {
  const Catalog({super.key});

  @override
  State<StatefulWidget> createState() => CatalogState();
}

class CatalogState extends State<Catalog> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Catalog"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: EdgeInsets.fromLTRB(20.0,5.0,10.0,5.0),
                child: Text(
                  "This Week's Featured Books",
                  style: TextStyle(fontSize:24),
                ),
              )
            ),
            SizedBox(
              // This is required to set a height bound for the horizontal list view
              // Without a vertical bound, it errors and doesn't render
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 10, // Adjust this later to take a dynamic number of books
                padding: EdgeInsets.fromLTRB(10.0,0.0,10.0,5.0),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    width: 180,
                    margin: EdgeInsets.fromLTRB(10.0,0.0,10.0,0.0),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255,0,100,255),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text("Title ${index+1}")
                    )
                  );
                },
              )
            ),
            Divider(height: 20, thickness: 2, indent: 20, endIndent: 20, color: Colors.grey),
            Align(
                alignment: Alignment.topLeft,
                child: Container(
                  padding: EdgeInsets.fromLTRB(20.0,0.0,10.0,5.0),
                  child: Text(
                    "Recommended For You",
                    style: TextStyle(fontSize:24),
                  ),
                )
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 10,
                padding: EdgeInsets.fromLTRB(10.0,0.0,10.0,5.0),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    width:120,
                    margin: EdgeInsets.fromLTRB(10.0,0.0,10.0,0.0),
                    decoration: BoxDecoration(
                      color:Color.fromARGB(255, 138, 101, 236),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text("Title ${index+1}")
                    )
                  );
                }
              )
            ),
            Divider(height: 20, thickness: 2, indent: 20, endIndent: 20, color: Colors.grey),
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                padding: EdgeInsets.fromLTRB(20.0,0.0,10.0,5.0),
                child: Text(
                  "Critically Acclaimed",
                  style: TextStyle(fontSize:24),
                ),
              )
            ),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 10,
                padding: EdgeInsets.fromLTRB(10.0,0.0,10.0,5.0),
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    width:120,
                    margin: EdgeInsets.fromLTRB(10.0,0.0,10.0,0.0),
                    decoration: BoxDecoration(
                      color:Color.fromARGB(255, 143, 239, 111),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Center(
                      child: Text("Title ${index+1}")
                    )
                  );
                }
              )
            ),
            SizedBox(
              height: 75
            ),
          ]
        )
      )
    );
  }
}