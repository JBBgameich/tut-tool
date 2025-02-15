import 'dart:io';

import 'package:app/io.dart';
import 'package:app/project_page.dart';
import 'package:flutter/material.dart';

import 'package:path/path.dart' as p;
import 'package:get/get.dart';
import 'package:getwidget/getwidget.dart';

import 'package:app/logic.dart';

/// Single Group Page for grading
class GroupPage extends StatefulWidget {
  final Project project;
  final int groupIndex;
  const GroupPage(this.project, this.groupIndex, {Key? key}) : super(key: key);

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  TextEditingController controller = TextEditingController();

  to(int relativeIndex, {required bool finished}) async {
    final project = widget.project;
    final groupIndex = widget.groupIndex;
    if (controller.text.isNotEmpty) {
      Future.wait([
        for (final student in project.groups[groupIndex])
          student.commentsFile.writeAsString(controller.text)
      ]).then((value) => null);
    }
    if (finished) {
      project.finishedGroups.add(project.currGroup);
    } else {
      project.finishedGroups.remove(project.currGroup);
    }
    project.currGroup += relativeIndex;
    if (project.currGroup <= -1) {
      Get.to(() => ProjectGroupsPage(project));
    } else if (project.currGroup >= project.groups.length) {
      Get.to(() => SubmitProjectPage(project));
    } else {
      Get.back();
      Get.to(GroupPage(project, project.currGroup));
    }
    project.save();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final groupIndex = widget.groupIndex;
    widget.project.groupComments(groupIndex).readAsString().then(((value) {
      controller.text = value;
    }));
    final submissionSide = DecoratedBox(
        decoration: BoxDecoration(
            border: Border.all(color: Colors.black12, width: 3),
            borderRadius: const BorderRadius.all(Radius.circular(5))),
        child: ListView(children: [
          for (final file in [
            for (final student in widget.project.groups[groupIndex])
              ...student.submissionFiles
          ])
            GFAccordion(
              titleChild: Row(
                children: [
                  Text(p.basename(file.path)),
                  const Expanded(child: SizedBox()),
                  Tooltip(
                    message: "Open commandline",
                    child: ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.transparent),
                          padding: MaterialStateProperty.all(EdgeInsets.zero)),
                      onPressed: () => consoleDir(file),
                      child: const Text(
                        "CMD",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontFamily: "MonoLisa, monospace"),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => openDir(file),
                    icon: const Icon(Icons.folder),
                    tooltip: "Open directory",
                  ),
                  IconButton(
                    onPressed: () => openFile(file),
                    icon: const Icon(Icons.file_open),
                    tooltip: "Open file",
                  ),
                  IconButton(
                    onPressed: () => runFile(file),
                    icon: const Icon(Icons.play_arrow),
                    tooltip: "Run file",
                  )
                ],
              ),
              contentChild: FileShower(file),
            )
        ]));
    final feedbackSide = DecoratedBox(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.black12, width: 3),
          borderRadius: const BorderRadius.all(Radius.circular(5))),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: const InputDecoration(
                  labelText: "Comments",
                  alignLabelWithHint: true,
                  border: OutlineInputBorder()),
              controller: controller,
              maxLines: 20,
              minLines: 5,
              cursorRadius: const Radius.circular(5),
              // readOnly: loading,
            )
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(project.groupTitle(groupIndex)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async => await to(-project.currGroup - 1,
              finished: project.finishedGroups.contains(project.currGroup)),
        ),
        actions: [
          IconButton(
              onPressed: () async => await to(
                  project.groups.length - project.currGroup,
                  finished: true),
              icon: const Icon(Icons.arrow_forward))
        ],
      ),
      body: Stack(children: [
        Padding(
            padding: const EdgeInsets.all(60.0),
            child: MediaQuery.of(context).size.width > 1400
                ? Row(
                    children: [
                      Expanded(child: submissionSide),
                      const SizedBox(width: 30),
                      Expanded(child: feedbackSide)
                    ],
                  )
                : feedbackSide),
        Align(
            alignment: Alignment.centerLeft,
            child: Flex(
              mainAxisAlignment: MainAxisAlignment.center,
              direction: Axis.vertical,
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.lightGreen),
                    child: IconButton(
                      splashRadius: null,
                      icon: const Icon(Icons.arrow_left_outlined),
                      onPressed: () async => await to(-1, finished: true),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black26),
                    child: IconButton(
                      splashRadius: null,
                      icon: const Icon(Icons.arrow_left_outlined),
                      onPressed: () async => to(-1, finished: false),
                    ),
                  ),
                ),
              ],
            )),
        Align(
            alignment: Alignment.centerRight,
            child: Flex(
              mainAxisAlignment: MainAxisAlignment.center,
              direction: Axis.vertical,
              children: [
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.lightGreen),
                    child: IconButton(
                      splashRadius: null,
                      icon: const Icon(Icons.arrow_right_outlined),
                      onPressed: () async => await to(1, finished: true),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.black26),
                    child: IconButton(
                      splashRadius: null,
                      icon: const Icon(Icons.arrow_right_outlined),
                      onPressed: () async => await to(1, finished: false),
                    ),
                  ),
                ),
              ],
            )),
      ]),
    );
  }
}
