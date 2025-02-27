part of spine_flutter;

class SkeletonAnimation extends core.Skeleton {
  SkeletonAnimation(core.SkeletonData data)
      : state = core.AnimationState(core.AnimationStateData(data)),
        super(data);

  final core.AnimationState state;
  // bool _dispose  = false;

  dispose(){
    state.tracks.forEach((element) {
      state.queue.dispose(element!);
    });
    // _dispose = true;
  }

  void applyState() {
    // if(!_dispose) {
      state.apply(this);
    // }
  }

  void updateState(double delta) {
    state.update(delta);
  }

  static Future<SkeletonAnimation> createWithFiles(
    String name, {
    String pathBase = '',
    String rawAtlas = '',
    String rawSkeleton = '',
    Uint8List? rawTexture,
  }) async {
    final String atlasDataFile = '$name.atlas';
    final String skeletonDataFile = '$name.json';
    final String path = '$pathBase$name/';

    print('dashu, atlasDataFile=$atlasDataFile,skeletonDataFile=$skeletonDataFile,path=$path');

    final Map<String, dynamic> assets = <String, dynamic>{};
    final List<Future<MapEntry<String, dynamic>>> futures =
        <Future<MapEntry<String, dynamic>>>[
      AssetLoader.loadJson(path + skeletonDataFile, rawSkeleton),
      AssetLoader.loadText(path + atlasDataFile, rawAtlas),
    ];

    final List<String> textureDataFiles =
        await textureFilesFromAtlas(path + atlasDataFile);
    for (final String textureDataFile in textureDataFiles) {
      final Future<MapEntry<String, dynamic>> entry =
          AssetLoader.loadTexture(path + textureDataFile, rawTexture);
      futures.add(entry);
    }

    await Future.wait(futures).then(assets.addEntries).catchError((Object e) {
      if (kDebugMode) {
        print("Couldn't add entries. $e");
      }
    });

    final core.TextureAtlas atlas = core.TextureAtlas(
        assets[path + atlasDataFile], (String? p) => assets[path + (p ?? '')]);
    final core.AtlasAttachmentLoader atlasLoader =
        core.AtlasAttachmentLoader(atlas);
    final core.SkeletonJson skeletonJson = core.SkeletonJson(atlasLoader);
    final core.SkeletonData skeletonData =
        skeletonJson.readSkeletonData(assets[path + skeletonDataFile]);

    return SkeletonAnimation(skeletonData);
  }

  static Future<List<String>> textureFilesFromAtlas(String pathToAtlas) async {
    final String data = await rootBundle.loadString(pathToAtlas);
    final core.TextureAtlasReader reader = core.TextureAtlasReader(data);
    final List<String> r = <String>[];
    for (;;) {
      String? line = reader.readLine();
      if (line == null) {
        break;
      }

      line = line.trim();
      if (line.isEmpty) {
        continue;
      }

      if (isAllowedImageFileName(line)) {
        r.add(line);
      }
    }

    return r;
  }

  static const List<String> allowedImageExtensions = <String>[
    'jpg',
    'png',
    'webp',
  ];

  static bool isAllowedImageFileName(String file) => allowedImageExtensions
      .firstWhere((String ext) => file.endsWith('.$ext'), orElse: () => '')
      .isNotEmpty;
}
