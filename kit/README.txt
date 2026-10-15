VANILLA VR - playing on a friend's server
=========================================

A VR client for the 1.12 game, played with your body: swing your sword, draw your bow, push a
palm out to cast. This folder holds only the client and its launcher. It has none of the game's
files: you need your own copy of the game.

WHAT YOU NEED
- Windows 10 or 11 and a graphics card with Vulkan (any recent AMD or NVIDIA card).
- A PC VR headset working with SteamVR. A Quest works through Quest Link, Air Link, Steam Link or
  Virtual Desktop.
- Your own World of Warcraft 1.12.1 client (build 5875), English, installed in a folder of its own.
- Tailscale (free), to reach your friend's server privately.

ONCE
1. Make a free Tailscale account and install Tailscale:
   https://tailscale.com/download
   Sign in when it asks. A new account is fine: it makes you the owner of your own small network.
2. Open the share link your friend sent you and accept it. Your friend's PC then appears in
   Tailscale. You can reach that one PC and nothing else of theirs, and they can't reach yours.
3. Unzip this folder anywhere. (If Windows warns about files from the internet, right-click the
   zip first, choose Properties, tick Unblock, then unzip.)

EACH TIME YOU PLAY
1. Make sure Tailscale is connected (its icon by the clock).
2. Start SteamVR with your headset connected.
3. Double-click PLAY.cmd. The first time it asks where your 1.12.1 folder is and for your friend's
   server address (filled in already if your friend set it). Both are kept in settings.txt.
4. In the headset, log in with the account and password your friend gave you (the password
   ignores case). Point at the fields with your finger and type on the keyboard below them.

UPDATES
PLAY.cmd keeps this folder up to date by itself: each time, before the game starts, it asks your
friend's PC for a newer version and fetches only what changed (it shows what is new). Every file is
checked before anything is replaced, so a bad download changes nothing. If a new version plays
worse, ROLLBACK.cmd puts the previous one back, and that version is not installed again (the next
one will be). Your own settings (settings.txt, vr-settings.txt) are never touched.

YOUR LOGS
So your friend can fix what goes wrong for you, PLAY.cmd sends them your last game logs (what the
game wrote while you played, nothing else from your PC), under the name in settings.txt (NAME=,
your Windows name at first). Put SEND_LOGS=no in settings.txt to stop it.

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
- Windows says VCRUNTIME140.dll is missing: install the "Microsoft Visual C++ Redistributable"
  (x64) from Microsoft's website, then try again.
- Windows SmartScreen says it protected your PC: choose "More info", then "Run anyway". The
  client is not signed.
- No picture in the headset: start SteamVR before PLAY.cmd. Without a headset the game runs flat
  on the monitor.
- Comfort and tuning: vr-settings.txt beside this file, or the VR page in the game's book.
- Logs for your friend, if they ask: the logs folder beside this file.

The client is built on Benilla (Apache-2.0 or MIT, see LICENSE-APACHE and LICENSE-MIT).
