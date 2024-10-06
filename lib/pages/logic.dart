import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum YouTubeLinkType { video, playlist, unknown }

// 'Video' is both video and audio, while 'Audio' is audio-only.
enum DownloadType { Video, Audio }

YouTubeLinkType analyzeYouTubeLink(String url) {
  Uri uri;
  try {
    uri = Uri.parse(url);
  } catch (e) {
    return YouTubeLinkType.unknown;
  }

  // Check for playlist links
  if (uri.queryParameters.containsKey('list') ||
      uri.pathSegments.contains('playlist')) {
    return YouTubeLinkType.playlist;
  }

  // Check for video links
  if (uri.host == 'youtu.be' ||
      uri.pathSegments.contains('watch') ||
      uri.pathSegments.contains('v') ||
      uri.pathSegments.contains('embed')) {
    return YouTubeLinkType.video;
  }

  return YouTubeLinkType.unknown;
}

// returns a boolean based on success.
Future<bool> downloadVideo(
    String url, DownloadType vidType, String outputDir) async {
  final YoutubeExplode yt = YoutubeExplode();

  try {
    final video = await yt.videos.get(url);
    final streamManifest = await yt.videos.streamsClient.getManifest(video.id);
    StreamInfo streamInfo;

    if (vidType == DownloadType.Video)
      streamInfo = streamManifest.muxed.withHighestBitrate();
    else
      streamInfo = streamManifest.audioOnly.withHighestBitrate();

    // Get the actual stream
    final stream = yt.videos.streamsClient.get(streamInfo);

    // Set the path
    final fileName = "${video.title}.${streamInfo.container.name}";

    // Open a file for writing.
    final file = File("$outputDir/$fileName");
    final fileStream = file.openWrite();

    // Pipe all the content of the stream into the file.
    await stream.pipe(fileStream); // Close the file.
    await fileStream.flush();
    await fileStream.close();
  } catch (_) {
    // Todo: log errors

    yt.close();
    return false;
  }

  yt.close();
  return true;
}

bool downloadPlaylist(String url, DownloadType vidType, String outputDir) {
  return true;
}
