import 'dart:io';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

enum YouTubeLinkType { video, playlist, unknown }

// 'Video' is both video and audio, while 'Audio' is audio-only.
enum DownloadType { Video, VideoNoAudio, Audio }

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
      uri.pathSegments.contains('embed')) {
    return YouTubeLinkType.video;
  }

  // Check for playlist links
  if (uri.queryParameters.containsKey('list') ||
      uri.pathSegments.contains('playlist')) {
    return YouTubeLinkType.playlist;
  }

  return YouTubeLinkType.unknown;
}

Future<bool> download(
    YoutubeExplode yt, String url, DownloadType vidType, String outputDir,
    {Video? vid}) async {
  try {
    Video video;
    if (vid != null)
      video = vid;
    else
      video = await yt.videos.get(url);

    final streamManifest = await yt.videos.streamsClient.getManifest(video.id);
    StreamInfo streamInfo;

    if (vidType == DownloadType.Video)
      streamInfo = streamManifest.muxed.withHighestBitrate();
    else if (vidType == DownloadType.Audio)
      streamInfo = streamManifest.audioOnly.withHighestBitrate();
    else
      streamInfo = streamManifest.videoOnly.withHighestBitrate();

    // Get the actual stream
    final stream = yt.videos.streamsClient.get(streamInfo);

    // Set the path
    final fileExtension = streamInfo.container.name;
    final fileName = "${video.title}.$fileExtension";
    final fullPath = "$outputDir/$fileName";

    // Open file with the full path.
    final file = File(fullPath);

    if (await file.exists() &&
        await file.length() >= streamInfo.size.totalBytes)
      return true; // video of this quality or higher is already downloaded.

    // Pipe all the content of the stream into the file.
    final fileStream = file.openWrite(mode: FileMode.writeOnly);
    await stream.pipe(fileStream);

    // Close the file.
    await fileStream.flush();
    await fileStream.close();
    return true;
  } catch (err) {
    return false;
  }
}

Future<bool> startDownloadVideo(
    String url, DownloadType vidType, String outputDir) async {
  final YoutubeExplode yt = YoutubeExplode();

  final result = await download(yt, url, vidType, outputDir);

  yt.close();
  return result;
}

Future<bool> startDownloadPlaylist(
    String url, DownloadType vidType, String outputDir,
    {required Function(double progress) updateProgressFn}) async {
  final YoutubeExplode yt = YoutubeExplode();
  updateProgressFn(0);

  try {
    final Playlist playlist = await yt.playlists.get(url);
    final String playlistOutputDir = "$outputDir/${playlist.title}";
    if (!Directory(playlistOutputDir).existsSync())
      Directory(playlistOutputDir).createSync();

    final int? playlistSize = playlist.videoCount;
    int downloaded = 0;
    await for (final video in yt.playlists.getVideos(playlist.id)) {
      await download(yt, url, vidType, playlistOutputDir, vid: video);

      // progress bar
      downloaded++;
      if (playlistSize != null) updateProgressFn(downloaded / playlistSize);
    }
  } catch (err) {
    yt.close();
    return false;
  }

  yt.close();
  return true;
}
