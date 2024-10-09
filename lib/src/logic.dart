import 'dart:io';

import 'package:khizanah/main.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

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
    uri = Uri.parse(url);
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
  // this shows a cmd windows with the progress.
  final process = await Process.start(
    'cmd',
    ['/c', 'start', 'cmd', '/k', pathToYTDLP, ...args],
    mode: ProcessStartMode.detached,
  );

  // wait for the process to finish
  return await process.exitCode == 0 ? ExitCode.success : ExitCode.ytdlp_err;
}

Future<ExitCode> _download(
    String url, DownloadType vidType, String outputDir) async {
  if (vidType == DownloadType.VideoHD && !await isFFmpegInstalled())
    return ExitCode.ffmpeg_not_installed;

  try {
    List<String> args;

    switch (vidType) {
      case DownloadType.Audio:
        final fullPath = "$outputDir$slash%(title)s صوتية.%(ext)s";
        // ! Temp args = ['-f', '"ba"', '-o', '"$fullPath"', url];
        args = ["-F", url];
        break;
      case DownloadType.Video:
        final fullPath = "$outputDir$slash%(title)s.%(ext)s";
        args = ['-f "b"' '-o "$fullPath"', url];
        break;
      case DownloadType.VideoHD:
        final fullPath = "$outputDir$slash%(title)s جودة عالية.%(ext)s";
        args = ['-f "bv+ba"', '-o "$fullPath"', url];
        break;
      default:
        // this should be impossible to reach.
        return ExitCode.invalid_vid_type;
    }

    // if (Platform.isWindows) return await _runYTDLPcmd(args);

    // else if unix system:
    final ProcessResult result =
        await Process.run(pathToYTDLP, args, runInShell: true);
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
