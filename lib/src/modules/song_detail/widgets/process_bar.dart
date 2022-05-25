import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zanmelodic/src/config/themes/my_colors.dart';
import 'package:zanmelodic/src/modules/audio_control/logic/audio_handle_bloc.dart';

class ProcessBar extends StatelessWidget {
  const ProcessBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //const _pHori = 40.0;
    //   final _size = MediaQuery.of(context).size.width - _pHori * 2;
    return BlocBuilder<AudioHandleBloc, AudioHandleState>(
      builder: (context, state) {
        // final _current = state.progress.current.inSeconds.toDouble();
        // final _total = state.progress.total.inSeconds.toDouble();
        // final _posSeek = _current / (_total / _size);

        return state.waveform.isEmpty
            ? Center(
                child: Text(
                  'Load widget ${(100 * state.progressWidget).toInt()}%',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              )
            : SquigglyWaveform(
                inactiveColor: MyColors.colorWhite,
                activeColor: MyColors.colorPrimary,
                strokeWidth: 1,
                maxDuration: state.progress.total,
                elapsedDuration: state.progress.current,
                samples: state.waveform,
                height: 60,
                width: 280,
              );
        // return Column(
        //   children: [
        //     SizedBox(
        //       height: 60,
        //       child: Stack(
        //         children: [
        //           Image.asset(
        //             MyImage.audio,
        //             color: MyColors.colorWhite1,
        //           ),
        //           Align(
        //             alignment: Alignment.center,
        //             child: ProgressBar(
        //               progress: state.progress.current,
        //               buffered: state.progress.buffered,
        //               total: state.progress.total,
        //               onSeek: state.audioHandler.seek,
        //               timeLabelLocation: TimeLabelLocation.none,
        //               thumbCanPaintOutsideBar: false,
        //               baseBarColor: Colors.transparent,
        //               thumbColor: Colors.transparent,
        //               thumbGlowColor: Colors.transparent,
        //               progressBarColor: Colors.transparent,
        //               bufferedBarColor: Colors.transparent,
        //               thumbGlowRadius: 30,
        //             ),
        //           ),
        //           Positioned(
        //             left: _posSeek,
        //             width: 1,
        //             height: 60,
        //             child: Container(
        //               color: MyColors.colorGray,
        //             ),
        //           ),
        //         ],
        //       ),
        //     ),
        //     Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       children: [
        //         _timeSong(state.progress.current),
        //         _timeSong(state.progress.total)
        //       ],
        //     ),
        //   ],
        // );
      },
    );
  }

  // Text _timeSong(Duration duration) {
  //   return Text(
  //     XUtils.formatDuration(duration),
  //     style: Style.textTheme().titleMedium!.copyWith(fontSize: 17),
  //   );
  // }
}
