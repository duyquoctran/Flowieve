import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diff_image/diff_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';
import 'fire_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

void main() => runApp(MaterialApp(
      home: MyApp(),
    ));

String image1 = "images/imageflower5.jpg";
String image2 = "images/imageflower15.jpg";
String image = image1;

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with SingleTickerProviderStateMixin {
  final Firestore fb = Firestore.instance;
  List _outputs;
  File _image;
  bool _loading = false;
  var imagetest = "images";
  var imagequery;
  var listtest;
  var listsort;
  var snapshotdata;

  AnimationController animationController;
  Animation degOneTranslationAnimation,
      degTwoTranslationAnimation,
      degThreeTranslationAnimation;
  Animation rotationAnimation;

  double getRadiansFromDegree(double degree) {
    double unitRadian = 57.295779513;
    return degree / unitRadian;
  }

  @override
  void initState() {
    animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 250));
    degOneTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.2), weight: 75.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.2, end: 1.0), weight: 25.0),
    ]).animate(animationController);
    degTwoTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.4), weight: 55.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.4, end: 1.0), weight: 45.0),
    ]).animate(animationController);
    degThreeTranslationAnimation = TweenSequence([
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.0, end: 1.75), weight: 35.0),
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.75, end: 1.0), weight: 65.0),
    ]).animate(animationController);
    rotationAnimation = Tween<double>(begin: 180.0, end: 0.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut));

    super.initState();

    animationController.addListener(() {
      setState(() {});
    });

    _loading = true;
    loadModel().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('CBIR PROJECT'),
        ),
        body: _loading
            ? Container(
                alignment: Alignment.center,
                child: CircularProgressIndicator(),
              )
            : Container(
                // width: MediaQuery.of(context).size.width,
                alignment: Alignment.center,
                height: MediaQuery.of(context).size.height / 1.0,
                width: MediaQuery.of(context).size.width,
                child: ListView(children: [
                  SizedBox(
                    height: 100,
                  ),
                  //
                  //Ảnh input từ device
                  _image == null
                      ? Container()
                      : Image.file(
                          _image,
                          height: 200,
                        ),
                  //
                  SizedBox(
                    height: 20,
                  ),
                  // Text sau khi classify
                  _outputs != null
                      ? Center(
                          child: Text(
                          // "${'index:' + _outputs[0]["index"].toString() + ' ' + 'label:' + _outputs[0]["label"] + ' ' + '(' + (_outputs[0]["confidence"] * 100).toStringAsFixed(0) + '%)'}",
                          "${'Flower type:' + ' ' + _outputs[0]["label"] + ' ' + '(' + (_outputs[0]["confidence"] * 100).toStringAsFixed(0) + '%)'}",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20.0,
                            // background: Paint()
                            //   ..color = Colors.white,
                          ),
                        ))
                      : Container(),
                  //
                  SizedBox(
                    height: 20,
                  ),

                  // Dòng "Results"
                  _outputs != null ? textSection1 : Container(),

                  // Lấy tất cả các ảnh store từ Cloud Firestore
                  FutureBuilder(
                    future: getImages(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        snapshotdata = snapshot;
                        return ListView.builder(
                            physics: ScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: snapshot.data.documents.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Card(
                                  color: Colors.grey[100],
                                  semanticContainer: true,
                                  // clipBehavior: Clip.antiAliasWithSaveLayer,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  elevation: 5,
                                  margin: EdgeInsets.all(10),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(25.0),
                                    //Image
                                    leading: listsort != null
                                        ? Image.network(
                                            snapshot
                                                .data
                                                .documents[listsort[index]]
                                                .data["url"],
                                            fit: BoxFit.fill)
                                        : Image.network(
                                            snapshot.data.documents[index]
                                                .data["url"],
                                            fit: BoxFit.fill),
                                    //Name of image
                                    title: listsort != null
                                        ? Text(
                                            snapshot
                                                .data
                                                .documents[listsort[index]]
                                                .data["name"],
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20.0,
                                            ),
                                          )
                                        : Text(
                                            snapshot.data.documents[index]
                                                .data["name"],
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20.0,
                                            ),
                                          ),
                                    //% Diff of image
                                    subtitle: listtest != null
                                        ? Text(
                                            '${'Similiarity: ' + (100 - listtest[index]).toStringAsFixed(1) + '%'}',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20.0,
                                            ),
                                          )
                                        : Container(),

                                    // trailing: Icon(Icons.sort),

                                    // onTap: () async {
                                    //   //Notification
                                    //   final snackBar = SnackBar(
                                    //       content: Text('Wait a minute !!!'));
                                    //   Scaffold.of(context)
                                    //       .showSnackBar(snackBar);
                                    //   //Hàm so sánh vô đây
                                    //   //test
                                    //   processimage();
                                    //   sorting();
                                    // },
                                  ));
                            });
                      } else if (snapshot.connectionState ==
                          ConnectionState.none) {
                        return Text("No data");
                      }
                      return Container();
                    },
                  ),

                  // // Lấy ảnh từ FB Storage
                  // FutureBuilder(
                  //   future: _getImage(context, image),
                  //   builder: (context, snapshot) {
                  //     if (snapshot.connectionState == ConnectionState.done)
                  //       return Container(
                  //         height: MediaQuery.of(context).size.height / 3.0,
                  //         width: MediaQuery.of(context).size.width / 2.0,
                  //         child: snapshot.data,
                  //       );

                  //     if (snapshot.connectionState == ConnectionState.waiting)
                  //       return Container(
                  //           height: MediaQuery.of(context).size.height / 3.0,
                  //           width: MediaQuery.of(context).size.width / 3.0,
                  //           child: CircularProgressIndicator());

                  //     return Container();
                  //   },
                  // ),

                  // Center(
                  //   child: loadButton(context),
                  // ),

                  // _outputs != null
                  //     ? Center(
                  //         child: Text(
                  //         "${'index:' + _outputs[0]["index"].toString() + ' ' + 'label:' + _outputs[0]["label"] + ' ' + '(' + (_outputs[0]["confidence"] * 100).toStringAsFixed(0) + '%)'}",
                  //         style: TextStyle(
                  //           color: Colors.black,
                  //           fontSize: 20.0,
                  //           background: Paint()..color = Colors.white,
                  //         ),
                  //       ))
                  //     : Container(),

                  // floatingActionButton: FloatingActionButton(
                  //   onPressed: pickImage,
                  //   child: Icon(Icons.image),
                  // ),
                ])),
        floatingActionButton: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Stack(children: <Widget>[
              Positioned(
                  right: 10,
                  bottom: 10,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: <Widget>[
                      IgnorePointer(
                        child: Container(
                          color: Colors.black.withOpacity(
                              0.0), // comment or change to transparent color
                          height: 150.0,
                          width: 150.0,
                        ),
                      ),
                      Transform.translate(
                        offset: Offset.fromDirection(getRadiansFromDegree(270),
                            degOneTranslationAnimation.value * 100),
                        child: Transform(
                          transform: Matrix4.rotationZ(
                              getRadiansFromDegree(rotationAnimation.value))
                            ..scale(degOneTranslationAnimation.value),
                          alignment: Alignment.center,
                          child: CircularButton(
                            color: Colors.blue,
                            width: 50,
                            height: 50,
                            icon: Icon(
                              Icons.add_a_photo,
                              color: Colors.white,
                            ),
                            onClick: pickImage,
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset.fromDirection(getRadiansFromDegree(225),
                            degTwoTranslationAnimation.value * 100),
                        child: Transform(
                          transform: Matrix4.rotationZ(
                              getRadiansFromDegree(rotationAnimation.value))
                            ..scale(degTwoTranslationAnimation.value),
                          alignment: Alignment.center,
                          child: CircularButton(
                            color: Colors.black,
                            width: 50,
                            height: 50,
                            icon: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            onClick: takeImage,
                          ),
                        ),
                      ),
                      _outputs != null
                          ? Builder(
                              builder: (context) => Transform.translate(
                                    offset: Offset.fromDirection(
                                        getRadiansFromDegree(180),
                                        degThreeTranslationAnimation.value *
                                            100),
                                    child: Transform(
                                      transform: Matrix4.rotationZ(
                                          getRadiansFromDegree(
                                              rotationAnimation.value))
                                        ..scale(
                                            degThreeTranslationAnimation.value),
                                      alignment: Alignment.center,
                                      child: CircularButton(
                                        color: Colors.purpleAccent,
                                        width: 50,
                                        height: 50,
                                        icon: Icon(
                                          Icons.sort,
                                          color: Colors.white,
                                        ),
                                        onClick: () async {
                                          //Notification
                                          final snackBar = SnackBar(
                                              content:
                                                  Text('Wait a minute !!!'));
                                          Scaffold.of(context)
                                              .showSnackBar(snackBar);
                                          //Hàm so sánh vô đây
                                          //test
                                          processimage();
                                          sorting();
                                        },
                                      ),
                                    ),
                                  ))
                          : Container(),
                      Transform(
                        transform: Matrix4.rotationZ(
                            getRadiansFromDegree(rotationAnimation.value)),
                        alignment: Alignment.center,
                        child: CircularButton(
                          color: Colors.blue,
                          width: 60,
                          height: 60,
                          icon: Icon(
                            Icons.menu,
                            color: Colors.white,
                          ),
                          onClick: () {
                            if (animationController.isCompleted) {
                              animationController.reverse();
                            } else {
                              animationController.forward();
                            }
                          },
                        ),
                      )
                    ],
                  ))
            ])));
  }

  //Hàm xử lí sắp xếp
  //test
  Future<Void> processimage() async {
    var listdiff = new List(snapshotdata.data.documents.length);
    for (var i = 0; i < snapshotdata.data.documents.length; i++) {
      var response = await http.get(snapshotdata.data.documents[i].data["url"]);
      var image2 = img.decodeImage(response.bodyBytes);
      image2 = img.copyResize(image2, width: 300, height: 300);
      listdiff[i] = await DiffImage.compare(imagequery, image2);
    }
    //After sorting
    var sorted = listdiff.toList();
    sorted.sort((a, b) => a.compareTo(b));
    var lists = new List();
    for (var j = 0; j < sorted.length; j++) {
      for (var k = 0; k < listdiff.length; k++) {
        if (listdiff[k] == sorted[j]) {
          var tempsnap = snapshotdata.data.documents[j];
          snapshotdata.data.documents[j] = snapshotdata.data.documents[k];
          snapshotdata.data.documents[k] = tempsnap;
          lists.add(k);
          break;
        }
      }
    }
    setState(() {
      listsort = lists;
    });
  }

  //test
  Future<Void> sorting() async {
    var listdiff = new List(snapshotdata.data.documents.length);
    for (var i = 0; i < snapshotdata.data.documents.length; i++) {
      var response = await http.get(snapshotdata.data.documents[i].data["url"]);
      var image2 = img.decodeImage(response.bodyBytes);
      image2 = img.copyResize(image2, width: 300, height: 300);
      listdiff[i] = await DiffImage.compare(imagequery, image2);
    }

    setState(() {
      listdiff.sort((a, b) => a.compareTo(b));
      listtest = listdiff;
    });
  }

  //Hàm lấy ảnh từ Cloud Firestore
  Future<QuerySnapshot> getImages() {
    return fb.collection(imagetest).getDocuments();
  }

  //"Results" text
  Widget textSection1 = Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          'Results',
          softWrap: true,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
      ));

  //Hàm classify ảnh
  classifyImage(File image) async {
    var output = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 1,
      threshold: 0.1,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _loading = false;
      _outputs = output;
      imagetest = _outputs[0]["label"];
    });
  }

  //Take a picture
  takeImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = image;
    });
    classifyImage(image);
    imagequery = img.copyResize(img.decodeImage(image.readAsBytesSync()),
        width: 300, height: 300);
    listtest = null;
    listsort = null;
  }

  //Pick ảnh từ device
  pickImage() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return null;
    setState(() {
      _loading = true;
      _image = image;
    });
    classifyImage(image);
    imagequery = img.copyResize(img.decodeImage(image.readAsBytesSync()),
        width: 300, height: 300);
    listtest = null;
    listsort = null;
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/b1_aug.tflite",
      labels: "assets/labels.txt",
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  //test
  //   Future<File> urlToFile(String imageUrl) async {
  // // generate random number.
  //     var rng = new Random();
  // // get temporary directory of device.
  //     Directory tempDir = await getTemporaryDirectory();
  // // get temporary path from temporary directory.
  //     String tempPath = tempDir.path;
  // // create a new file in temporary path with random file name.
  //     File file = new File('$tempPath' + (rng.nextInt(100)).toString() + '.png');
  // // call http.get method and pass imageUrl into it to get response.
  //     http.Response response = await http.get(imageUrl);
  // // write bodyBytes received in response to file.
  //     await file.writeAsBytes(response.bodyBytes);
  // // now return the file which is created with random name in
  // // temporary directory and image bytes from response is written to // that file.
  //     // return file;
  //     // classifyImage(file);
  //   }

  // Lấy ảnh từ FB Storage
  // Future<Widget> _getImage(BuildContext context, String image) async {
  //   Image m;

  //   await FireStorageService.loadFromStorage(context, image)
  //       .then((downloadUrl) async {
  //     //Chuyển để classify ảnh trên mạng
  //     // urlToFile(downloadUrl);
  //     // Diff test 2 ảnh
  //     // var difftest = await DiffImage.compareFromUrl(FIRST_IMAGE, downloadUrl);
  //     // print('The difference between images is: $difftest percent');
  //     m = Image.network(
  //       downloadUrl.toString(),
  //       fit: BoxFit.scaleDown,
  //     );
  //     // setState(() {
  //     //   _diff = difftest;
  //     // });
  //   });
  //   return m;
  // }

  //Nút random ảnh từ FB Storage "RANDOM IMAGE"
  // Widget loadButton(BuildContext context) {
  //   return Container(
  //     child: Stack(
  //       children: <Widget>[
  //         Container(
  //           padding:
  //               const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16.0),
  //           margin: const EdgeInsets.only(
  //               top: 30, left: 20.0, right: 20.0, bottom: 20.0),
  //           decoration: BoxDecoration(
  //               gradient: LinearGradient(
  //                 colors: [Colors.lightBlue, Colors.lightBlueAccent],
  //               ),
  //               borderRadius: BorderRadius.circular(30.0)),
  //           child: FlatButton(
  //             onPressed: () {
  //               //fetch another image
  //               setState(() {
  //                 final _random = new Random();
  //                 var imageList = [image1, image2];
  //                 image = imageList[_random.nextInt(imageList.length)];
  //               });
  //             },
  //             child: Text(
  //               "RANDOM IMAGE",
  //               style: TextStyle(fontSize: 20),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Widget buttonSection1 = Container(
  //   child: Row(
  //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //     children: [
  //       /*_buildButtonColumn(color, Icons.call, 'CALL'),
  //         _buildButtonColumn(color, Icons.near_me, 'ROUTE'),
  //         _buildButtonColumn(color, Icons.share, 'SHARE'),*/
  //       Image.asset(
  //         'assets/images/lake.jpg',
  //         width: 120,
  //         height: 150,
  //         fit: BoxFit.fitWidth,
  //       ),
  //       Image.asset(
  //         'assets/images/lake.jpg',
  //         width: 120,
  //         height: 150,
  //         fit: BoxFit.fitWidth,
  //       ),
  //       Image.asset(
  //         'assets/images/lake.jpg',
  //         width: 120,
  //         height: 150,
  //         fit: BoxFit.fitWidth,
  //       ),
  //     ],
  //   ),
  // );
}

class CircularButton extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Icon icon;
  final Function onClick;

  CircularButton(
      {this.color, this.width, this.height, this.icon, this.onClick});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      width: width,
      height: height,
      child: IconButton(icon: icon, enableFeedback: true, onPressed: onClick),
    );
  }
}
