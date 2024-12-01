// ignore_for_file: unused_import

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:jplay/API/music_api.dart';
import 'package:jplay/music.dart';
import 'package:jplay/style/appColors.dart';
import 'package:jplay/ui/aboutPage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:jplay/widgets/gradient_text.dart';
import 'package:jplay/widgets/audio_player.dart';
import 'package:jplay/ui/directory_browser.dart';

class Jplay extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return AppState();
  }
}

class AppState extends State<Jplay> {
  TextEditingController searchBar = TextEditingController();
  bool fetchingSongs = false;
  List searchedList = [];
  String title = '';
  String artist = '';
  String image = '';
  String kUrl = '';
  String checker = '';
  String has_320 = '';
  String rawkUrl = '';

  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xff1c252a),
      statusBarColor: Colors.transparent,
    ));
  }

  search() async {
    String searchQuery = searchBar.text;
    if (searchQuery.isEmpty) return;
    fetchingSongs = true;
    setState(() {});
    await searchSongs(searchQuery);
    fetchingSongs = false;
    setState(() {});
  }

  Future<void> searchSongs(String query) async {
    setState(() => fetchingSongs = true);
    searchedList = await MusicAPI.searchSongs(query);
    setState(() => fetchingSongs = false);
  }

  Future<void> getSongDetails(String id, BuildContext context) async {
    try {
      var details = await MusicAPI.getSongDetails(id);
      if (details['url'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudioPlayerScreen(
              videoId: details['id'],
              title: details['title'],
              artist: details['artist'],
              thumbnail: details['image'],
            ),
          ),
        );
      } else {
        Fluttertoast.showToast(
          msg: "This song is not available",
          backgroundColor: Colors.black,
          textColor: Color(0xff61e88a),
        );
      }
    } catch (e) {
      print(e);
      Fluttertoast.showToast(
        msg: "Unable to play this song",
        backgroundColor: Colors.black,
        textColor: Color(0xff61e88a),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xff384850),
            Color(0xff263238),
            Color(0xff263238),
          ],
        ),
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.transparent,
        //backgroundColor: Color(0xff384850),
        bottomNavigationBar: kUrl != ""
            ? Container(
                height: 75,
                //color: Color(0xff1c252a),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18)),
                    color: Color(0xff1c252a)),
                child: Padding(
                  padding: const EdgeInsets.only(top: 5.0, bottom: 2),
                  child: GestureDetector(
                    onTap: () {
                      checker = "Nahi";
                      if (kUrl != "") {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AudioApp()),
                        );
                      }
                    },
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 8.0,
                          ),
                          child: IconButton(
                            icon: Icon(
                              MdiIcons.appleKeyboardControl,
                              size: 22,
                            ),
                            onPressed: null,
                            disabledColor: accent,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 0.0, top: 7, bottom: 7, right: 15),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: CachedNetworkImage(
                              imageUrl: image,
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 0.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                title,
                                style: TextStyle(
                                    color: accent,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(
                                artist,
                                style:
                                    TextStyle(color: accentLight, fontSize: 15),
                              )
                            ],
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: playerState == MusicPlayerState.playing
                              ? Icon(Icons.pause_circle_outline)
                              : Icon(Icons.play_circle_outline),
                          color: accent,
                          splashColor: Colors.transparent,
                          onPressed: () {
                            setState(() {
                              if (playerState == MusicPlayerState.playing) {
                                audioPlayer.pause();
                                playerState = MusicPlayerState.paused;
                              } else if (playerState == MusicPlayerState.paused) {
                                audioPlayer.setUrl(kUrl).then((_) => audioPlayer.play());
                                playerState = MusicPlayerState.playing;
                              }
                            });
                          },
                          iconSize: 45,
                        )
                      ],
                    ),
                  ),
                ),
              )
            : SizedBox.shrink(),
        body: Column(
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 30, bottom: 20.0)),
            Center(
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 42.0),
                      child: Center(
                        child: GradientText(
                          "jPlay",
                          gradient: LinearGradient(colors: [
                            Color(0xff4db6ac),
                            Color(0xff61e88a),
                          ]),
                          style: TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    child: IconButton(
                      iconSize: 26,
                      alignment: Alignment.center,
                      icon: Icon(MdiIcons.dotsVertical),
                      color: accent,
                      onPressed: () => {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutPage(),
                          ),
                        ),
                      },
                    ),
                  )
                ]),
            ),
            Padding(padding: EdgeInsets.only(top: 20)),
            TextField(
              onSubmitted: (String value) {
                search();
              },
              controller: searchBar,
              style: TextStyle(
                fontSize: 16,
                color: accent,
              ),
              cursorColor: Colors.green[50],
              decoration: InputDecoration(
                fillColor: Color(0xff263238),
                filled: true,
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(100),
                  ),
                  borderSide: BorderSide(
                    color: Color(0xff263238),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(100),
                  ),
                  borderSide: BorderSide(color: accent),
                ),
                suffixIcon: IconButton(
                  icon: fetchingSongs
                      ? SizedBox(
                          height: 18,
                          width: 18,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.search,
                          color: accent,
                        ),
                  color: accent,
                  onPressed: () {
                    search();
                  },
                ),
                border: InputBorder.none,
                hintText: "Search...",
                hintStyle: TextStyle(
                  color: accent,
                ),
                contentPadding: const EdgeInsets.only(
                  left: 18,
                  right: 20,
                  top: 14,
                  bottom: 14,
                ),
              ),
            ),
            Expanded(
              child: searchedList.isNotEmpty
                ? ListView.builder(
                    shrinkWrap: true,
                    itemCount: searchedList.length,
                    itemBuilder: (context, index) {
                      final item = searchedList[index];
                      return ListTile(
                        leading: CachedNetworkImage(
                          imageUrl: item['image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          item['artist'],
                          style: TextStyle(
                            color: accentLight,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () => getSongDetails(item['id'], context),
                      );
                    },
                  )
                : FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
                    future: MusicAPI.getMusicByFolders(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final folders = snapshot.data!;
                        return ListView.builder(
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folderName = folders.keys.elementAt(index);
                            final items = folders[folderName]!;
                            
                            return ExpansionTile(
                              title: Text(
                                folderName,
                                style: TextStyle(color: Colors.white),
                              ),
                              leading: Icon(Icons.folder, color: accent),
                              children: items.map((item) {
                                final isDirectory = item['isDirectory'] ?? false;
                                
                                return ListTile(
                                  leading: Icon(
                                    isDirectory ? Icons.folder : Icons.music_note,
                                    color: accent,
                                  ),
                                  title: Text(
                                    item['title'] ?? '',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: !isDirectory ? Text(
                                    item['artist'] ?? 'Unknown Artist',
                                    style: TextStyle(color: accentLight),
                                  ) : null,
                                  onTap: () async {
                                    if (isDirectory) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => DirectoryBrowser(
                                            path: item['id'],
                                            title: item['title'],
                                          ),
                                        ),
                                      );
                                    } else {
                                      getSongDetails(item['id'], context);
                                    }
                                  },
                                );
                              }).toList(),
                            );
                          },
                        );
                      }
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(accent),
                        ),
                      );
                    },
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget getTopSong(String image, String title, String subtitle, String id) {
    return InkWell(
      onTap: () {
        getSongDetails(id, context);
      },
      child: Column(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.17,
            width: MediaQuery.of(context).size.width * 0.4,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: CachedNetworkImageProvider(image),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Text(
            title
                .split("(")[0]
                .replaceAll("&amp;", "&")
                .replaceAll("&#039;", "'")
                .replaceAll("&quot;", "\""),
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xff263238),
          content: Row(
            children: [
              LoadingAnimationWidget.staggeredDotsWave(
                color: accent,
                size: 40,
              ),
              SizedBox(width: 20),
              Text(
                message,
                style: TextStyle(color: accent),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> topSongs() async {
    return await MusicAPI.getRecentSongs();
  }
}
