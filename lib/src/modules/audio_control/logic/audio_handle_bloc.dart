import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:zanmelodic/src/config/themes/my_colors.dart';
import 'package:zanmelodic/src/models/audio_model.dart';
import 'package:zanmelodic/src/models/enums/button_state.dart';
import 'package:zanmelodic/src/models/enums/repeat_state.dart';
import 'package:zanmelodic/src/models/presf.dart';
import 'package:zanmelodic/src/modules/audio_control/logic/progress_bar_bloc.dart';
import 'package:zanmelodic/src/modules/dashboard/pages/dashboard_page.dart';

part 'audio_handle_state.dart';

class AudioHandleBloc extends Cubit<AudioHandleState> {
  static final AudioHandleState _initialValue = AudioHandleState(
      currentSong: const MediaItem(title: 'N/A', id: '-1'),
      progress: const ProgressBarState(
        current: Duration.zero,
        buffered: Duration.zero,
        total: Duration.zero,
      ),
      playlist: const [],
      audioHandler: GetIt.I<AudioHandler>());

  AudioHandleBloc() : super(_initialValue) {
    init();
  }

  MediaItem convertSongOnlineToModel(XAudio audio) {
    final result = MediaItem(
      id: audio.id.toString(),
      album: 'Firebase',
      title: audio.name,
      artist: audio.author,
      extras: {
        'url': audio.link,
        'isFirebase': true,
        'image': audio.image,
        'lyric': audio.lyric
      },
    );
    return result;
  }

  void dispose() {
    state.audioHandler.customAction('dispose');
  }

  void init() {
    _listenToChangesInPlaylist();
    _listenToPlaybackState();
    _listenToCurrentPosition();
    _listenToBufferedPosition();
    _listenToTotalDuration();
    _listenToChangesInSong();
  }

  Future<void> getImagePalette(ImageProvider imageProvider) async {
    final PaletteGenerator paletteGenerator =
        await PaletteGenerator.fromImageProvider(imageProvider);
    emit(state.copyWith(mainColor: paletteGenerator.dominantColor!.color));
  }

  Future<void> loadPlaylist(List<MediaItem> items) async {
    final mediaItems = (items).map((song) => song).toList();
    state.audioHandler.addQueueItems(mediaItems);
    emit(state.copyWith(
      playlist: mediaItems,
    ));
  }

  void next() => state.audioHandler.skipToNext();

  void pause() => state.audioHandler.pause();

  void play() => state.audioHandler.play();

  Future<void> playItem({
    List<SongModel>? items,
    int? index,
    List<XAudio>? audios,
    List<MediaItem>? medias,
  }) async {
    List<MediaItem> mediaItems = medias ?? [];
    if (items != null) {
      mediaItems = (items).map((e) => converSongToModel(e)).toList();
    }
    if (audios != null) {
      mediaItems = (audios).map((e) => convertSongOnlineToModel(e)).toList();
    }

    bool isEqual = listEquals(mediaItems, state.playlist);
    if (isEqual == false) {
      loadPlaylist(mediaItems);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    state.audioHandler.skipToQueueItem(index ?? 0);

    play();

    emit(state.copyWith(
        isShowBottomBar: true,
        currentSong: state.audioHandler.mediaItem.value));
  }

  void previous() => state.audioHandler.skipToPrevious();

  void remove() {
    final lastIndex = state.audioHandler.queue.value.length - 1;
    if (lastIndex < 0) return;
    state.audioHandler.removeQueueItemAt(lastIndex);
  }

  void repeat() {
    final next = (state.repeatButton.index + 1) % RepeatState.values.length;

    emit(state.copyWith(repeatButton: RepeatState.values[next]));
    final repeatMode = state.repeatButton;
    switch (repeatMode) {
      case RepeatState.off:
        state.audioHandler.setRepeatMode(AudioServiceRepeatMode.none);
        break;
      case RepeatState.repeatSong:
        state.audioHandler.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case RepeatState.repeatPlaylist:
        state.audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;
    }
  }

  void seek(Duration position) => state.audioHandler.seek(position);

  void shuffle() {
    final enable = !state.isShuffleModeEnabled;
    emit(state.copyWith(isShuffleModeEnabled: enable));
    if (enable) {
      state.audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
    } else {
      state.audioHandler.setShuffleMode(AudioServiceShuffleMode.none);
    }
  }

  void sort() {
    final enable = !state.isSortModeEnabled;
    emit(state.copyWith(isSortModeEnabled: enable));
    if (enable) {
      (state.audioHandler.queue.value)
          .sort((a, b) => (a.title).compareTo((b.title)));
    } else {
      (state.audioHandler.queue.value)
          .sort((a, b) => (b.title).compareTo((a.title)));
    }
  }

  void stop() => state.audioHandler.stop();

  void _listenToBufferedPosition() {
    state.audioHandler.playbackState.listen((playbackState) {
      emit(state.copyWith(
          progress: ProgressBarState(
        current: state.progress.current,
        buffered: playbackState.bufferedPosition,
        total: state.progress.total,
      )));
    });
  }

  void _listenToChangesInPlaylist() {
    state.audioHandler.queue.listen((playlist) {
      if (playlist.isEmpty) {
        emit(state.copyWith(
            playlist: [],
            currentSong: const MediaItem(title: 'N/A', id: '-1')));
      } else {
        emit(state.copyWith(playlist: playlist));
      }

      _updateSkipButtons();
    });
  }

  void _listenToChangesInSong() {
    state.audioHandler.mediaItem.listen((mediaItem) {
      emit(state.copyWith(currentSong: mediaItem));
      if (mediaItem != null) {
        Prefs.saveMedia(mediaItem.title);
        getMainColors(mediaItem);
      }
      _updateSkipButtons();
    });
  }

  Future<void> getMainColors(MediaItem mediaItem) async {
    if (mediaItem.extras!['image'] != null) {
      getImagePalette(
        NetworkImage(mediaItem.extras!['image']),
      );
    }
    if (mediaItem.extras!['uri_image'] != null) {}
  }

  void _listenToCurrentPosition() {
    AudioService.position.listen((position) {
      emit(state.copyWith(
          progress: ProgressBarState(
        current: position,
        buffered: state.progress.buffered,
        total: state.progress.total,
      )));
    });
  }

  void _listenToPlaybackState() {
    state.audioHandler.playbackState.listen((playbackState) {
      final isPlaying = playbackState.playing;
      final processingState = playbackState.processingState;
      if (processingState == AudioProcessingState.loading ||
          processingState == AudioProcessingState.buffering) {
        emit(state.copyWith(playButton: ButtonState.loading));
      } else if (!isPlaying) {
        emit(state.copyWith(playButton: ButtonState.paused));
      } else if (processingState != AudioProcessingState.completed) {
        emit(state.copyWith(playButton: ButtonState.playing));
      } else {
        state.audioHandler.seek(Duration.zero);
        state.audioHandler.pause();
      }
    });
  }

  void _listenToTotalDuration() {
    state.audioHandler.mediaItem.listen((mediaItem) {
      emit(state.copyWith(
          progress: ProgressBarState(
        current: state.progress.current,
        buffered: state.progress.buffered,
        total: mediaItem?.duration ?? Duration.zero,
      )));
    });
  }

  void _updateSkipButtons() {
    final mediaItem = state.audioHandler.mediaItem.value;
    final playlist = state.audioHandler.queue.value;
    if (playlist.length < 2 || mediaItem == null) {
      emit(state.copyWith(isFirstSong: true, isLastSong: true));
    } else {
      emit(state.copyWith(
          isFirstSong: playlist.first == mediaItem,
          isLastSong: playlist.last == mediaItem));
    }
  }
}
