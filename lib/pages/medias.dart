// import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kicko/appbar.dart';
import 'package:kicko/services/database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kicko/services/app_state.dart';

class DisplayProfileImages extends StatefulWidget {
  const DisplayProfileImages({Key? key}) : super(key: key);

  @override
  _DisplayProfileImages createState() => _DisplayProfileImages();
}

class _DisplayProfileImages extends State<DisplayProfileImages> {
  bool inProcess = false;
  late dynamic profileImages;
  DatabaseMethods dataBaseMethods = DatabaseMethods();

  buildImageProfileWraps(dynamic storageReferences) {
    List<Widget> r = [];

    for (dynamic storageReference in storageReferences) {
      String storageReferenceBasename =
      storageReference.split('%2F').last.split('?')[0];
      Widget w = Column(
        children: [
          Container(
            child: InkWell(
              onTap: () {
                dataBaseMethods.updateTableField(
                    storageReferenceBasename,
                    "image_id",
                    "update_business_fields");
              }, // Image tapped
              splashColor: Colors.white10, // Splash color over image
              child: Image.network(
                storageReference,
                fit: BoxFit.fill,
              ),
            ),
            width: 200,
            height: 200,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          )
        ],
      );

      r.add(w);
    }

    return r;
  }

  getProfileImages()
  // BUCKET IN FORM business_images/userGroup/currentUsername
  async {
    String currentUsername = appState.currentUser.username;
    String userGroup = appState.userGroup;

    String bucket = 'business_images/$userGroup/$currentUsername';
    return dataBaseMethods.downloadFiles(bucket);
  }

  @override
  void initState() {
    super.initState();
    profileImages = getProfileImages();
  }

  Future<XFile?> selectImageFromGallery() async {
    final picker = ImagePicker();

    setState(() {
      inProcess = true;
    });

    Future<XFile?> xFile = picker.pickImage(source: ImageSource.gallery);

    setState(() {
      inProcess = false;
    });

    return xFile;
  }

  Future<void> addProfileImage()
  // BUCKET IN FORM business_images/userGroup/currentUsername
  async {
    XFile? image = await selectImageFromGallery();

    if (image == null) {
      throw Exception('an exception occured');
    } else {
      String postId = DateTime.now().millisecondsSinceEpoch.toString();
      String imageName = "post_$postId.jpg";
      String currentUsername = appState.currentUser.username;
      String userGroup = appState.userGroup;
      await dataBaseMethods.uploadFile(
          'business_images/$userGroup/$currentUsername', imageName, image);
      bool res = await dataBaseMethods.updateTableField(
          imageName, "image_id", "update_business_fields");
      if (res) {
        print("popup succesfully uploaded");
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DisplayProfileImages()),
        );
      } else {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: protoAppBar("Images de profil"),
      body: Column(
        children: [
          Center(child: ElevatedButton(
            onPressed: () => addProfileImage(),
            child: Text('Ajouter photo de profile',
              style: Theme.of(context).textTheme.displayMedium,
            ),
          )),
          FutureBuilder(
            future: profileImages,
            builder: (context, AsyncSnapshot snapshot) {
              if (snapshot.hasData) {
                dynamic profileImagesList = snapshot.data;

                return Wrap(
                    children: buildImageProfileWraps(profileImagesList));
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                return const Text('Chargement...');
              }
            },
          ),
        ],
      ),
    );
  }
}
