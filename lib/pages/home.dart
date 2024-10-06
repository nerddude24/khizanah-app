import "package:flutter/material.dart";
import "package:khizanah/pages/themes.dart";

// 'Video' is both video and audio, while 'Audio' is audio-only.
enum DownloadType { Video, Audio }

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String vidLink = "";
  DownloadType? vidType = DownloadType.Video;

  // ! Temp
  void onDownloadBtnClick() {
    if (vidLink.trim() == "") return;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Color(0xff1a1c1e),
        appBar: HomeAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              YtLinkTextField(),
              VerticalSpace(10),
              VidTypeInput(),
              VerticalSpace(50),
              SubmitButton(),
            ],
          ),
        ),
      ),
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
