import "dart:io";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:khizanah/pages/themes.dart";
import "package:path_provider/path_provider.dart";
import "package:shared_preferences/shared_preferences.dart";

// 'Video' is both video and audio, while 'Audio' is audio-only.
enum DownloadType { Video, Audio }

enum LogicState { WaitingForInput, Confirmation, Downloading }

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String vidLink = "";
  DownloadType? vidType = DownloadType.Video;
  String? downloadFolder = "";
  bool isSelectingDownloadFolder = false;
  bool isSetup = false;
  LogicState currentState = LogicState.WaitingForInput;

  setup() async {
    isSetup = true;
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final String? prevSelectedDir = await prefs.getString("output_dir");
    final Directory? platformDownloadDir = await getDownloadsDirectory();

    setState(() {
      // set download dir as prev selected dir if possible.
      // if not, set it to the download dir. else, it will be null.
      // when it's null, a check will fail in the download phase and
      // it will abort and alert the user.
      downloadFolder =
          prevSelectedDir != null ? prevSelectedDir : platformDownloadDir?.path;
    });
  }

  startDownload() {
    setState(() {
      currentState = LogicState.Downloading;
    });
    // ! Todo: download the video/videos while checking for existing ones.
  }

  onDownloadBtnClick() {
    if (currentState == LogicState.Confirmation) return startDownload();
    if (currentState == LogicState.Downloading) return;
    if (vidLink.trim() == "") return;
    // ! Todo: check downloadFolder validity.

    // ! Todo: check vidLink validity.
    // ! Todo: ask user for confirmation.

    setState(() {});
  }

  startSelectDownloadFolder() async {
    if (isSelectingDownloadFolder) return;
    isSelectingDownloadFolder = true;

    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final String? SelectedDir = await FilePicker.platform.getDirectoryPath(
      initialDirectory: downloadFolder,
      lockParentWindow: true,
    );

    if (SelectedDir != null) {
      await prefs.setString("output_dir", SelectedDir);

      setState(() {
        downloadFolder = SelectedDir;
      });
    }

    isSelectingDownloadFolder = false;
  }

  @override
  Widget build(BuildContext context) {
    if (!isSetup) setup();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xff1a1c1e),
        appBar: HomeAppBar(),
        floatingActionButton: FolderPickerFloatingButton(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              YtLinkTextField(),
              VerticalSpace(10),
              VidTypeInput(),
              VerticalSpace(50),
              SubmitButton(),
              VerticalSpace(10),
              Text("$downloadFolder", style: SmallTxt),
            ],
          ),
        ),
      ),
    );
  }

  FloatingActionButton FolderPickerFloatingButton() {
    return FloatingActionButton(
      onPressed: startSelectDownloadFolder,
      child: Icon(Icons.folder_sharp),
      backgroundColor: Colors.black45,
      foregroundColor: Colors.white,
      tooltip: "اختر مجلدًا لتخزين المقاطع",
    );
  }

  SizedBox VerticalSpace(double space) {
    return SizedBox(height: space);
  }

  SubmitButton() {
    return OutlinedButton(
      onPressed: onDownloadBtnClick,
      child: Text("تحميل", style: MediumTxt),
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.red[700]),
        surfaceTintColor: WidgetStatePropertyAll(Colors.black),
        padding: WidgetStatePropertyAll(EdgeInsets.fromLTRB(60, 20, 60, 20)),
      ),
    );
  }

  Row VidTypeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("تحميل على شكل: ", style: MediumTxt),
        Text("فيديو", style: SmallTxt),
        VidTypeRadio(DownloadType.Video),
        Text("صوتية", style: SmallTxt),
        VidTypeRadio(DownloadType.Audio),
      ],
    );
  }

  Container YtLinkTextField() {
    return Container(
      width: 700,
      decoration: BoxDecoration(boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.6),
          blurRadius: 24,
          spreadRadius: 0,
        )
      ]),
      child: TextField(
        textDirection: TextDirection.ltr,
        style: SmallTxt,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.black,
          hintText: "رابط المقطع أو السلسلة على اليوتيوب",
          hintTextDirection: TextDirection.rtl,
          border: OutlineInputBorder(
            borderSide: new BorderSide(color: Colors.black12),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        onChanged: (value) => setState(() {
          vidLink = value;
          currentState = LogicState.WaitingForInput;
        }),
      ),
    );
  }

  Radio<DownloadType> VidTypeRadio(DownloadType val) {
    return Radio<DownloadType>(
      value: val,
      groupValue: vidType,
      hoverColor: Colors.red.withAlpha(30),
      focusColor: Colors.red.withAlpha(30),
      fillColor: WidgetStatePropertyAll(Colors.red),
      onChanged: (DownloadType? val) {
        setState(() {
          vidType = val;
          currentState = LogicState.WaitingForInput;
        });
      },
    );
  }

  AppBar HomeAppBar() {
    return AppBar(
      backgroundColor: Color(0xff1a1c1e),
      foregroundColor: Colors.white,
      centerTitle: true,
      toolbarHeight: 100,
      title: const Text(
        "خِزانة",
        style: TextStyle(fontSize: 64, fontWeight: FontWeight.w700),
      ),
    );
  }
}
