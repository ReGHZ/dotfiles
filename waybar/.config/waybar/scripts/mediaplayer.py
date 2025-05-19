#!/usr/bin/env python3
import gi
gi.require_version("Playerctl", "2.0")
from gi.repository import Playerctl, GLib
from gi.repository.Playerctl import Player
import argparse
import logging
import sys
import signal
import json
import os
from typing import List, Dict, Optional

# Configure a null handler by default to avoid "No handler found" warnings
logging.getLogger(__name__).addHandler(logging.NullHandler())
logger = logging.getLogger(__name__)

def signal_handler(sig, frame):
    logger.info("Received signal to stop, exiting")
    sys.stdout.write("\n")
    sys.stdout.flush()
    sys.exit(0)

class PlayerManager:
    def __init__(self, selected_player=None, excluded_player=None):
        self.manager = Playerctl.PlayerManager()
        self.loop = GLib.MainLoop()
        
        # Setup signal handlers
        self.manager.connect("name-appeared", self.on_player_appeared)
        self.manager.connect("player-vanished", self.on_player_vanished)
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
        
        # Store configuration
        self.selected_player = selected_player
        self.excluded_player = excluded_player.split(',') if excluded_player else []
        
        # Track active players and current player
        self.players: Dict[str, Player] = {}
        self.current_player_name: Optional[str] = None
        
        # Initialize existing players
        self.init_players()

    def init_players(self):
        """Initialize all existing players that match our criteria"""
        for player in self.manager.props.player_names:
            if self._should_manage_player(player.name):
                self.init_player(player)

    def _should_manage_player(self, player_name: str) -> bool:
        """Determine if we should manage this player based on configuration"""
        if player_name in self.excluded_player:
            return False
        if self.selected_player and self.selected_player != player_name:
            return False
        return True

    def run(self):
        """Start the main loop"""
        logger.info("Starting main loop")
        self.loop.run()

    def init_player(self, player):
        """Initialize a new player and connect signals"""
        logger.info(f"Initialize new player: {player.name}")
        
        # Create player instance and connect signals
        player_instance = Playerctl.Player.new_from_name(player)
        player_instance.connect("playback-status", self.on_playback_status_changed)
        player_instance.connect("metadata", self.on_metadata_changed)
        
        # Keep track of this player
        self.players[player.name] = player_instance
        self.manager.manage_player(player_instance)
        
        # Initial metadata update
        self.on_metadata_changed(player_instance, player_instance.props.metadata)

    def get_players(self) -> List[Player]:
        """Return list of managed players"""
        return list(self.players.values())

    def write_output(self, text, player):
        """Write formatted output to stdout for waybar consumption"""
        if not text:
            self.clear_output()
            return
            
        logger.debug(f"Writing output: {text}")
        output = {
            "text": text,
            "class": "custom-" + player.props.player_name,
            "alt": player.props.player_name
        }
        sys.stdout.write(json.dumps(output) + "\n")
        sys.stdout.flush()

    def clear_output(self):
        """Clear the output display"""
        sys.stdout.write("\n")
        sys.stdout.flush()

    def on_playback_status_changed(self, player, status, _=None):
        """Handle player status changes"""
        player_name = player.props.player_name
        logger.debug(f"Playback status changed for player {player_name}: {status}")
        
        # Update display with this player's info if it's playing or if it's our current player
        self.update_display()

    def get_first_playing_player(self) -> Optional[Player]:
        """Find the first playing player, or return None"""
        # First look for any player with "Playing" status
        for player in self.get_players():
            if player.props.status == "Playing":
                return player
                
        # If no player is playing but we have a current player, return it
        if self.current_player_name and self.current_player_name in self.players:
            return self.players[self.current_player_name]
            
        # Otherwise return the first player if any exist
        players = self.get_players()
        return players[0] if players else None

    def update_display(self):
        """Update the display with the most important player info"""
        # Get the most important player (playing or current)
        current_player = self.get_first_playing_player()
        
        if current_player is not None:
            # Update our current player reference
            self.current_player_name = current_player.props.player_name
            # Update display with this player's metadata
            self.on_metadata_changed(current_player, current_player.props.metadata)
        else:
            # No players to display
            self.current_player_name = None
            self.clear_output()

    def on_metadata_changed(self, player, metadata, _=None):
        """Handle metadata changes for a player"""
        player_name = player.props.player_name
        logger.debug(f"Metadata changed for player {player_name}")
        
        # Only process if this is our current player or if this is a playing player
        current_playing = self.get_first_playing_player()
        if current_playing is None or current_playing.props.player_name == player_name:
            track_info = self.format_track_info(player, metadata)
            if track_info:
                self.write_output(track_info, player)
                # Update our current player reference
                self.current_player_name = player_name
        else:
            logger.debug(f"Other player {current_playing.props.player_name} is playing, skipping {player_name}")

    def format_track_info(self, player, metadata) -> str:
        """Format track information for display"""
        player_name = player.props.player_name
        artist = player.get_artist()
        title = player.get_title()
        
        # Format the track info
        track_info = ""
        if player_name == "spotify" and "mpris:trackid" in metadata.keys() and ":ad:" in metadata["mpris:trackid"]:
            track_info = "Advertisement"
        elif artist is not None and title is not None:
            track_info = f"{artist} - {title}"
        elif title is not None:
            track_info = title
            
        # Add status prefix
        if track_info:
            if player.props.status == "Playing":
                track_info = "[PLAY]  " + track_info
            else:
                track_info = "[STOP]  " + track_info
                
        return track_info

    def on_player_appeared(self, _, player):
        """Handle new player appearance"""
        logger.info(f"Player has appeared: {player.name}")
        if self._should_manage_player(player.name):
            self.init_player(player)
            # Maybe update display if no player is currently active
            if self.current_player_name is None:
                self.update_display()

    def on_player_vanished(self, _, player):
        """Handle player disappearance"""
        player_name = player.props.player_name
        logger.info(f"Player {player_name} has vanished")
        
        # Remove from our tracked players
        if player_name in self.players:
            del self.players[player_name]
            
        # If this was our current player, find a new one
        if player_name == self.current_player_name:
            self.update_display()

def parse_arguments():
    parser = argparse.ArgumentParser()

    # Increase verbosity with every occurrence of -v
    parser.add_argument("-v", "--verbose", action="count", default=0)
    
    # Define excluded players
    parser.add_argument("-x", "--exclude", help="Comma-separated list of excluded players")
    
    # Define selected player
    parser.add_argument("--player", help="Single player to monitor")
    
    # Enable logging to file
    parser.add_argument("--enable-logging", action="store_true")

    return parser.parse_args()

def main():
    arguments = parse_arguments()

    # Initialize logging
    if arguments.enable_logging:
        logfile = os.path.join(os.path.dirname(
            os.path.realpath(__file__)), "media-player.log")
        logging.basicConfig(filename=logfile, level=logging.DEBUG,
                            format="%(asctime)s %(name)s %(levelname)s:%(lineno)d %(message)s")
    else:
        # Set up a basic null handler to prevent warnings
        logging.basicConfig(level=logging.WARNING, 
                            format="%(asctime)s %(name)s %(levelname)s:%(lineno)d %(message)s")

    # Set log level based on verbosity
    logger.setLevel(max((3 - arguments.verbose) * 10, 0))

    # Create and run the player manager
    logger.info("Creating player manager")
    player = PlayerManager(arguments.player, arguments.exclude)
    player.run()

if __name__ == "__main__":
    main()
