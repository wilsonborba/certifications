


import 'package:flutter/material.dart';

class DesktopPageFilter extends StatefulWidget {
  final String documentId;
  const DesktopPageFilter({super.key, required this.documentId});

  @override
  State<DesktopPageFilter> createState() => _DesktopPageFilterState();
}

class _DesktopPageFilterState extends State<DesktopPageFilter> {
  @override
  void initState() {
    super.initState();
  }

     @override
  Widget build(BuildContext context) {
       return Scaffold(
         body: Center(
           child: Text('Desktop Page Filter for document ID: ${widget.documentId}'),
         ),
       );
}
}
