# Vanilla VR

A VR client for the 1.12 game, played with your body: swing your sword, draw your bow, push a palm
out to cast, lay a hand on a friend to heal them, and talk to the players near you. Play on a
friend's server, joined privately over Tailscale, or on a realm of your own that the launcher builds
on your PC.

This repository is the **kit**: the client, its launcher and its guide. The client is built on
[Benilla](https://github.com/samwhosung/benilla), a 1.12.1 client written from scratch in Rust.

> **No game files are included.** You need your own copy of the World of Warcraft 1.12.1 client.
> The kit reads the game's data from your install, on your PC, and so does the launcher's look.
> Vanilla VR is not affiliated with or endorsed by Blizzard Entertainment. World of Warcraft is a
> trademark of Blizzard Entertainment, Inc.

**[The install guide](INSTALL.md)** takes you from nothing to standing in the game.

![The launcher](docs/launcher-ready.png)

## What you need

- **Windows 10 or 11** with a graphics card that supports Vulkan (any recent AMD or NVIDIA card).
- **A PC VR headset that works with SteamVR.** A Quest works through Quest Link, Air Link, Steam
  Link or Virtual Desktop.
- **Your own World of Warcraft 1.12.1 client**, build 5875, English, in a folder of its own.
- **To play on a friend's server:** a free [Tailscale](https://tailscale.com/download) account, and
  from your friend a share link and an account on their server.
- **To play on your own:** about 6 GB free, and an hour of your PC's time once.

## Get it

1. Download the **VanillaVR** zip from [Releases](../../releases/latest).
2. Right-click the zip, choose **Properties**, tick **Unblock**, then unzip it anywhere you like.
3. Double-click **`PLAY.cmd`**. The launcher's Settings ask for your game folder and where you play.

## The launcher

`PLAY.cmd` opens a launcher in the manner of the old game's: the news, your realm, a progress bar
and a big **PLAY** button. Once it knows your game folder it wears your game's own login-screen
art (the logo, the red buttons, the gold frames, the fonts), read from your install; nothing of the
game is downloaded or shared.

- **Updates** itself every time it opens, from your friend's PC, or from this page's releases when
  you play on your own. Only what changed is fetched, and every file is checked before anything is
  replaced. **Go back a version** undoes an update that plays worse.
- **On your own**, it builds your realm once (the free [vMaNGOS](https://github.com/vmangos/core)
  server, its world database and [MariaDB](https://mariadb.org), downloaded from their own pages,
  then your game's maps read from your install), wakes it while you read the news, logs you straight
  in, and puts it to sleep with your progress saved when you close the game. Your account is a game
  master's: `.levelup`, `.tele` and `.partybot add` work in chat.
- **After you play**, it asks how it went: fun, did it work, and how your arms and back feel, 1 to
  5, plus what felt great and what broke. That, with what the session measured, becomes a
  [playtest report](../../issues?q=label%3Aplaytest) here.

## Playtest reports

Vanilla VR is built around three questions: is it fun, does it work, and how does your body feel
after an hour of it. Every report helps answer them. Sent with your answers: how long you played and
as which class, your PC's parts and your headset, your VR settings, what the session asked of your
arms, the frame times, the moves that fired and the moments you marked (click both thumbsticks when
something misfires). Your logs and motion recording go only to the friend whose server you play on,
never to GitHub, and your name is on a report only if you tick **Put my name on it**. Playing on your
own with no friend, **Post on GitHub** opens the report as a form for you to post yourself.

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

## What's here

| | |
|---|---|
| [`INSTALL.md`](INSTALL.md) | The install guide, with what to do when something goes wrong |
| [`kit/`](kit) | The launcher and guide as they ship in the zip: `PLAY.cmd`, `launcher.ps1`, `play.ps1` (its engine), `solo.ps1` (your own realm), `ROLLBACK.cmd`, `README.txt`, `vr-settings.txt` |
| [Releases](../../releases) | The kit itself: the client `benilla-vr.exe` and `launcher-art.exe` (the launcher's look, read from your game) with the files above, and the update the launcher fetches |
| [`THIRD-PARTY-NOTICES.txt`](THIRD-PARTY-NOTICES.txt) | The licenses of the libraries inside the client |

## License

The client and the launcher are under the MIT license or the Apache License 2.0, at your option, as
Benilla is: see [LICENSE-MIT](LICENSE-MIT) and [LICENSE-APACHE](LICENSE-APACHE). The libraries
inside the client keep their own licenses, listed in
[THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt). Your own realm runs vMaNGOS and MariaDB (both
GPL-2.0), which the launcher downloads from their own projects' pages when you build it; they are
not part of this kit.
