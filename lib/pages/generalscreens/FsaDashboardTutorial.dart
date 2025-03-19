import 'package:flutter/material.dart';
import 'package:app_tutorial/app_tutorial.dart';

void showAppTutorial(BuildContext context, GlobalKey _trainingKey, GlobalKey _campaignKey) {
  print("usgfyugsyfu");
  List<TutorialItem> items = [
    TutorialItem(
      globalKey: _trainingKey,
      color: Colors.black.withOpacity(0.6),
      borderRadius: const Radius.circular(15.0),
      shapeFocus: ShapeFocus.roundedSquare,
      child: const TutorialItemContent(
        title: 'Increment button',
        content: 'This is the increment button',
      ),
    ),
    TutorialItem(
      globalKey: _campaignKey,
      shapeFocus: ShapeFocus.square,
      borderRadius: const Radius.circular(15.0),
      child: const TutorialItemContent(
        title: 'Counter text',
        content: 'This is the text that displays the status of the counter',
      ),
    ),
  ];

  Future.delayed(const Duration(milliseconds: 200)).then((value) {
    Tutorial.showTutorial(context, items, onTutorialComplete: () {
      print('Tutorial is complete!');
    });
  });
}

class TutorialItemContent extends StatelessWidget {
  final String title;
  final String content;

  const TutorialItemContent({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Center(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.1),
          child: Column(
            children: [
              Text(title, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 10.0),
              Text(content, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)),
              const Spacer(),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Tutorial.skipAll(context),
                    child: const Text(
                      'Skip onboarding',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  const TextButton(
                    onPressed: null,
                    child: Text(
                      'Next',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
