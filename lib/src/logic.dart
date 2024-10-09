import 'dart:io';

import 'package:khizanah/main.dart';

enum YouTubeLinkType { video, playlist, unknown }

// 'Video' is both video and audio, while 'Audio' is audio-only.
enum DownloadType { Video, VideoHD, Audio }

enum ExitCode {
  success,
  link_invalid,
  ffmpeg_not_installed,
  ytdlp_err,
  invalid_vid_type
}

final slash = Platform.isWindows ? "\\" : "/";

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
    'cmd',
    ["/c", pathToYTDLP, ...args],
    mode: ProcessStartMode.detachedWithStdio,
  );

  // wait for the process to finish, other futures can be used.
  await process.stderr.length;

  // run another process but this time in normal mode to see if there were any errors.
  // this might seem stupid (running yt-dlp twice), but this is the only solution i found
  // that both 1. shows the cmd windows and 2. gets you the exit code.
  // also, if the files are already downloaded, yt-dlp will skip them so this shouldn't take very long.
  final verificationProcess =
      await Process.run(pathToYTDLP, [...args], runInShell: true);

  final isErred = verificationProcess.exitCode != 0;
  return isErred ? ExitCode.ytdlp_err : ExitCode.success;
}

Future<ExitCode> _download(
    String url, DownloadType vidType, String outputDir) async {
  if (vidType == DownloadType.VideoHD && !await isFFmpegInstalled())
    return ExitCode.ffmpeg_not_installed;

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
        // args = ["-F", url];
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

    if (Platform.isWindows) return await _runYTDLPcmd(args);

    // else if unix system:
    final ProcessResult result = await Process.run(pathToYTDLP, args,
        runInShell: true, workingDirectory: outputDir);
    if (result.exitCode != 0) return ExitCode.ytdlp_err;
  } catch (err) {
    return ExitCode.ytdlp_err;
  }

  return ExitCode.success;
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
