import 'dart:io';

import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../chat_bubble.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final RecorderController recorderController;
  PlayerController currentPlaying = PlayerController();

  List<String?> path = [];
  String? musicFile;
  bool isRecording = false;
  var isLoading = true;
  late Directory appDirectory;

  @override
  void initState() {
    super.initState();
    _getDir();
    _initialiseControllers();
  }

  void _getDir() async {
    appDirectory = await getApplicationDocumentsDirectory();
    path = await getFilePathsFromCacheDirectory();
    isLoading = false;
    setState(() {});
  }

  void _initialiseControllers() {
    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 44100;
  }

  @override
  void dispose() {
    recorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        onPressed: _startOrStopRecording,
        child: Icon(isRecording ? Icons.stop : Icons.mic),
      ),
      backgroundColor: const Color(0xFF252331),
      appBar: AppBar(
          backgroundColor: const Color(0xFF252331),
          elevation: 1,
          centerTitle: true,
          shadowColor: Colors.grey,
          title: const Text(
            'Recorder',
            style: TextStyle(color: Colors.white),
          )),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: path.length,
                      itemBuilder: (_, index) {
                        PlayerController controller = PlayerController();
                        controller.onPlayerStateChanged.listen((event) {
                          if (event.isPlaying && controller != currentPlaying) {
                            print('Playing');
                            currentPlaying.seekTo(0);
                            currentPlaying.pausePlayer();

                            currentPlaying =controller;
                          }
                        });
                        return WaveBubble(
                          path: path[index],
                          isSender: true,
                          appDirectory: appDirectory,
                          controller: controller,
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: isRecording
                              ? AudioWaveforms(
                                  enableGesture: true,
                                  size: Size(
                                      MediaQuery.of(context).size.width / 2,
                                      50),
                                  recorderController: recorderController,
                                  waveStyle: const WaveStyle(
                                    waveColor: Colors.white,
                                    extendWaveform: true,
                                    showMiddleLine: false,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12.0),
                                    color: const Color(0xFF1E1B26),
                                  ),
                                  padding: const EdgeInsets.only(left: 18),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                )
                              : Container(
                                  width:
                                      MediaQuery.of(context).size.width / 1.7,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E1B26),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  padding: const EdgeInsets.only(left: 18),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  child: const Center(
                                    child: Text(
                                      'Press and say something!',
                                      style: TextStyle(color: Colors.white54),
                                    ),
                                  )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _startOrStopRecording() async {
    try {
      if (isRecording) {
        recorderController.reset();
        path.add(await recorderController.stop(false));
      } else {
        await recorderController.record();
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isRecording = !isRecording;
      });
    }
  }

  Future<List<String>> getFilePathsFromCacheDirectory() async {
    Directory cacheDir = await getTemporaryDirectory();
    List<FileSystemEntity> files =
        cacheDir.listSync(recursive: false, followLinks: false);

    List<String> filePaths = [];
    for (var file in files) {
      if (file is File) {
        filePaths.add(file.path);
      }
    }

    return filePaths;
  }
}
