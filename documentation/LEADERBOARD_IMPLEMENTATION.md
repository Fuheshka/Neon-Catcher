# Leaderboard System Implementation Guide

## Overview
A complete Local Leaderboard system with Top 10 scores and nickname input has been implemented for your Godot 4.6 game.

## Components Created

### 1. LeaderboardManager (AutoLoad Singleton)
**File:** `scripts/LeaderboardManager.gd`

**Features:**
- Stores top 10 scores with player nicknames
- Data structure: `Array[Dictionary]` with `{"name": String, "score": int}`
- Persistent storage using JSON file at `user://leaderboard.json`

**Key Functions:**
- `is_high_score(score: int) -> bool` - Checks if a score qualifies for Top 10
- `add_score(nickname: String, score: int)` - Adds entry, sorts descending, keeps only top 10
- `save_leaderboard()` - Saves data to disk
- `load_leaderboard()` - Loads data from disk
- `get_leaderboard() -> Array[Dictionary]` - Returns full leaderboard
- `clear_leaderboard()` - Clears all entries

**Signals:**
- `leaderboard_updated()` - Emitted when leaderboard changes

### 2. RegistrationScreen
**Files:** 
- `scenes/RegistrationScreen.tscn`
- `scripts/RegistrationScreen.gd`

**Features:**
- Overlay that appears after Game Over IF the player achieved a high score
- LineEdit for nickname input (automatically limited to 12 characters)
- Confirm button to submit score
- Validates nickname (defaults to "Anonymous" if empty)
- Can submit with Enter key or button click

**Signals:**
- `nickname_submitted()` - Emitted when player submits their nickname

### 3. LeaderboardUI
**Files:**
- `scenes/LeaderboardUI.tscn`
- `scripts/LeaderboardUI.gd`

**Features:**
- ScrollContainer with VBoxContainer for displaying entries
- Dynamically creates rows for each leaderboard entry
- Shows rank, name, and score for each entry
- Displays "No scores yet!" message when empty
- Close button to dismiss the leaderboard
- Automatically refreshes when leaderboard updates

**Signals:**
- `closed()` - Emitted when player closes the leaderboard

### 4. LeaderboardRow
**File:** `scenes/LeaderboardRow.tscn`

**Features:**
- Reusable scene for displaying a single leaderboard entry
- Shows: Rank number, Player name, Score
- Consistent styling across all entries

## Integration

### GameOverScreen Updates
**File:** `scripts/GameOverScreen.gd`

**Changes:**
- Now checks if the player's score qualifies for the leaderboard
- If high score: Shows RegistrationScreen for nickname input
- If not high score: Shows regular Game Over screen
- After nickname submission: Shows full leaderboard
- Added "View Leaderboard" button to Game Over screen
- Proper flow management between screens

### UI Scene Updates
**File:** `scenes/ui.tscn`

**Changes:**
- Added RegistrationScreen instance
- Added LeaderboardUI instance
- Added "View Leaderboard" button to Game Over screen
- Both new screens set to `process_mode = 2` (work when paused)

### Main Menu Updates
**Files:**
- `scenes/main_menu.tscn`
- `scripts/MainMenu.gd`

**Changes:**
- Added "Leaderboard" button
- Instantiates LeaderboardUI scene
- Players can view leaderboard from main menu

### Project Configuration
**File:** `project.godot`

**Changes:**
- Added LeaderboardManager as AutoLoad singleton
- Path: `*res://scripts/LeaderboardManager.gd`

## User Flow

### When Player Gets High Score:
1. Game ends → `game_over` signal fires
2. GameOverScreen checks if score is high enough
3. If yes → RegistrationScreen appears
4. Player enters nickname (max 12 chars)
5. Player clicks "Confirm" or presses Enter
6. Score added to leaderboard and saved
7. LeaderboardUI displays with updated scores
8. Player closes leaderboard
9. Regular Game Over screen appears with options

### When Player Gets Normal Score:
1. Game ends → `game_over` signal fires
2. GameOverScreen checks if score is high enough
3. If no → Regular Game Over screen appears
4. Player can click "View Leaderboard" to see top scores
5. Player can Restart or Quit

### From Main Menu:
1. Player clicks "Leaderboard" button
2. LeaderboardUI displays current top 10
3. Player closes leaderboard
4. Returns to main menu

## Data Persistence

**Storage Location:** `user://leaderboard.json`

**Platform Paths:**
- **Windows:** `%APPDATA%\Godot\app_userdata\[ProjectName]\leaderboard.json`
- **macOS:** `~/Library/Application Support/Godot/app_userdata/[ProjectName]/leaderboard.json`
- **Linux:** `~/.local/share/godot/app_userdata/[ProjectName]/leaderboard.json`

**Format:**
```json
[
  {"name": "PlayerOne", "score": 9999},
  {"name": "PlayerTwo", "score": 8888},
  ...
]
```

## Testing Checklist

- [ ] Play game and check if high score triggers RegistrationScreen
- [ ] Enter nickname and verify it appears in leaderboard
- [ ] Test with scores that don't qualify (should show normal Game Over)
- [ ] Verify leaderboard keeps only top 10 scores
- [ ] Test "View Leaderboard" button from Game Over screen
- [ ] Test "Leaderboard" button from Main Menu
- [ ] Verify nickname length limit (12 characters)
- [ ] Test empty nickname (should default to "Anonymous")
- [ ] Verify data persists between game sessions
- [ ] Test with less than 10 scores (all should qualify as high scores)

## Customization Options

### Styling
- Edit the scene files to adjust colors, fonts, and sizes
- Modify `LeaderboardRow.tscn` for different row layouts
- Update panel sizes in `RegistrationScreen.tscn` and `LeaderboardUI.tscn`

### Configuration
In `LeaderboardManager.gd`:
- Change `MAX_ENTRIES` constant to store more/fewer scores
- Modify `LEADERBOARD_FILE` path for different save location

### Nickname Validation
In `RegistrationScreen.gd` `_submit_score()`:
- Add profanity filter
- Enforce minimum length
- Add character restrictions

## Notes

- All leaderboard screens work when game is paused (process_mode = 2)
- Leaderboard automatically loads on game start
- Scores are sorted in descending order (highest first)
- Empty leaderboard message appears when no scores exist
- System is fully compatible with web exports

## Future Enhancements

- Add online leaderboards with backend integration  
- Add filters (daily, weekly, all-time)
- Show player's rank in real-time during gameplay
- Add animations when score enters leaderboard
- Show which score position player achieved
- Add player avatars or icons
- Export/import leaderboard data
