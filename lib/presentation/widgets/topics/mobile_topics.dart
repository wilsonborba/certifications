



import 'package:accredit/presentation/widgets/topics/base_topics.dart';
import 'package:flutter/material.dart';

class MobileTopics extends BaseTopics {

  const MobileTopics({super.key, required String itemName}) : super(itemName: itemName);

  @override
  State<MobileTopics> createState() => _MobileTopicsState();
}

class _MobileTopicsState extends State<MobileTopics> {
  @override
  void initState() {
    super.initState();
  }

  // ---- Layout identical to your original MobileAttachment ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Your mobile topics layout here
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('Mobile Topics Content'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}