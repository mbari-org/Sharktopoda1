# Sharktopoda 2

_Sharktopoda 2_ will be a video player that supports MBARI's video annotation and machine learning efforts. It is a native desktop application that will support remote control from other applications via UDP. In addition, it will display rectangular regions of interest (ROIs, aka _localizations_, aka _bounding boxes_, aka _annotations_) and allow the user to interact (e.g. create, edit, delete) with them. A prototype example is illustrated at <https://youtu.be/FKeuG8-UYC0>.

## Localizations

A Localization is a labeled and localized rectangular region at a given moment in the video. It is also called an `Annotation` and has the following properties:

- `uuid` - The unique identifier for an annotation. UUID v4 (random) is recommended.
- `concept` - The label associated with a localization that identifies the object in the region of interest. In theory, the concept can be up to 256 characters long, but in practice it is much shorter.
- `elapsedTimeMillis` - The elapsed time from the start of the video that the localization is to be displayed.
- `durationMillis` - This field may be present but can be ignored for now. It represents how long the localization is valid. It will span from `elapsedTimeMillis` to `elapsedTimeMillis` + `durationMillis`. The default is 0 which means the localization is valid for a single frame.
- `x` - The x coordinate of the localization in pixels.
- `y` - The y coordinate of the localization in pixels.
- `width` - The width of the localization in pixels.
- `height` - The height of the localization in pixels.
- `color` - The color used to draw the localization.

Additional fields can be added as deemed necessary to support Sharktopoda's functions.

The video player will display prexisting bounding boxes over the video at the correct frame. The player will allow users to specify a time window. Each bounding boxes will have a defined `elapsedTimeMillis`. A visual representation of the bounding box will be displayed from `elapsedTimeMillis - timeWindow / 2.0` to `elapsedTimeMillis + timeWindow / 2.0` over the video. The timeWindow can be set in preferences.

Each localization will be correctly scaled and translated from it's pixel coordinates to match the video as it is scaled. (e.g. when a window is resized)

Localization information can be created/update/deleted/selected via an external application via a [UDP-based remote protocol](UDP_Remote_Protocol.md). Localizations can also be created/updated/deleted/selected from Sharktopoda and then inform the remote applications that an event occurred via the same UDP protocol.

## Specifications

- [UDP Remote Protocol](UDP_Remote_Protocol.md)
- [UI](UI.md)
