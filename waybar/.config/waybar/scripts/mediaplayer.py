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
from typing import List, Dict, Optional, Set
import weakref

# Configure a null handler by default to avoid "No handler found" warnings
logging.getLogger(__name__).addHandler(logging.NullHandler())
logger = logging.getLogger(__name__)

class PlayerManager:
    def __init__(self, selected_player=None, excluded_player=None):
        self.manager = Playerctl.PlayerManager()
        self.loop = GLib.MainLoop()
        
        # Setup signal handlers with proper cleanup
        self.manager.connect("name-appeared", self.on_player_appeared)
        self.manager.connect("player-vanished", self.on_player_vanished)
        
        # Store configuration
        self.selected_player = selected_player
        self.excluded_player = excluded_player.split(',') if excluded_player else []
        
        # Track active players and current player with signal handlers
        self.players: Dict[str, Player] = {}
        self.player_signals: Dict[str, List[int]] = {}  # Track signal handler IDs
        self.current_player_name: Optional[str] = None
        self._cleanup_scheduled = False
        
        # Setup cleanup signal handlers
        self._setup_signal_handlers()
        
        # Initialize existing players
        self.init_players()

    def _setup_signal_handlers(self):
        """Setup proper signal handlers with cleanup"""
        def cleanup_and_exit(sig, frame):
            logger.info(f"Received signal {sig} to stop, cleaning up")
            self.cleanup_all_players()
            sys.stdout.write("\n")
            sys.stdout.flush()
            self.loop.quit()
            sys.exit(0)
        
        signal.signal(signal.SIGINT, cleanup_and_exit)
        signal.signal(signal.SIGTERM, cleanup_and_exit)
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)

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
        try:
            self.loop.run()
        except KeyboardInterrupt:
            logger.info("Keyboard interrupt received")
        finally:
            self.cleanup_all_players()

    def init_player(self, player):
        """Initialize a new player and connect signals"""
        player_name = player.name
        logger.info(f"Initialize new player: {player_name}")
        
        # Skip if already managing this player
        if player_name in self.players:
            logger.debug(f"Player {player_name} already managed, skipping")
            return
        
        try:
            # Create player instance and connect signals
            player_instance = Playerctl.Player.new_from_name(player)
            
            # Connect signals and track handler IDs for proper cleanup
            signal_ids = []
            signal_ids.append(player_instance.connect("playback-status", self.on_playback_status_changed))
            signal_ids.append(player_instance.connect("metadata", self.on_metadata_changed))
            
            # Keep track of this player and its signal handlers
            self.players[player_name] = player_instance
            self.player_signals[player_name] = signal_ids
            
            # Register with manager
            self.manager.manage_player(player_instance)
            
            # Initial metadata update
            self.on_metadata_changed(player_instance, player_instance.props.metadata)
            
        except Exception as e:
            logger.error(f"Failed to initialize player {player_name}: {e}")

    def cleanup_player(self, player_name: str):
        """Properly cleanup a specific player"""
        if player_name not in self.players:
            return
            
        logger.info(f"Cleaning up player: {player_name}")
        player_instance = self.players[player_name]
        
        try:
            # Disconnect all signal handlers
            if player_name in self.player_signals:
                for signal_id in self.player_signals[player_name]:
                    try:
                        player_instance.disconnect(signal_id)
                    except Exception as e:
                        logger.debug(f"Error disconnecting signal {signal_id}: {e}")
                del self.player_signals[player_name]
            
            # Unmanage from PlayerManager
            try:
                self.manager.unmanage_player(player_instance)
            except Exception as e:
                logger.debug(f"Error unmanaging player {player_name}: {e}")
            
            # Remove from our tracking
            del self.players[player_name]
            
        except Exception as e:
            logger.error(f"Error during cleanup of player {player_name}: {e}")

    def cleanup_all_players(self):
        """Cleanup all managed players"""
        if self._cleanup_scheduled:
            return
        self._cleanup_scheduled = True
        
        logger.info("Cleaning up all players")
        player_names = list(self.players.keys())
        for player_name in player_names:
            self.cleanup_player(player_name)
        
        # Clear any remaining references
        self.players.clear()
        self.player_signals.clear()
        self.current_player_name = None

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
            try:
                if player.props.status == "Playing":
                    return player
            except Exception as e:
                logger.debug(f"Error checking status for player: {e}")
                continue
                
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
            try:
                self.on_metadata_changed(current_player, current_player.props.metadata)
            except Exception as e:
                logger.debug(f"Error updating display: {e}")
                self.clear_output()
        else:
            # No players to display
            self.current_player_name = None
            self.clear_output()

    def on_metadata_changed(self, player, metadata, _=None):
        """Handle metadata changes for a player"""
        try:
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
        except Exception as e:
            logger.debug(f"Error in metadata changed handler: {e}")

    def format_track_info(self, player, metadata) -> str:
        """Format track information for display"""
        try:
            player_name = player.props.player_name
            artist = player.get_artist()
            title = player.get_title()
            
            # Format the track info
            track_info = ""
            if player_name == "spotify" and metadata and "mpris:trackid" in metadata.keys() and ":ad:" in metadata["mpris:trackid"]:
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
        except Exception as e:
            logger.debug(f"Error formatting track info: {e}")
            return ""

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
        
        # Proper cleanup of the vanished player
        self.cleanup_player(player_name)
            
        # If this was our current player, find a new one
        if player_name == self.current_player_name:
            self.current_player_name = None
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
    player_manager = None
    try:
        player_manager = PlayerManager(arguments.player, arguments.exclude)
        player_manager.run()
    except Exception as e:
        logger.error(f"Error in main: {e}")
    finally:
        if player_manager:
            player_manager.cleanup_all_players()

if __name__ == "__main__":
    main()