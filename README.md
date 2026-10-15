# Vanilla VR

A VR client for the 1.12 game, played with your body: swing your sword, draw your bow, push a palm
out to cast, lay a hand on a friend to heal them, and talk to the players near you. Your friend
runs the server on their PC, and you join it privately over Tailscale.

This repository is the **friend kit**: the client, its launcher and its guide. The client is built on
[Benilla](https://github.com/samwhosung/benilla), a 1.12.1 client written from scratch in Rust.

> **No game files are included.** You need your own copy of the World of Warcraft 1.12.1 client.
> The kit reads the game's data from your install, on your PC. Vanilla VR is not affiliated with or
> endorsed by Blizzard Entertainment. World of Warcraft is a trademark of Blizzard Entertainment, Inc.

## What you need

- **Windows 10 or 11** with a graphics card that supports Vulkan (any recent AMD or NVIDIA card).
- **A PC VR headset that works with SteamVR.** A Quest works through Quest Link, Air Link, Steam
  Link or Virtual Desktop.
- **Your own World of Warcraft 1.12.1 client**, build 5875, English, in a folder of its own.
- **A free [Tailscale](https://tailscale.com/download) account**, which lets you reach your friend's
  PC without opening anything to the internet.
- **From your friend:** a Tailscale share link, and an account and password on their server.

## Get it

1. Download the newest **VanillaVR-Friend-&lt;date&gt;.zip** from
   [Releases](../../releases/latest).
2. If Windows warns about files from the internet, right-click the zip, choose **Properties**, tick
   **Unblock**, then unzip it anywhere you like.

## Once, before your first game

1. **Install Tailscale and make an account.** A new account is right: it makes you the owner of
   your own small network, which accepting a share needs.
2. **Accept your friend's share link.** Their PC then shows up in Tailscale.

## Each time you play

1. **Check Tailscale is connected.** Its icon sits by the clock.
2. **Start SteamVR** with your headset connected.
3. **Double-click `PLAY.cmd`** in the kit. The first time, it asks where your 1.12.1 folder is and
   for your friend's server address (their Tailscale address, like `100.101.102.103`), and keeps
   both in `settings.txt`. It checks the server answers before starting.
4. **Log in inside the headset.** Point at the fields with your finger and type on the keyboard
   that floats below them.

## Updates

`PLAY.cmd` keeps the kit up to date by itself. Each time, before the game starts, it asks your
friend's PC for a newer version and fetches only what changed. Every file is checked before anything
is replaced, so a bad download changes nothing.

If a new version plays worse, **`ROLLBACK.cmd`** puts the previous one back, and that version is
not installed again. Your own settings (`settings.txt`, `vr-settings.txt`) are never touched.

So your friend can fix what goes wrong for you, `PLAY.cmd` sends them your last game logs: only what
the game wrote while you played, nothing else from your PC. Put `SEND_LOGS=no` in `settings.txt`
to stop it.

## Voice chat

Voice chat is built in. Players near you hear you from where your character stands, and you hear
them the same way, fading out by about 30 yards. Nothing to install: the game uses Windows' default
microphone, and only talking is sent, never silence. On the VR page of the game's book:

- **Microphone**: System's (Windows' default), Headset's (your VR headset's own), or Muted.
- **Voices**: their volume, or Off.
- **Voice goes**: Straight to players (the quickest), or Through the host.

Straight to players means your PC and theirs talk directly, so the players you talk with can see
your internet address, as in most online games' voice chat. Two public servers (Google's and
Cloudflare's) are also asked what that address is. **Through the host** sends your voice through
your friend's PC instead: no other player learns your address, at a little more delay. Everything
you say is encrypted, and only the players near you can hear it.

## Controls

Every button and body move is on one page:
**[the controls sheet](https://claude.ai/artifact/JvCN7hMaJAwirPu6VZmg2J)**. In the game,
first-time tips explain each control as it comes up. What the client can do so far is on
[the progress page](https://claude.ai/artifact/MUduZNciSaVUg31Hvx33dZ).

## If something goes wrong

- **"Can't reach the server"**: is Tailscale connected, did you accept the share link, and is your
  friend's server running? Ask them.
- **Windows says `VCRUNTIME140.dll` is missing**: install the Microsoft Visual C++ Redistributable
  (x64) from Microsoft's website, then try again.
- **Windows SmartScreen says it protected your PC**: choose **More info**, then **Run anyway**. The
  client is not signed.
- **No picture in the headset**: start SteamVR before `PLAY.cmd`. Without a headset the game runs
  flat on your monitor.
- **Too much motion, or too little**: the VR page in the game's book, or `vr-settings.txt` in the
  kit.
- **Logs for your friend**: the `logs` folder beside `PLAY.cmd`.

## What's here

| | |
|---|---|
| [`kit/`](kit) | The launcher and guide as they ship in the zip: `PLAY.cmd`, `play.ps1`, `ROLLBACK.cmd`, `README.txt`, `vr-settings.txt` |
| [Releases](../../releases) | The kit itself: the client `benilla-vr.exe` with the files above |
| [`THIRD-PARTY-NOTICES.txt`](THIRD-PARTY-NOTICES.txt) | The licenses of the libraries inside the client |

## License

The client and the launcher are under the MIT license or the Apache License 2.0, at your option, as
Benilla is: see [LICENSE-MIT](LICENSE-MIT) and [LICENSE-APACHE](LICENSE-APACHE). The libraries
inside the client keep their own licenses, listed in
[THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt).
