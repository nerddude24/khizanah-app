import 'dart:io';

enum YouTubeLinkType { video, playlist, unknown }

// 'Video' is both video and audio, while 'Audio' is audio-only.
enum DownloadType { Video, VideoHD, Audio }

enum ExitCode {
  success,
  link_invalid,
  ffmpeg_not_installed,
  ytdlp_err,
  invalid_vid_type,
  ytdlp_not_installed
}

final slash = Platform.isWindows ? "\\" : "/";

String? pathToYTDLP = null;

Future<bool> isFFmpegInstalled() async {
  try {
    // Run the ffmpeg command with the -version flag to check if it's installed
    ProcessResult result = await Process.run('ffmpeg', ['-version']);

    // Check the exit code; a 0 exit code means the command was successful
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

Future<bool> isYTDLPInstalled() async {
  try {
    // Run the ffmpeg command with the -version flag to check if it's installed
    ProcessResult result = await Process.run('yt-dlp', ['--version']);

    // Check the exit code; a 0 exit code means the command was successful
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

Future<String?> getYTDLPPath() async {
  // yt-dlp is grouped with windows version of the app only (for now).
  if (await isYTDLPInstalled())
    return "yt-dlp";
  else if (Platform.isWindows &&
      await File("${Platform.resolvedExecutable}\\deps\\yt-dlp.exe").exists())
    return "${Platform.resolvedExecutable}\\deps\\yt-dlp.exe";
  else
    return null;
}

YouTubeLinkType analyzeYouTubeLink(String url) {
  Uri uri;
  try {
    uri = Uri.parse(url.trim());
  } catch (e) {
    return YouTubeLinkType.unknown;
  }

  // Check for video links
  if (uri.host == 'youtu.be' ||
      uri.pathSegments.contains('watch') ||
      uri.pathSegments.contains('embed') ||
      uri.pathSegments.contains('shorts')) {
    return YouTubeLinkType.video;
  }

  // Check for playlist links
  if (uri.queryParameters.containsKey('list') ||
      uri.pathSegments.contains('playlist')) {
    return YouTubeLinkType.playlist;
  }

  return YouTubeLinkType.unknown;
}

Future<ExitCode> _runYTDLPcmd(List<String> args) async {
  // this shows a cmd window with the progress.
  final process = await Process.start(
    "cmd",
    ["/c", pathToYTDLP!, ...args],
    mode: ProcessStartMode.detachedWithStdio,
  );

  // wait for the process to finish, other futures can be used.
  await process.stderr.length;

  return ExitCode.success;
}

Future<ExitCode> _runYTDLPlinux(List<String> args) async {
  final process = await Process.run(pathToYTDLP!, [...args], runInShell: true);

  final isErred = process.exitCode != 0;
  return isErred ? ExitCode.ytdlp_err : ExitCode.success;
}

Future<ExitCode> _download(
    String url, DownloadType vidType, String outputDir) async {
  try {
    List<String> args;

    switch (vidType) {
      case DownloadType.Audio:
        args = [
          "-f",
          "139/ba",
          "-o",
          "$outputDir$slash%(title)s صوتية.%(ext)s",
          url
        ];
        break;
      case DownloadType.Video:
        args = ["-f", "b", "-o", "$outputDir$slash%(title)s.%(ext)s", url];
        break;
      case DownloadType.VideoHD:
        args = [
          "-f",
          "bv+ba",
          "-o",
          "$outputDir$slash%(title)s جودة عالية.%(ext)s",
          url
        ];
        break;
      default:
        // this should be impossible to reach.
        return ExitCode.invalid_vid_type;
    }

    // first check yt-dlp executable path if it wasn't checked already.
    pathToYTDLP = pathToYTDLP == null ? await getYTDLPPath() : pathToYTDLP;
    // if yt-dlp executable still wasn't found, err out.
    if (pathToYTDLP == null) return ExitCode.ytdlp_not_installed;

    // check ffmpeg if video is hd
    if (vidType == DownloadType.VideoHD && !await isFFmpegInstalled())
      return ExitCode.ffmpeg_not_installed;

    if (Platform.isWindows)
      return await _runYTDLPcmd(args);
    else
      return await _runYTDLPlinux(args);
  } catch (err) {
    return ExitCode.ytdlp_err;
  }
}

Future<ExitCode> startDownloadVideo(
    String url, DownloadType vidType, String outputDir) async {
  return _download(url, vidType, outputDir);
}

Future<ExitCode> startDownloadPlaylist(
    String url, DownloadType vidType, String outputDir) async {
  // append the playlist's title to the outputDir.
  return _download(url, vidType, "$outputDir$slash%(playlist)s");
}
