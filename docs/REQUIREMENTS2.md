# Sharktopoda 2 Requirements

Sharktopoda will be a Max OS X video playback application based on AVFoundation/AVKit. It supports a UDP connection allowing other local applications to connect to it. This connection allows other applications to control and query Sharktopoda.

Sharktopoda will display videos (either local files or remote URL's) in windows just like Apples' QuickTime app does. Each window will have a unique UUID associated to the window (more about that below). Sharktopoda can route control/query commands to the appropriate video window with this UUID.

## UI

The UI can be the stock AVKit windows. It should have the controls pictured below. The window should be able to be resized. The ability to make a video window full-screen is nice-to-have, but not required.

![Sharktopus UI](images/Sharktopus.png)

## Configuring the UDP Port

- Under _Preferences_, a user should be able to specify the UDP port that can be used to connect to the app.
- This UDP port should be saved as a preference so it is preserved and restored if an application is shut down and restarted.

## Commands Accepted via the UDP port

Sharktopoda will receive JSON messages and respond with JSON via the UDP port configured under Preferences. It should support the following commands and corresponding functions:

### Connect

 Establishes a remote host and port number that Sharktopus can send outgoing UDP messages to another application. There are 2 forms of this message.

 ![Port Configuration](images/Port%20Configuration.png)

 The first form omits the "host" field; Sharktopoda assumes that the host is "localhost".

```json
{
  "command": "connect",
  "port": "8095"
}
```

The second form explicitly specifies the host:

```json
{
  "command": "connect",
  "port": "8095",
  "host": "some.server.org"
}
```

### -- Open

Opens the specified video in a new window. The application should associate the URL and UUID with the window. (More on that later).

If a window with the UUID already exits, the window should be focused and brought to the front of all open Sharktopoda windows (i.e. the same behavior as the "show" command below) and a success response returned.

#### Open URL

```json
{
  "command": "open",
  "url": "http://someurl/and/moviefile.mov",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170"
}
```

#### Open File (using file URL)

```json
{
  "command": "open",
  "url": "file://somefileurl/and/moviefile.mp4",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170"
}
```

Either open command should respond with a success or failure message:

##### Successfully opened video response

```json
{
  "response": "open",
  "status": "ok"
}
```

##### Failed to open video response

```json
{
  "response": "open",
  "status": "failed"
}
```

### -- Close

It should close the window with the corresponding UUID:

```json
{
  "command": "close",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170"
}
```

Close should respond with an ack:

```json
{
  "response": "close",
  "status": "ack"
}
```

### -- Show

Focuses the window containing the video with the given UUID and brings it to the front of all open Sharktopoda windows.

```json
{
  "command": "show",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170"
}
```

Show should respond with an ack:

```json
{
  "response": "show",
  "status": "ack"
}
```

### -- Request Video Information for the focused Window

// TODO should this use a UUID instead of the focused window or maybe that should be a separate command

```json
{"command": "request video information"}
```

It should return the UUID and URL of the currently focused (or top most window in z order) as well as the length of the video in milliseconds (named as `duration_millis`) and the frame_rate of the mov

```json
{
  "response": "request video information",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170",
  "url": "http://someurl/and/moviefile.mov",
  "duration_millis": 150000,
  "frame_rate": "29.97"
}
```

### -- Request information for all open videos

```json
{"command": "request all information"}
```

It should return info for all open videos like the following:

```json
{
  "response": "request all information",
  "videos": [
    {
      "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170",
      "url": "http://someurl/and/moviefile.mov"
    },
    {
      "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170",
      "url": "file://sometoherurl/and/moviefile.mp4"
    }
  ]
}
```

### -- Play

Play the video associated with the UUID. The play rate will be 1.0

```json
{
  "command": "play",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170"
}
```

Optionally the play command can contain a rate for the playback. A positive rate is forward, negative is reverse.

```json
{
  "command": "play",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170",
  "rate": "-2.4"
}
```

It should respond with:

```json
{
  "response": "play",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170",
  "status":"ok"
}
```

or

```json
{
  "response": "play",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170",
  "status": "failed"
}
```

### -- Pause

Pauses the playback for the video specified by the UUID

```json
{
  "command": "pause",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170"
}
```

It should respond with:

```json
{
  "response": "pause",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170",
  "status":"ok"
}
```

or, in the case of failure, such as the requested video UUID does not exist:

```json
{
  "response": "pause",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170",
  "status": "failed"
}
```

### -- Request elapsed time

Return the elapsed time (from the start) of the video as milliseconds.

```json
{
  "command": "request elapsed time",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170"
}
```

It should respond with:

```json
{
  "response": "request elapsed time",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170",
  "elapsed_time_millis": "12345"
}
```

### -- Request Status

Return the current playback status of the video (by UUID). Possible responses include: `shuttling forward`, `shuttling reverse`, `paused`, `playing`, `not found`.

- _playing_ is when the video is playing at a rate of 1.0
- _shuttling forward_ is when the video is playing with a positive rate that is not equal to 1.0
- _shuttling reverse_ is when the video is playing with a negative rate.
- _paused_ is obvious. (Not playing)

```json
{"command": "request status", "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170"}
```

An example response is:

```json
{"response": "request status", "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170", "status": "playing"}
```

### -- Seek Elapsed Time

Seek to the provided elapsed time (which will be in milliseconds)

```json
{
  "command": "seek elapsed time",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170",
  "elapsed_time_millis": "12345"
}
```

Seek should respond with an ack:

```json
{
  "response": "seek elapsed time",
  "status": "ack"
}
```

### -- Frame advance

Advance the video one frame for the given video The UDP/JSON command is

```json
{
  "command": "frame advance",
  "uuid": "cb5cf7f1-e19c-40ba-b176-a7e479a3cdef"
}
```

Frame advance should respond with an ack:

```json
{
  "response": "frame advance",
  "status": "ack"
}
```

### -- Framecapture

Sharktopoda should immediately grab the current frame from the video along with the elapsed time of that frame. The image should be saved (in a separate non-blocking thread. I think this is the default in AVFoundation). This action should not interfere with video playback.

```mermaid
sequenceDiagram 
    participant app as Remote App
    participant shark as Sharktopoda
    participant videos as Open Videos
    participant disk as Local Disk

    Note over app,shark: Remote app must tell Sharktopoda which remote port is open via "connect" command
    app->>shark: connect command to define remote port
    shark->>shark: Open UDP client to send messages to Remote App

    app->>+shark: {"command": "framecapture", ... }
    shark->>app: ack
    shark->>videos: find video by UUID

    alt UUID not found
      shark->>app: status failed response
    else UUID found
    Note over shark,disk: On separate thread
      shark->>videos: Capture image and elapsed time into video
      shark->>disk: write lossless PNG to disk at image_location
      alt Unable to write PNG to image_location
        shark->>app: status failed message via remote port
      else write PNG was successful
        shark->>-app: status success message via remote port
      end
    end
```

 ![Framecapture](images/Framecapture.png)

```json
{
  "command": "framecapture",
  "uuid": "b52cf7f1-e19c-40ba-b176-a7e479a3b170",
  "image_location": "/Some/path/to/save/image.png",
  "image_reference_uuid": "aa4cf7f1-e19c-40ba-b176-a7e479a3cdef"
}
```

When Sharktopoda receives the command is should response with an ack:

```json
{
  "command": "framecapture",
  "status" : "ack"
}
```

After the image has been written to disk, Sharktopoda should inform the remote app that the image has succesfully been written to disk via the remote UDP port specified in the _connect_ command.

```json
{
  "response": "framecapture",
  "elapsed_time_millis": "12345",
  "image_reference_uuid": "aa4cf7f1-e19c-40ba-b176-a7e479a3cdef",
  "image_location": "/Some/path/to/save/image.png",
  "status": "ok"
}
```

The _status_ field should be `"failed"` if Sharktopus is unable to capture and write the image to disk.

```json
{
  "response": "framecapture",
  "elapsed_time_millis": "12345",
  "image_reference_uuid": "aa4cf7f1-e19c-40ba-b176-a7e479a3cdef",
  "image_location": "/Some/path/to/save/image.png",
  "status": "failed"
}
```

## Localizations

A localization defines a rectangular region of interest on the video. Users should be able to draw these regions directly on a video window in sharktopoda. Sharktopoda will, in turn, notify the remote app that a new localization has been created. Sharktopoda needs to be able to handle 10,000s of localizations in a video and have them drawn on the correct frames as the video is played, rewinded, etc.

Localizations can be added, deleted, or modified from either a remote app or from sharktopoda. If a localization is created/mutated in Sharktopoda, it will notify the remote app using UDP via the port defined by the connect command.

### -- Add Localization(s)

The initiating app (both sharktopoda and the remote app can create localizations) will send a notification of a new localizations to the other app.

```json
{
  "command": "add localizations",
  "uuid": "<the video's uuid>",
  "localizations": [
    {
      "uuid": "<uuid unique to this localization>",
      "concept": "Bathybembix bairdii",
      "elapsedTimeMillis": 49211,
      "durationMillis": 25, // optional
      "x": 1076,
      "y": 13,
      "width": 623,
      "height": 475
    }
  ]
}
```

The receiving app should respond with an ack:

```json
{
  "response": "add localizations",
  "status": "ack"
}
```

or a failure if the video with uuid does not exist:

```json
{
  "response": "add localizations",
  "status": "failed"
}
```

### -- Localizaton(s) deleted

The initiating app will send a notification of localizations to be deleted.

```json
{
  "commmand": "remove localizations",
  "uuid": "<the video's uuid>",
  "localizations": [
    "<uuid for localiation A>",
    "<uuid for localiation B>"
  ]
}
```

The receiving app will respond with an ack:

```json
{
  "response": "remove localizations",
  "status": "ack"
}
```

or a failure if the video with uuid does not exist:

```json
{
  "response": "remove localizations",
  "status": "failed"
}
```

### -- Localizations(s) modified

```json
{
  "command": "update localizations",
  "uuid": "<the video's uuid>",
  "localizations": [
    {
      "uuid": "<uuid unique to this localization>",
      "concept": "Bathybembix bairdii",
      "elapsedTimeMillis": 49211,
      "durationMillis": 25, // optional
      "x": 1076,
      "y": 13,
      "width": 623,
      "height": 475
    }
  ]
}
```

The receiving app will respond with an ack:

```json
{
  "response": "update localizations",
  "status": "ack"
}
```

or a failure if the video with uuid does not exist:

```json
{
  "response": "update localizations",
  "status": "failed"
}
```

### -- Clear all Localizations

This will only be sent from the remote app to Sharktopoda (not vice versa). Sharktopoda should remove all cached information about the localizations for a given video.

```json
{
  "command": "clear localizations",
  "uuid": "<the video's uuid>"
}
```

Sharktopoda will respond with an ack:

```json
{
  "response": "clear localizations",
  "status": "ack"
}
```

or a failure if the video with uuid does not exist:

```json
{
  "response": "clear localizations",
  "status": "failed"
}
```
