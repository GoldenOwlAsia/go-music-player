import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:zanmelodic/src/config/routes/coordinator.dart';
import 'package:zanmelodic/src/models/handle.dart';
import 'package:zanmelodic/src/modules/audio_control/logic/audio_handle_bloc.dart';
import 'package:zanmelodic/src/modules/dashboard/pages/dashboard_page.dart';
import 'package:zanmelodic/src/modules/playlist/playlist/logic/playlist_bloc.dart';
import 'package:zanmelodic/src/modules/playlist/router/playlist_router.dart';
import 'package:zanmelodic/src/modules/upper_control/logic/upper_control_bloc.dart';
import 'package:zanmelodic/src/repositories/domain.dart';
import 'package:zanmelodic/src/widgets/loading/bot_toast.dart';
import 'package:zanmelodic/src/widgets/loading/loading.dart';

part 'playlist_detail_state.dart';

class PlaylistDetailBloc extends Cubit<PlaylistDetailState> {
  final Domain _domain = Domain();

  PlaylistDetailBloc()
      : super(PlaylistDetailState(
            mediaItems: const [],
            items: XHandle.loading(),
            playlist: PlaylistModel({})));

  Future<void> fetchListOfSongsFromPlaylist(BuildContext context,
      {required PlaylistModel playlist, required List<SongModel> songs}) async {
    await Future.delayed(const Duration(seconds: 2));
    final _value =
        await _domain.playlist.getListOfSongFromPlaylist(playlist.id);
    if (_value.isSuccess) {
      List<SongModel> newList = [];
      for (SongModel item in (songs)) {
        for (SongModel item1 in (_value.data ?? [])) {
          if (item.title == item1.title) {
            newList.add(item);
          }
        }
      }
      var a = (newList).map((e) => converSongToModel(e)).toList();
      context.read<AudioHandleBloc>().loadPlaylist(a);
      emit(state.copyWith(
          items: XHandle.completed(_value.data ?? []),
          playlist: playlist,
          mediaItems: a,
          numberSongs: playlist.numOfSongs));
      PlaylistCoordinator.showPlaylistDetailScreen(context);
    } else {
      XSnackbar.show(msg: 'Load All List Error');
    }
  }

  Future<void> removeFromPlaylist(BuildContext context,
      {required PlaylistModel playlist, required int idSong}) async {
    XLoading.show();
    await Future.delayed(const Duration(seconds: 2));
    final _value = await _domain.playlist
        .removeFromPlaylist(idPlaylist: playlist.id, idSong: idSong);
    if (_value.isSuccess) {
      context.read<PlaylistBloc>().fetchPlaylists();

      emit(state.copyWith(
        items: XHandle.completed(_value.data ?? []),
        numberSongs: state.numberSongs - 1,
      ));
      XSnackbar.show(msg: 'Remove Success');
    } else {
      XSnackbar.show(msg: 'Remove Error');
    }
    XCoordinator.pop(context);

    XLoading.hide();
  }

  Future<void> saveNewNamePlaylist(BuildContext context,
      {required PlaylistModel playlist, required String newName}) async {
    XLoading.show();
    await Future.delayed(const Duration(seconds: 2));
    final _value = await _domain.playlist
        .newNamePlaylist(idPlaylist: playlist.id, newName: newName);
    if (_value.isSuccess) {
      XSnackbar.show(msg: 'Rename Success');
    } else {
      XSnackbar.show(msg: 'Rename Error');
    }
    XCoordinator.pop(context);

    XLoading.hide();
  }
}
