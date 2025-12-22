# Third-Party Licenses

This application uses the following third-party components:

---

## FFmpeg (Non-App Store builds only)

**License:** LGPL 2.1 or later (when built without GPL components)

FFmpeg is a trademark of Fabrice Bellard, originator of the FFmpeg project.

This software uses code of [FFmpeg](http://ffmpeg.org) licensed under the
[LGPLv2.1](http://www.gnu.org/licenses/old-licenses/lgpl-2.1.html).

The FFmpeg source code can be obtained from: https://ffmpeg.org/download.html

### LGPL Compliance Notice

For builds that include FFmpeg (Homebrew and direct distribution builds):

1. This software uses libraries from the FFmpeg project under the LGPLv2.1
2. The source code of FFmpeg is available at https://ffmpeg.org/
3. FFmpeg is dynamically linked / used as an external binary
4. You have the right to obtain the FFmpeg source code and replace the binary

**Note:** App Store builds do NOT include FFmpeg. They use Apple's native
AVFoundation framework instead.

---

## AVFoundation (App Store builds only)

**License:** Proprietary (Apple)

App Store builds use Apple's AVFoundation framework for video conversion.
AVFoundation is part of macOS and iOS and is subject to Apple's license terms.

---

## Wails

**License:** MIT

Copyright (c) 2022 Lea Anthony

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

---

## Other Go Dependencies

This software includes various Go packages. See `go.mod` for the complete list
and their respective licenses.
