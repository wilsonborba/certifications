


import 'package:flutter/material.dart';

class MobilePageFilter extends StatefulWidget {
  final String documentId;
  const MobilePageFilter({super.key, required this.documentId});

  @override
  State<MobilePageFilter> createState() => _MobilePageFilterState();
}

class _MobilePageFilterState extends State<MobilePageFilter> {
  @override
  void initState() {
    super.initState();
  }

     @override
  Widget build(BuildContext context) {
       return Scaffold(
         body: Center(
           child: Text('Mobile Page Filter for document ID: ${widget.documentId}'),
         ),
       );
}
}
