VANILLA VR
==========

A VR client for the 1.12 game, played with your body: swing your sword, draw your bow, push a
palm out to cast. Play it on a friend's server, or on a realm of your own on this PC. This folder
holds only the client and its launcher. It has none of the game's files: you need your own copy
of the game.

WHAT YOU NEED
- Windows 10 or 11 and a graphics card with Vulkan (any recent AMD or NVIDIA card).
- A PC VR headset working with SteamVR. A Quest works through Quest Link, Air Link, Steam Link or
  Virtual Desktop.
- Your own World of Warcraft 1.12.1 client (build 5875), English, installed in a folder of its own.
- To play on a friend's server: Tailscale (free), to reach it privately.
- To play on your own: about 6 GB free beside this folder, and an hour of your PC's time once.

ONCE
1. Unzip this folder anywhere. (If Windows warns about files from the internet, right-click the
   zip first, choose Properties, tick Unblock, then unzip.)
2. Playing on a friend's server: make a free Tailscale account and install Tailscale
   (https://tailscale.com/download), then open the share link your friend sent you and accept it.
   You can reach that one PC of theirs and nothing else, and they can't reach yours.

EACH TIME YOU PLAY
1. On a friend's server, make sure Tailscale is connected (its icon by the clock).
2. Start SteamVR with your headset connected.
3. Double-click PLAY.cmd. The Vanilla VR launcher opens. The first time, its Settings ask where
   your 1.12.1 folder is (Browse... finds it) and where you play: on a friend's server (their
   address, filled in already if your friend set it) or on your own. All of it is kept in
   settings.txt. Once your game folder is set, the launcher wears your game's own login-screen
   art, read from your install.
4. The launcher updates your copy if there is a newer version (the bar along the bottom) and shows
   the news. When it says Ready to play, press PLAY.
5. On a friend's server, log in in the headset with the account and password your friend gave you
   (the password ignores case). Point at the fields with your finger and type on the keyboard
   below them. On your own realm, the launcher logs you in.

YOUR OWN REALM (SOLO)
Choose "On my own" in Settings and press PLAY. The first time, the launcher builds you a realm of
your own: it downloads the free vMaNGOS server, its world database and the MariaDB database server
(about 130 MB), then reads your game's maps from your 1.12.1 folder (it never changes it). That
takes about an hour of your PC's time, once. It is the same server and house rules your friend
runs, in the solo folder here, and only this PC can reach it.
Each time after that, the launcher wakes your realm (a minute or so) while you read the news,
logs you in, and when you close the game it saves your progress and puts your realm back to
sleep. Your account is a game master's, so commands like .levelup 10, .tele ironforge or
.partybot add priest work in chat. Updates come from the project's GitHub page, or from your
friend if you also give their address.

HOW WAS IT?
After a session the launcher asks how it went: three numbers (fun, did it work, how your arms and
back feel) and two lines (what felt great, what broke or misfired). Every question is optional,
and "Ask me how it went after I play" in Settings turns it off. Sent with your answers: how long
you played and as whom, your PC and headset, your VR settings, what the session asked of your arms,
the frame times, the moves that fired and the moments you marked as feeling wrong (click both
sticks in the game when something misfires). Your friend's PC posts it on the project's GitHub
page. "Post on GitHub" opens the form for you to post yourself (a GitHub account is needed).
Your name goes on it only if you tick "Put my name on it".

UPDATES
The launcher keeps this folder up to date by itself: each time it opens, it asks your friend's PC
(or, playing solo, the project's GitHub page) for a newer version and fetches only what changed
(the news shows what is new). Every file is checked before anything is replaced, so a bad download
changes nothing. If a new version plays worse, the launcher's "Go back a version" (or
ROLLBACK.cmd) puts the previous one back, and that version is not installed again (the next one
will be). Your own settings (settings.txt, vr-settings.txt) and your realm are never touched. If
the launcher's window will not open, run play.ps1 with PowerShell for the same thing in a console.

YOUR LOGS
So your friend can fix what goes wrong for you and tune the moves, the launcher sends them your
last game logs and motion recordings (your head and hands, the buttons, and the moves that fired;
never voice or video, nothing else from your PC), under the name in its Settings. Untick "Send my
game logs" in Settings, or put SEND_LOGS=no in settings.txt, to stop it. WOWVR_MOTION_LOG= in
vr-settings.txt stops the recordings.

VOICE
Voice chat is built in. Players near you hear you from where your character stands, and you hear
them the same way, fading out by about 30 yards. Nothing to install: the game uses Windows' default
microphone. Only talking is sent, never silence. On the VR page of the game's book:
- Microphone: System's (Windows' default), Headset's (your VR headset's own), or Muted.
- Voices: their volume, or Off.
- Voice goes: Straight to players (the quickest), or Through the host.
Straight to players means your PC and theirs talk directly. The players you talk with can then see
your internet address, as in most online games' voice chat. Two public servers (Google's and
Cloudflare's) are also asked what that address is. Through the host sends your voice through your
friend's PC instead: no other player learns your address, at a little more delay.
Everything you say is encrypted, and only the players near you can hear it. If Windows asks
whether the game may use the network, allow it.

MUMBLE (OPTIONAL, INSTEAD)
If your group prefers Mumble (https://www.mumble.info/downloads/), set Voices to Off on the VR page
(or you will hear everyone twice). Connect Mumble to your friend's Tailscale address (port 64738),
join their channel, and in Configure > Settings (tick Advanced):
- Plugins: tick "Link to Game and Transmit Position" and enable the Link plugin.
- Audio Output: Positional Audio on, Headphones on, Minimum Distance 1 m, Maximum Distance 30 m,
  Minimum Volume 0%.
- Audio Input: Voice Activity (a headset has no key to hold).

CONTROLS
Every button and body move on one page:
https://claude.ai/artifact/JvCN7hMaJAwirPu6VZmg2J
In the game, first-time tips explain each control as it comes up.

IF SOMETHING GOES WRONG
- "Can't reach the server": is Tailscale connected, did you accept the share link, and is your
  friend's server running? Ask them.
- Your realm will not build or wake: the solo\logs folder says why. Press PLAY again to carry on
  from where the build stopped.
- Windows says VCRUNTIME140.dll is missing: install the "Microsoft Visual C++ Redistributable"
  (x64) from Microsoft's website, then try again.
- Windows SmartScreen says it protected your PC: choose "More info", then "Run anyway". The
  client is not signed.
- No picture in the headset: start SteamVR before PLAY.cmd. Without a headset the game runs flat
  on the monitor.
- Comfort and tuning: vr-settings.txt beside this file, or the VR page in the game's book.
- Logs for your friend, if they ask: the logs folder beside this file.

The client is built on Benilla (Apache-2.0 or MIT, see LICENSE-APACHE and LICENSE-MIT). Your own
realm runs vMaNGOS (GPL-2.0, https://github.com/vmangos/core) and MariaDB (GPL-2.0,
https://mariadb.org), downloaded from their own pages when you build it.
