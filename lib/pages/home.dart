import "dart:io";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:khizanah/pages/logic.dart";
import "package:path_provider/path_provider.dart";
import "package:shared_preferences/shared_preferences.dart";
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import "package:khizanah/pages/themes.dart";

enum AppState { WaitingForInput, Downloading }

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String? outputDir = "";
  String vidLink = "";
  DownloadType vidType = DownloadType.Video;
  bool isSelectingDownloadFolder = false;
  bool isSetup = false;
  AppState currentState = AppState.WaitingForInput;

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
      outputDir =
          prevSelectedDir != null ? prevSelectedDir : platformDownloadDir?.path;
    });
  }

  startDownload() async {
    setState(() {
      currentState = AppState.Downloading;
    });

    final linkType = analyzeYouTubeLink(vidLink);
    bool isSuccessful;

    if (linkType == YouTubeLinkType.unknown)
      throw ErrorDescription("invalid link");
    else if (linkType == YouTubeLinkType.video)
      isSuccessful = await downloadVideo(vidLink, vidType, outputDir!);
    else
      isSuccessful = await downloadPlaylist(vidLink, vidType, outputDir!);

    if (!isSuccessful)
      showAppDialog(
          "حدث خطأ أثناء التحميل", "رجاءًا تأكد من رابط المقطع ومن الإنترنت.");
    else
      showAppDialog("الحمد لله", "تم تحميل المقطع بنجاح!");

    setState(() {
      currentState = AppState.WaitingForInput;
    });
  }

  onDownloadBtnClick() async {
    if (currentState == AppState.Downloading) return;
    if (vidLink.trim() == "") return;

    // check if download folder is valid
    try {
      if (!Directory(outputDir!).existsSync()) return;
    } catch (err) {
      setState(() {
        outputDir = null;
      });
      showAppDialog(
          "حدث خطأ في التطبيق", "!رجاءًا اختر مجلدًا آخرًا لتحميل الملفات");
    }

    showAppDialog("هل أنت متأكد", "", buttons: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text("إلغاء", style: SmallTxt),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          startDownload();
        },
        child: Text("تأكيد", style: SmallTxt.copyWith(color: Colors.green)),
        style:
            TextButton.styleFrom(padding: EdgeInsets.fromLTRB(20, 15, 20, 15)),
      )
    ]);
  }

  void showAppDialog(String title, String desc, {List<Widget>? buttons}) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(
                title,
                style: SmallTxt.copyWith(fontWeight: FontWeight.w600),
              ),
              content: Text(
                desc,
                style: SmallTxt,
              ),
              actions: buttons != null
                  ? buttons
                  : [
                      TextButton(
                        child: Text(
                          "حسنا",
                          style: SmallTxt.copyWith(color: Colors.red),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      )
                    ],
              elevation: 24,
            ));
  }

  startSelectDownloadFolder() async {
    if (isSelectingDownloadFolder) return;
    isSelectingDownloadFolder = true;

    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final String? SelectedDir = await FilePicker.platform.getDirectoryPath(
      initialDirectory: outputDir,
      lockParentWindow: true,
    );

    if (SelectedDir != null) {
      await prefs.setString("output_dir", SelectedDir);

      setState(() {
        outputDir = SelectedDir;
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
              Text("$outputDir :إلى",
                  textDirection: TextDirection.ltr, style: SmallTxt),
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white60)),
    );
  }

  ElevatedButton SubmitButton() {
    final isEnabled = currentState == AppState.WaitingForInput;
    return ElevatedButton(
      onPressed: isEnabled ? onDownloadBtnClick : null,
      child: Text(isEnabled ? "تحميل" : "...", style: MediumTxt),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[700],
        surfaceTintColor: Colors.black,
        padding: EdgeInsets.fromLTRB(60, 20, 60, 20),
        elevation: 24,
      ),
    );
  }

  Row VidTypeInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("تحميل على هيئة: ", style: SmallTxt),
        HorizontalSpace(20),
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
          currentState = AppState.WaitingForInput;
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
          vidType = val!;
          currentState = AppState.WaitingForInput;
        });
      },
    );
  }

  AppBar HomeAppBar() {
    return AppBar(
      backgroundColor: Color(0xff1a1c1e),
      foregroundColor: Colors.white,
      centerTitle: true,
      toolbarHeight: 80,
      title: const Text(
        "خِزانة",
        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700),
      ),
    );
  }
}
