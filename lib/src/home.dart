import "dart:io";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:khizanah/src/logic.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:path_provider/path_provider.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:khizanah/src/theme.dart";
import "package:url_launcher/url_launcher.dart";
import "package:url_launcher/url_launcher_string.dart";

enum AppState { Setup, WaitingForInput, SelectingDownloadFolder, Downloading }

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // * App state variables
  String appVersion = "";
  String? outputDir = "";
  String vidLink = "";
  DownloadType vidType = DownloadType.Video;
  AppState currentState = AppState.Setup;
  String pathToYTDLP = "";
  bool isSubmitBtnHovered = false;

  @override
  Widget build(BuildContext context) {
    if (currentState == AppState.Setup) setup();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xff1a1c1e),
        appBar: HomeAppBar(),
        floatingActionButton: FolderPickerFloatingButton(),
        body: Stack(children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                YtLinkTextField(),
                VerticalSpace(10),
                VidTypeInput(),
                VerticalSpace(50),
                currentState == AppState.Downloading
                    ? ProgressBar()
                    : SubmitButton(),
                VerticalSpace(30),
                Text("$outputDir :إلى",
                    textDirection: TextDirection.ltr,
                    style: XSmallTxt.copyWith(fontWeight: FontWeight.w200)),
              ],
            ),
          ),
          // app version text
          Positioned(
            right: 10,
            bottom: 10,
            child: TextButton(
              child: Text(
                appVersion,
                style: XSmallTxt.copyWith(color: Colors.white24),
              ),
              onPressed: () => launchUrl(
                  Uri.https("github.com", "nerddude24/khizanah-app/releases")),
            ),
          )
        ]),
      ),
    );
  }

  bool canInput() {
    return currentState == AppState.WaitingForInput;
  }

  void setup() async {
    // Download folder setup
    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final String? prevSelectedDir = await prefs.getString("output_dir");
    final Directory? platformDownloadDir = await getDownloadsDirectory();

    // App version display setup
    final packageInfo = await PackageInfo.fromPlatform();

    setState(() {
      // set download dir as prev selected dir if possible.
      // if not, set it to the platform download dir. else, it will be null.
      // when it's null, a check will fail in the download phase and
      // it will abort and alert the user.
      outputDir =
          prevSelectedDir != null ? prevSelectedDir : platformDownloadDir?.path;

      appVersion = packageInfo.version;

      currentState = AppState.WaitingForInput;
    });
  }

  void startDownload() async {
    setState(() => currentState = AppState.Downloading);

    // check if link is valid and if it's audio or video.
    final linkType = analyzeYouTubeLink(vidLink);
    // used for later displays.
    ExitCode downloadExitCode;

    if (linkType == YouTubeLinkType.unknown)
      downloadExitCode = ExitCode.link_invalid;
    else if (linkType == YouTubeLinkType.video) {
      showAppDialog("رجاءًا انتظر", "بدأ تحميل المقطع...");
      downloadExitCode = await startDownloadVideo(vidLink, vidType, outputDir!);
    } else {
      showAppDialog("رجاءًا انتظر", "بدأ تحميل قائمة التشغيل...");
      downloadExitCode =
          await startDownloadPlaylist(vidLink, vidType, outputDir!);
    }

    if (downloadExitCode != ExitCode.success) {
      if (Navigator.of(context).canPop())
        Navigator.of(context).pop(); // pop other dialogs
      String errMsg;
      List<Widget> buttons = [];

      switch (downloadExitCode) {
        case ExitCode.ffmpeg_not_installed:
          errMsg =
              "رجاءا قم بتحميل ffmpeg و ffprobe لإمكانية تحميل المقاطع العالية الجودة!";
          buttons = [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("تمام", style: SmallTxt.copyWith(color: Colors.red)),
              style: TextButton.styleFrom(padding: EdgeInsets.all(20)),
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.https("github.com",
                  "nerddude24/khizanah-app/blob/main/INSTALL.md")),
              child: Text("كيفية التثبيت",
                  style: SmallTxt.copyWith(color: Colors.white)),
              style: TextButton.styleFrom(padding: EdgeInsets.all(20)),
            ),
          ];
          break;
        case ExitCode.ytdlp_not_installed:
          errMsg =
              "لم يتم العثور على برنامج yt-dlp!\n رجاءًا قم بإعادة تثبيت تطبيق خزانة، أو قم بتثبيت برنامج yt-dlp بنفسك.";
          break;
        case ExitCode.invalid_vid_type:
          errMsg = "حدث خلل غير متوقع، رجاءًا قم بإعادة فتح تطبيق خزانة.";
          break;
        case ExitCode.link_invalid:
          errMsg = "رجاءًا تأكد من رابط المقطع!";
          break;
        default:
          errMsg = "رجاءًا تأكد من رابط المقطع ومن الإنترنت!";
          break;
      }

      showAppDialog("حدث خطأ أثناء التحميل", errMsg, buttons: buttons);
    } else
      showAppDialog("الحمد لله", "تم تحميل المقاطع بنجاح!", buttons: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("تمام", style: SmallTxt.copyWith(color: Colors.green)),
          style: TextButton.styleFrom(padding: EdgeInsets.all(20)),
        ),
        TextButton(
          onPressed: () async {
            Navigator.of(context).pop();
            await launchUrlString(outputDir!);
          },
          child: Text("إظهار الخزانة", style: SmallTxt),
          style: TextButton.styleFrom(padding: EdgeInsets.all(15)),
        )
      ]);

    setState(() => currentState = AppState.WaitingForInput);
  }

  void onDownloadBtnClick() async {
    if (!canInput()) return;
    // check if link is empty.
    if (vidLink.trim() == "") return;

    // check if download folder exists
    if (outputDir == null || !Directory(outputDir!).existsSync()) {
      showAppDialog(
          "حدث خطأ في التطبيق", "!رجاءًا اختر مجلدًا صحيحًا لتحميل الملفات");
      return;
    }

    // confirmation dialog.
    showAppDialog("هل أنت متأكد", " $outputDir :سيتم التحميل إلى", buttons: [
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
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          desc,
          textDirection: TextDirection.rtl,
          style: SmallTxt,
        ),
        actions: buttons != null
            ? buttons
            : [
                TextButton(
                  child: Text(
                    "تمام",
                    style: SmallTxt.copyWith(color: Colors.red),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
        elevation: 24,
      ),
    );
  }

  void startSelectDownloadFolder() async {
    setState(() => currentState = AppState.SelectingDownloadFolder);

    final SharedPreferencesAsync prefs = SharedPreferencesAsync();
    final String? SelectedDir = await FilePicker.platform.getDirectoryPath(
      initialDirectory: outputDir,
      lockParentWindow: true,
    );

    // save new dir only if it's valid.
    if (SelectedDir != null) {
      await prefs.setString("output_dir", SelectedDir);

      setState(() {
        outputDir = SelectedDir;
      });
    }

    setState(() => currentState = AppState.WaitingForInput);
  }

  FloatingActionButton FolderPickerFloatingButton() {
    return FloatingActionButton(
      onPressed: canInput() ? startSelectDownloadFolder : null,
      child: Icon(Icons.folder_sharp),
      backgroundColor: Colors.black45,
      foregroundColor: Colors.white,
      tooltip: "اختر مجلدًا لتخزين المقاطع",
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white60)),
    );
  }

  MouseRegion SubmitButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => isSubmitBtnHovered = true),
      onExit: (_) => setState(() => isSubmitBtnHovered = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(32)),
            boxShadow: isSubmitBtnHovered
                ? [BoxShadow(color: Colors.red.shade700, blurRadius: 20)]
                : [
                    BoxShadow(
                      color: Colors.red.shade700,
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ]),
        child: ElevatedButton(
          onPressed: canInput() ? onDownloadBtnClick : null,
          child: Text(canInput() ? "تحميل" : "...", style: MediumTxt),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[700],
            surfaceTintColor: Colors.black,
            padding: EdgeInsets.fromLTRB(60, 20, 60, 20),
            elevation: 24,
          ),
        ),
      ),
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
          hintText: "رابط المقطع أو قائمة التشغيل على اليوتيوب",
          hintTextDirection: TextDirection.rtl,
          border: OutlineInputBorder(
            borderSide: new BorderSide(color: Colors.black12),
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
        enabled: canInput(),
        onChanged: (val) => setState(() => vidLink = val),
      ),
    );
  }

  Row VidTypeInput() {
    final getTxtColor =
        (vtype) => vtype == vidType ? Colors.white : Colors.white54;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("تحميل على هيئة: ", style: SmallTxt),
        HorizontalSpace(20),
        Text("فيديو",
            style: SmallTxt.copyWith(color: getTxtColor(DownloadType.Video))),
        VidTypeRadio(DownloadType.Video),
        Text("فيديو",
            style: SmallTxt.copyWith(color: getTxtColor(DownloadType.VideoHD))),
        HorizontalSpace(5),
        Icon(
          Icons.hd_outlined,
          color: getTxtColor(DownloadType.VideoHD),
        ),
        VidTypeRadio(DownloadType.VideoHD),
        Text("صوتية",
            style: SmallTxt.copyWith(color: getTxtColor(DownloadType.Audio))),
        VidTypeRadio(DownloadType.Audio),
      ],
    );
  }

  Radio<DownloadType> VidTypeRadio(DownloadType val) {
    return Radio<DownloadType>(
      value: val,
      groupValue: vidType,
      hoverColor: Colors.red.withAlpha(30),
      focusColor: Colors.red.withAlpha(30),
      fillColor: WidgetStatePropertyAll(Colors.red),
      onChanged: canInput()
          ? (DownloadType? val) => setState(() => vidType = val!)
          : null,
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

  Row ProgressBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: Platform.isWindows
              ? [
                  Text("جاري التحميل", style: SmallTxt),
                  Text("يمكنكم التتبع في النافذة التي ظهرت",
                      style: SmallTxt.copyWith(fontSize: 14))
                ]
              : [Text("جاري التحميل", style: SmallTxt)],
        ),
        HorizontalSpace(50),
        Container(
          width: 400,
          child: LinearProgressIndicator(
            value: null,
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
