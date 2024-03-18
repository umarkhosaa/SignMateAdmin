// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'dart:typed_data';
// import 'models/video_info.dart'; // Make sure this file exists with the VideoInfo class
//
// class VideoUploadScreen extends StatefulWidget {
//   @override
//   State<VideoUploadScreen> createState() => _VideoUploadScreenState();
// }
//
// class _VideoUploadScreenState extends State<VideoUploadScreen> {
//   double _uploadProgress = 0;
//   final TextEditingController _titleController = TextEditingController();
//   List<VideoInfo> videos = [];
//   // double _uploadProgress = 0;
//   // final TextEditingController _titleController = TextEditingController();
//
//   @override
//   void dispose() {
//     _titleController.dispose();
//     super.dispose();
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchVideos();
//   }
//
//   Future<void> _fetchVideos() async {
//     var querySnapshot = await FirebaseFirestore.instance.collection('videos').get();
//     setState(() {
//       videos = querySnapshot.docs.map((doc) {
//         return VideoInfo(
//           id: doc.id,
//           url: doc.data().containsKey('url') ? doc['url'] : 'default_url',
//           name: doc.data().containsKey('name') ? doc['name'] : 'default_name',
//           title: doc.data().containsKey('title') ? doc['title'] : 'default_title',
//         );
//       }).toList();
//     });
//
//   }
//
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         appBar: AppBar(
//           title:
//               Text("Sign Mate - Admin", style: TextStyle(color: Colors.white,)),
//           backgroundColor: Colors.deepPurple,
//         ),
//         body: Container(
//           padding: EdgeInsets.all(20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: <Widget>[
//               Text('Upload Video',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//               SizedBox(height: 40),
//               TextField(
//                 controller: _titleController,
//                 decoration: InputDecoration(
//                     labelText: 'Video Title', border: OutlineInputBorder()),
//               ),
//               SizedBox(height: 20),
//               LinearProgressIndicator(value: _uploadProgress),
//               SizedBox(height: 20),
//               ElevatedButton.icon(
//                 icon: Icon(Icons.cloud_upload),
//                 label: Text("Select and Upload Video"),
//                 onPressed: uploadVideo,
//                 style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.white, backgroundColor: Colors.deepPurple),
//               ),
//               Expanded(
//                 child: StreamBuilder<QuerySnapshot>(
//                   stream: FirebaseFirestore.instance.collection('videos').snapshots(),
//                   builder: (context, snapshot) {
//                     if (!snapshot.hasData) {
//                       return CircularProgressIndicator(); // Show loading indicator while waiting for data
//                     }
//
//                     return ListView(
//                       children: snapshot.data!.docs.map((DocumentSnapshot document) {
//                         VideoInfo videoInfo = VideoInfo(
//                           id: document.id,
//                           url: document.get('url'),
//                           name: document.get('name'),
//                           title: document.get('title'),
//                         );
//
//                         return Card(
//                           elevation: 4,
//                           margin: EdgeInsets.symmetric(vertical: 8),
//                           child: ListTile(
//                             leading: Icon(Icons.video_library), // Replace with video thumbnail if available
//                             title: Text(videoInfo.title),
//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 IconButton(
//                                   icon: Icon(Icons.edit),
//                                   onPressed: () => _editVideoTitle(videoInfo),
//                                 ),
//                                 IconButton(
//                                   icon: Icon(Icons.delete),
//                                   onPressed: () => _deleteVideo(videoInfo),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }).toList(),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//         ),
//     );
//   }
//   Future<void> uploadVideo() async {
//     FilePickerResult? result =
//         await FilePicker.platform.pickFiles(type: FileType.video);
//
//     if (result != null) {
//       Uint8List fileBytes = result.files.first.bytes!;
//       String fileName = result.files.first.name;
//
//       Reference ref =
//           FirebaseStorage.instanceFor(bucket: 'gs://signmate-126c5.appspot.com')
//               .ref('videos/$fileName');
//       UploadTask uploadTask = ref.putData(fileBytes);
//
//       uploadTask.snapshotEvents.listen((event) {
//         setState(() {
//           _uploadProgress = event.bytesTransferred / event.totalBytes;
//         });
//       }).onError((error) {
//         print(error);
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Error during upload: $error')));
//       });
//
//       try {
//         TaskSnapshot snapshot = await uploadTask;
//         final String downloadUrl = await snapshot.ref.getDownloadURL();
//         await saveVideoMetadataToFirestore(
//             downloadUrl, fileName, _titleController.text);
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Video uploaded successfully')));
//       } catch (e) {
//         print('Error during video upload: $e');
//         ScaffoldMessenger.of(context)
//             .showSnackBar(SnackBar(content: Text('Error during upload: $e')));
//       }
//     } else {
//       print('No file selected');
//     }
//   }
//
//   Future<void> saveVideoMetadataToFirestore(
//       String downloadUrl, String fileName, String title) async {
//     await FirebaseFirestore.instance.collection('videos').add({
//       'url': downloadUrl,
//       'name': fileName,
//       'title': title,
//     });
//   }
//
//   Future<void> _editVideoTitle(VideoInfo videoInfo) async {
//     TextEditingController titleController =
//         TextEditingController(text: videoInfo.title);
//     return showDialog<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Edit Video Title'),
//           content: TextField(
//             controller: titleController,
//             decoration: InputDecoration(hintText: "Enter new title"),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancel'),
//               onPressed: () => Navigator.of(context).pop(),
//             ),
//             TextButton(
//               child: const Text('Update'),
//               onPressed: () async {
//                 await FirebaseFirestore.instance
//                     .collection('videos')
//                     .doc(videoInfo.id)
//                     .update({'title': titleController.text});
//                 Navigator.of(context).pop();
//                 _fetchVideos();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _deleteVideo(VideoInfo videoInfo) async {
//     await FirebaseFirestore.instance
//         .collection('videos')
//         .doc(videoInfo.id)
//         .delete();
//     await FirebaseStorage.instance.ref('videos/${videoInfo.name}').delete();
//     _fetchVideos();
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import 'models/video_info.dart'; // Make sure this file exists with the VideoInfo class
import 'package:video_player/video_player.dart';

class VideoUploadScreen extends StatefulWidget {
  @override
  State<VideoUploadScreen> createState() => _VideoUploadScreenState();
}

class _VideoUploadScreenState extends State<VideoUploadScreen> {
  double _uploadProgress = 0;
  final TextEditingController _titleController = TextEditingController();
  List<VideoInfo> videos = [];
  VideoPlayerController? _videoPlayerController;

  @override
  void dispose() {
    _titleController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    var querySnapshot = await FirebaseFirestore.instance.collection('videos').get();
    setState(() {
      videos = querySnapshot.docs.map((doc) {
        return VideoInfo(
          id: doc.id,
          url: doc.data().containsKey('url') ? doc['url'] : 'default_url',
          name: doc.data().containsKey('name') ? doc['name'] : 'default_name',
          title: doc.data().containsKey('title') ? doc['title'] : 'default_title',
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null,
        flexibleSpace: Container(
          padding: const EdgeInsets.only(top: 3),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 255, 192, 203),
                Color.fromARGB(200, 255, 0, 0),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/Audiozic logo.png',
              height: 35,
              fit: BoxFit.contain,
            ),
          ),
        ),
        elevation: 3,
        shadowColor: Colors.black,
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Upload Video', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 40),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Video Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(value: _uploadProgress),
            SizedBox(height: 20),
            ElevatedButton.icon(
              icon: Icon(Icons.cloud_upload),
              label: Text("Select and Upload Video"),
              onPressed: uploadVideo,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.deepPurple,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: videos.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(videos[index].title),
                    // leading: IconButton(
                    //   icon: Icon(Icons.play_circle_outline),
                    //   onPressed: () => _playVideo(videos[index].url),
                    // ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit),
                          onPressed: () => _editVideoTitle(videos[index]),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteVideo(videos[index]),
                        ),
                      ],
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

  Future<void> uploadVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video);

    if (result != null) {
      Uint8List fileBytes = result.files.first.bytes!;
      String fileName = result.files.first.name;

      Reference ref = FirebaseStorage.instanceFor(bucket: 'gs://signmate-126c5.appspot.com')
          .ref('videos/$fileName');
      UploadTask uploadTask = ref.putData(fileBytes);

      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      }).onError((error) {
        print(error);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during upload: $error')));
      });

      try {
        TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        await saveVideoMetadataToFirestore(downloadUrl, fileName, _titleController.text);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Video uploaded successfully')));
      } catch (e) {
        print('Error during video upload: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during upload: $e')));
      }
    } else {
      print('No file selected');
    }
  }

  Future<void> saveVideoMetadataToFirestore(
      String downloadUrl, String fileName, String title) async {
    await FirebaseFirestore.instance.collection('videos').add({
      'url': downloadUrl,
      'name': fileName,
      'title': title,
    });
  }

  void _playVideo(String videoUrl) {
    _videoPlayerController?.dispose();
    _videoPlayerController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _videoPlayerController!.play();
      });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: AspectRatio(
            aspectRatio: _videoPlayerController!.value.aspectRatio,
            child: VideoPlayer(_videoPlayerController!),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _videoPlayerController!.pause();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editVideoTitle(VideoInfo videoInfo) async {
    TextEditingController titleController =
    TextEditingController(text: videoInfo.title);
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Video Title'),
          content: TextField(
            controller: titleController,
            decoration: InputDecoration(hintText: "Enter new title"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Update'),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('videos')
                    .doc(videoInfo.id)
                    .update({'title': titleController.text});
                Navigator.of(context).pop();
                _fetchVideos();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteVideo(VideoInfo videoInfo) async {
    await FirebaseFirestore.instance
        .collection('videos')
        .doc(videoInfo.id)
        .delete();
    await FirebaseStorage.instance.ref('videos/${videoInfo.name}').delete();
    _fetchVideos();
  }
}
