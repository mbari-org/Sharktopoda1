# Sharktopoda 2

_Sharktopoda 2_ will be a native desktop video player application that supports MBARI's video annotation and machine learning efforts. It should be written in the most current version of [Swift](https://developer.apple.com/swift/) and should be based off of [AVFoundation](https://developer.apple.com/av-foundation/) and/or [AVKit](https://developer.apple.com/documentation/avkit).

It will function as a normal video player, including standard audio playback. In addition, it will support these additional features beyond a standard video player:

1. Support remote control from an external application via a [Remote UDP Protocol](UDP_Remote_Protocol.md). Only a single remote app will connect to the video player at a time.
2. Ability to render [Localizations](#localizations), which are labeled, rectangular regions of interest (ROIs, aka _localizations_, aka _bounding boxes_, aka _annotations_) , on top of the video at the correct moment in the video.
3. Ability to interact (create/edit/delete) localizations on a video.

Here are video examples of a prototype to help guide development:

- [A Remote Annotation Application interacting a with the video player](https://youtu.be/FKeuG8-UYC0)
- [A Remote Annotation Application interacting a with the video player showing selectable localizations](https://youtu.be/m8jOhxDvv5Y).
- [A video player displaying output from machine learning inference](https://youtu.be/AZr0WcuEffQ)

## Localizations

A [Localization](UDP_Remote_Protocol.md#localizations) is a labeled and localized rectangular region at a given moment in the video. It is also called an `Annotation` and has the following properties:

- `uuid` - The unique identifier for an annotation. UUID v4 (random) is recommended.
- `concept` - The label associated with a localization that identifies the object in the region of interest. In theory, the concept can be up to 256 characters long, but in practice it is much shorter.
- `elapsedTimeMillis` - The elapsed time from the start of the video that the localization is to be displayed.
- `durationMillis` - This field is optional. It represents how long the localization is valid. It will span from `elapsedTimeMillis` to `elapsedTimeMillis` + `durationMillis`. The default is 0 which means the localization is valid for a single frame.
- `x` - The x coordinate of the localization in pixels.
- `y` - The y coordinate of the localization in pixels.
- `width` - The width of the localization in pixels.
- `height` - The height of the localization in pixels.
- `color` - The color used to draw the localization.

Additional fields can be added as deemed necessary to support Sharktopoda's functions.

The video player will display pre-existing localizations over the video at the correct frame. The player will allow users to specify a time window in the _Preferences_ that is combined with a localization's  `elapsedTimeMillis`. In general, a visual representation of the bounding box will be displayed from `elapsedTimeMillis - timeWindow / 2.0` to `elapsedTimeMillis + timeWindow / 2.0` over the video. More details [here](UI.md#annotation-display).

The localizations x, y, width, and height are in unscaled pixels relative to the videos actual (i.e. not-scaled) width/height. Each localization will be drawn correctly scaled and translated from it's pixel coordinates to match the video as the video is resized.

Localization information can be created/update/deleted/selected via an external application via a [UDP-based remote protocol](UDP_Remote_Protocol.md). Localizations can also be created/updated/deleted/selected from Sharktopoda and then inform the remote applications that an event occurred via the same UDP protocol.

## Specifications

- [UDP Remote Protocol](UDP_Remote_Protocol.md)
- [UI](UI.md)

## Resources

- A Java implementation of the [UDP Remote Protocol](UDP_Remote_Protocol.md) is at <https://github.com/mbari-org/vcr4j/tree/develop/vcr4j-remote> with examples of it's use [here](https://github.com/mbari-org/vcr4j/tree/develop/vcr4j-examples/src/main/java/org/mbari/vcr4j/examples/remote). We will be using this library for testing this application.
- Source code for a Java-based video player that uses the [UDP_Remote_Protocol](UDP_Remote_Protocol.md) is at [mbari-org/jsharktopoda](https://github.com/mbari-org/jsharktopoda/tree/feature/vcr4j-remote). Note that jsharktopoda is a test bed for the UPD protocol, it does not draw any localizations.
- The [current release of Sharktopoda](https://github.com/mbari-org/Sharktopoda/releases) uses an older version of a UDP Remote Protocol and is written using an outdated version of Swift.
- Tutorial on adding overlays in AVFoundation [1](https://www.raywenderlich.com/6236502-avfoundation-tutorial-adding-overlays-and-animations-to-videos) and [2](https://www.raywenderlich.com/2734-avfoundation-tutorial-adding-overlays-and-animations-to-videos)
- [Cabbage](https://github.com/VideoFlint/Cabbage) composition framework
- [VideoLab](https://github.com/ruanjx/VideoLab) video effects framework
