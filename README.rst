***********
Pi MusicBox
***********

Pi MusicBox is the Swiss Army Knife of streaming music on the Raspberry Pi.
With Pi MusicBox, you can create a cheap (Sonos-like) standalone streaming
music player for Spotify and other online music services.


Features
========

- Headless audio player based on `Mopidy <https://www.mopidy.com/>`_. Just
  connect your speakers or headphones - no need for a monitor.
- Quick and easy setup with no Linux knowledge required.
- Stream music from Spotify, SoundCloud, Google Music and YouTube.
- Listen to podcasts (with iTunes and Podder directories) as well as online
  radio (TuneIn, Dirble and Soma FM).
- Play MP3/OGG/FLAC/AAC music from your SD card, USB drives and network shares.
- Remote controllable with a choice of browser-interfaces or with an MPD-client
  (e.g. `MPDroid
  <https://play.google.com/store/apps/details?id=com.namelessdev.mpdroid>`_ for
  Android).
- AirTunes/AirPlay and DLNA streaming from your smartphone, tablet or computer.
- Support for all kinds of USB, HifiBerry and IQ Audio soundcards.
- Wi-Fi support (WPA, Raspbian supported Wi-Fi adapters only)
- Last.fm scrobbling.
- Spotify Connect support.


Installation
============

1. Download Raspbian lite
   https://www.raspberrypi.org/downloads/raspbian/
2. Write the image to your SD card. See `here <https://www.raspberrypi.org/documentation/installation/installing-images/README.md>`_ for details.
3. Boot your Raspberry Pi and wait for it to start.
4. Run the following commands

   cd /home/pi
   sudo apt install git
   git clone https://github.com/asrashley/pimusicbox.git
   cd pimusicbox
   sudo ./create_musicbox.sh



Project resources
=================

- `Website <http://www.pimusicbox.com/>`_
- `Discussion forum <https://discourse.mopidy.com/c/pi-musicbox>`_
- `Source code <https://github.com/pimusicbox/pimusicbox>`_
- `Changelog <https://github.com/pimusicbox/pimusicbox/blob/develop/docs/changes.rst>`_
- `Issue tracker <https://github.com/pimusicbox/pimusicbox/issues>`_
- Twitter: `@PiMusicBox <https://twitter.com/pimusicbox>`_
- Facebook: `raspberrypimusicbox <https://www.facebook.com/raspberrypimusicbox>`_


License
=======

Copyright 2013-2017 Wouter van Wijk and contributors.

Licensed under the Apache License, Version 2.0. See the file LICENSE for the
full license text.
