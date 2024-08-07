import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:blindapp/Screens/userHomePage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agora_uikit/agora_uikit.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({super.key});

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterTts _flutterTts = FlutterTts();
  AgoraClient? _client;
  String _channelName = '';
  String? _volunteerId;
  bool _isMicMuted = false; // State to manage mic status
  double _rating = 3.0;

  @override
  void initState() {
    super.initState();
    _initVideoCall();
  }

  Future<void> _initVideoCall() async {
    User? user = _auth.currentUser;
    if (user == null) {
      // Handle user not logged in
      print("User not logged in");
      return;
    }
    String userId = user.uid;

    // Generate a unique channel ID (for simplicity, using a timestamp here)
    _channelName = DateTime.now().millisecondsSinceEpoch.toString();

    // Store the channel in Firestore
    await _firestore.collection('channels').doc(_channelName).set({
      'channelName': _channelName,
      'userId': userId,
      'isOccupied': false,
    });

    _client = AgoraClient(
      agoraConnectionData: AgoraConnectionData(
        appId: '855ba77811cb4d11b801101b74f3d088',
        channelName: _channelName,
        tempToken: null, // Set to null when tokens are disabled
      ),
      agoraEventHandlers: AgoraRtcEventHandlers(
        onUserJoined: (RtcConnection connection, int uid, int elapsed) {
          _handleRemoteUserJoined();
        },
      ),
    );

    await _client!.initialize();

    _client!.engine.setCameraCapturerConfiguration(
        const CameraCapturerConfiguration(
            cameraDirection: CameraDirection.cameraRear));

    setState(() {}); // Refresh the UI
  }

  Future<void> _handleRemoteUserJoined() async {
    try {
      // Retrieve the volunteer ID from the channel document
      DocumentSnapshot channelSnapshot =
          await _firestore.collection('channels').doc(_channelName).get();
      _volunteerId =
          (channelSnapshot.data() as Map<String, dynamic>?)?['volunteerId'];

      if (_volunteerId != null) {
        DocumentSnapshot volunteerSnapshot =
            await _firestore.collection('volunteers').doc(_volunteerId).get();
        Map<String, dynamic>? volunteerData =
            volunteerSnapshot.data() as Map<String, dynamic>?;

        if (volunteerData != null) {
          String volunteerName = volunteerData['name'] ?? 'Unknown';
          double volunteerRating = volunteerData['rating']?.toDouble() ?? 0.0;

          String message =
              'Volunteer $volunteerName with a rating of $volunteerRating stars has joined the call';
          await _speak(message);
        }
      }
    } catch (e) {
      print("Error retrieving volunteer details: $e");
    }
  }

  Future<void> _endCall({bool showRating = true}) async {
    try {
    
      DocumentSnapshot channelSnapshot =
          await _firestore.collection('channels').doc(_channelName).get();
      _volunteerId =
          (channelSnapshot.data() as Map<String, dynamic>?)?['volunteerId'];

      if (_channelName.isNotEmpty) {
        await _firestore.collection('channels').doc(_channelName).delete();
      }

      await _client?.engine.leaveChannel();

      // Show rating dialog if required
      if (showRating && _volunteerId != null) {
        await _showRatingDialog();
      }
    } catch (e) {
      print("Error during end call: $e");
    }
  }

  Future<void> _showRatingDialog() async {
    await _speak("Please rate the volunteer from 1 to 5 stars.");
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rate the Volunteer'),
          content: RatingBar.builder(
            initialRating: 3,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => const Icon(
              Icons.star,
              color: Colors.amber,
            ),
            onRatingUpdate: (rating) async {
              _rating = rating;
              _speak("You have selected ${rating.toString()} stars.");
              Navigator.pop(context); // Close the dialog
              await _submitRating(_rating);
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => UserHomePage()),
                ); // Go back to the home screen
              }
            },
          ),
        );
      },
    );
  }

  Future<void> _submitRating(double rating) async {
    if (_volunteerId == null) {
      print("Volunteer ID is null, cannot submit rating.");
      return;
    }

    DocumentReference volunteerRef =
        _firestore.collection('volunteers').doc(_volunteerId);

    try {
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot volunteerSnapshot =
            await transaction.get(volunteerRef);
        Map<String, dynamic>? volunteerData =
            volunteerSnapshot.data() as Map<String, dynamic>?;

        if (volunteerData == null) {
       
          transaction.set(volunteerRef, {
            'rating': rating,
            'ratingCount': 1,
          });
          print("Volunteer document created with rating: $rating");
        } else {
         
          double currentRating = volunteerData['rating'] ?? 0.0;
          int ratingCount = volunteerData['ratingCount'] ?? 0;

          double newRating =
              ((currentRating * ratingCount) + rating) / (ratingCount + 1);
          transaction.update(volunteerRef, {
            'rating': newRating,
            'ratingCount': ratingCount + 1,
          });
          print("Volunteer document updated with new rating: $newRating");
        }
      });
    } catch (e) {
      print('Error updating rating: $e');
    }
  }

  void _toggleMic() {
    setState(() {
      _isMicMuted = !_isMicMuted;
      _client?.engine.muteLocalAudioStream(_isMicMuted);
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  @override
  void dispose() {
    _endCall(showRating: false).then((_) {
      _flutterTts.stop();
      super.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_client == null) {
      return const Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        await _endCall();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              AgoraVideoViewer(
                client: _client!,
                layoutType: Layout.oneToOne,
                showNumberOfUsers: true,
              ),
              Positioned(
                bottom: 20,
                right: 20,
                left: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.switch_camera, color: Colors.white),
                      onPressed: () {
                        _client?.engine.switchCamera();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.call_end, color: Colors.red),
                      onPressed: () async {
                        await _endCall();
                        if (mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => UserHomePage()),
                          ); // Go back to the home screen
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        _isMicMuted ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMic,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
