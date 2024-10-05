import "package:flutter/material.dart";

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
  String test = "";
  void onDownloadBtnClick() {
    setState(() {
      test = "Link: $vidLink . Type: $vidType";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("خزانة"),
              TextField(
                onChanged: (value) => setState(() {
                  vidLink = value;
                }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("تحميل على شكل: "),
                  const Text("مقطع"),
                  Radio<DownloadType>(
                    value: DownloadType.Video,
                    groupValue: vidType,
                    onChanged: (DownloadType? value) {
                      setState(() {
                        vidType = value;
                      });
                    },
                  ),
                  const Text("صوتية"),
                  Radio<DownloadType>(
                    value: DownloadType.Audio,
                    groupValue: vidType,
                    onChanged: (DownloadType? value) {
                      setState(() {
                        vidType = value;
                      });
                    },
                  ),
                ],
              ),
              TextButton(
                  onPressed: onDownloadBtnClick, child: const Text("تحميل")),

              // ! Temp
              Text(test)
            ],
          ),
        ),
      ),
    );
  }
}
