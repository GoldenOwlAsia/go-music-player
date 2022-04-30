import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:zanmelodic/src/config/themes/my_colors.dart';

class CustomImageWidget extends StatelessWidget {
  const CustomImageWidget(
      {Key? key,
      required this.id,
      this.height = double.infinity,
      this.width = double.infinity,
      this.artworkType = ArtworkType.AUDIO})
      : super(key: key);
  final int id;
  final double? height;
  final double? width;
  final ArtworkType artworkType;

  @override
  Widget build(BuildContext context) {
    return QueryArtworkWidget(
      artworkBorder: BorderRadius.circular(20.0),
      artworkHeight: height,
      artworkWidth: width,
      id: id,
      type: artworkType,
      keepOldArtwork: true,
      nullArtworkWidget: const Icon(
        Icons.image_not_supported,
        size: 50,
        color: MyColors.colorWhite,
      ),
    );
  }
}