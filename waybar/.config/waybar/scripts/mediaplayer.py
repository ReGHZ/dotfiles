#!/usr/bin/env python3
import gi
gi.require_version("Playerctl", "2.0")
from gi.repository import Playerctl, GLib
import argparse
import logging
import sys
import signal
import json
import os
from typing import List, Dict, Optional

logging.getLogger(__name__).addHandler(logging.NullHandler())
logger = logging.getLogger(__name__)

DEBOUNCE_MS = 50

class PlayerManager:
    def __init__(self, selected_player=None, excluded_player=None):
        self.manager = Playerctl.PlayerManager()
        self.loop = GLib.MainLoop()

        self.manager.connect("name-appeared", self._on_player_appeared)
        self.manager.connect("player-vanished", self._on_player_vanished)

        self.selected_player = selected_player
        self.excluded_player = excluded_player.split(',') if excluded_player else []

        self.players: Dict[str, Playerctl.Player] = {}
        self.player_signals: Dict[str, List[int]] = {}
        self.current_player_name: Optional[str] = None
        self._debounce_id: Optional[int] = None
        self._last_output: Optional[str] = None

        self._setup_signal_handlers()
        self._init_players()

    def _setup_signal_handlers(self):
        def cleanup_and_exit(sig, frame):
            logger.info(f"Received signal {sig}, cleaning up")
            self._cleanup_all()
            sys.stdout.write("\n")
            sys.stdout.flush()
            self.loop.quit()
            sys.exit(0)

        signal.signal(signal.SIGINT, cleanup_and_exit)
        signal.signal(signal.SIGTERM, cleanup_and_exit)
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)

    def _should_manage(self, name: str) -> bool:
        if name in self.excluded_player:
            return False
        if self.selected_player and self.selected_player != name:
            return False
        return True

    def _init_players(self):
        for player in self.manager.props.player_names:
            if self._should_manage(player.name):
                self._add_player(player)
        self._schedule_update()

    def _add_player(self, player):
        name = player.name
        if name in self.players:
            return

        try:
            instance = Playerctl.Player.new_from_name(player)
            sigs = [
                instance.connect("playback-status", lambda *_: self._schedule_update()),
                instance.connect("metadata", lambda *_: self._schedule_update()),
            ]
            self.players[name] = instance
            self.player_signals[name] = sigs
            self.manager.manage_player(instance)
            logger.info(f"Added player: {name}")
        except Exception as e:
            logger.error(f"Failed to add player {name}: {e}")

    def _remove_player(self, name: str):
        if name not in self.players:
            return

        logger.info(f"Removing player: {name}")
        instance = self.players[name]

        for sig_id in self.player_signals.pop(name, []):
            try:
                instance.disconnect(sig_id)
            except Exception:
                pass

        try:
            self.manager.unmanage_player(instance)
        except Exception:
            pass

        del self.players[name]

    def _cleanup_all(self):
        for name in list(self.players):
            self._remove_player(name)
        self.players.clear()
        self.player_signals.clear()
        self.current_player_name = None
        if self._debounce_id is not None:
            GLib.source_remove(self._debounce_id)
            self._debounce_id = None

    def _schedule_update(self):
        """Debounced display update — coalesces rapid events into one output."""
        if self._debounce_id is not None:
            GLib.source_remove(self._debounce_id)
        self._debounce_id = GLib.timeout_add(DEBOUNCE_MS, self._do_update)

    def _do_update(self) -> bool:
        self._debounce_id = None
        player = self._pick_player()

        if player is None:
            self.current_player_name = None
            self._write(None, None)
            return False  # one-shot

        self.current_player_name = player.props.player_name
        text = self._format(player)
        self._write(text, player)
        return False  # one-shot

    def _pick_player(self) -> Optional[Playerctl.Player]:
        """Pick the most relevant player: playing > current > first."""
        for p in self.players.values():
            try:
                if p.props.status == "Playing":
                    return p
            except Exception:
                continue

        if self.current_player_name and self.current_player_name in self.players:
            return self.players[self.current_player_name]

        players = list(self.players.values())
        return players[0] if players else None

    def _format(self, player) -> str:
        try:
            name = player.props.player_name
            artist = player.get_artist()
            title = player.get_title()

            if name == "spotify":
                meta = player.props.metadata
                if meta and "mpris:trackid" in meta.keys() and ":ad:" in meta["mpris:trackid"]:
                    return "[PLAY]  Advertisement"

            if artist and title:
                info = f"{artist} - {title}"
            elif title:
                info = title
            else:
                return ""

            prefix = "[PLAY]" if player.props.status == "Playing" else "[STOP]"
            return f"{prefix}  {info}"
        except Exception as e:
            logger.debug(f"Error formatting: {e}")
            return ""

    def _write(self, text: Optional[str], player: Optional[Playerctl.Player]):
        """Write to stdout, skip if identical to last output."""
        if text:
            raw = json.dumps({
                "text": text,
                "class": "custom-" + player.props.player_name,
                "alt": player.props.player_name,
            })
        else:
            raw = ""

        if raw == self._last_output:
            return

        self._last_output = raw
        sys.stdout.write(raw + "\n")
        sys.stdout.flush()

    def _on_player_appeared(self, _, player):
        logger.info(f"Player appeared: {player.name}")
        if self._should_manage(player.name):
            self._add_player(player)
            self._schedule_update()

    def _on_player_vanished(self, _, player):
        name = player.props.player_name
        logger.info(f"Player vanished: {name}")
        self._remove_player(name)
        if name == self.current_player_name:
            self.current_player_name = None
        self._schedule_update()

    def run(self):
        logger.info("Starting main loop")
        try:
            self.loop.run()
        except KeyboardInterrupt:
            pass
        finally:
            self._cleanup_all()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-v", "--verbose", action="count", default=0)
    parser.add_argument("-x", "--exclude", help="Comma-separated list of excluded players")
    parser.add_argument("--player", help="Single player to monitor")
    parser.add_argument("--enable-logging", action="store_true")
    args = parser.parse_args()

    if args.enable_logging:
        logfile = os.path.join(os.path.dirname(os.path.realpath(__file__)), "media-player.log")
        logging.basicConfig(filename=logfile, level=logging.DEBUG,
                            format="%(asctime)s %(name)s %(levelname)s:%(lineno)d %(message)s")
    else:
        logging.basicConfig(level=logging.WARNING,
                            format="%(asctime)s %(name)s %(levelname)s:%(lineno)d %(message)s")

    logger.setLevel(max((3 - args.verbose) * 10, 0))

    player_manager = None
    try:
        player_manager = PlayerManager(args.player, args.exclude)
        player_manager.run()
    except Exception as e:
        logger.error(f"Error in main: {e}")
    finally:
        if player_manager:
            player_manager._cleanup_all()


if __name__ == "__main__":
    main()
