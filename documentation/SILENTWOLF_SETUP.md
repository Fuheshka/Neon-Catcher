# SilentWolf Online Leaderboard - Setup Guide

## Overview
This guide covers the complete setup for integrating SilentWolf's online leaderboard into your Neon Catcher game.

## Files Created/Modified

### New Files:
- **`scripts/OnlineLeaderboard.gd`** - Bridge between game logic and SilentWolf API
  - Handles score posting with error handling
  - Fetches top scores from the online leaderboard
  - Emits signals for UI integration

### Modified Files:
- **`scripts/RegistrationScreen.gd`** - Score submission UI
  - Added status label for feedback
  - Integrated online score posting with loading states
  - Fallback to local storage on network errors

- **`scripts/LeaderboardUI.gd`** - Leaderboard display
  - Fetches and displays online scores
  - Shows connection status
  - Fallback to local leaderboard on errors

## Required Scene Updates

### 1. RegistrationScreen.tscn
Open `scenes/RegistrationScreen.tscn` in Godot Editor and add:

**Add StatusLabel:**
1. Select the `Panel/VBoxContainer` node
2. Add a new child node: `Label`
3. Rename it to `StatusLabel`
4. Configure the label:
   - Text: (leave empty)
   - Horizontal Alignment: Center
   - Modulate: Yellow (or any color)
   - Visible: false (will be shown when needed)

### 2. LeaderboardUI.tscn
Open `scenes/LeaderboardUI.tscn` in Godot Editor and add:

**Add StatusLabel:**
1. Select the `Panel/VBoxContainer` node
2. Add a new child node: `Label`
3. Rename it to `StatusLabel`
4. Position it below the TitleLabel
5. Configure the label:
   - Text: (leave empty)
   - Horizontal Alignment: Center
   - Modulate: Yellow
   - Visible: false

## SilentWolf Configuration

### Step 1: Get Your API Credentials
1. Visit https://silentwolf.com/
2. Sign up or login to your account
3. Create a new game project
4. Copy your **API Key** and **Game ID**

### Step 2: Configure SilentWolf in Your Game

**Option A: Edit SilentWolf.gd directly (Not Recommended)**
Modify `/addons/silent_wolf/SilentWolf.gd`:
```gdscript
var config = {
	"api_key": "YOUR_ACTUAL_API_KEY_HERE",
	"game_id": "YOUR_ACTUAL_GAME_ID_HERE",
	"log_level": 1
}
```

**Option B: Configure from Game Code (Recommended)**
Add this to your main game initialization (e.g., in `scripts/game_manager.gd` or main menu):

```gdscript
func _ready() -> void:
	# Configure SilentWolf
	SilentWolf.configure({
		"api_key": "YOUR_ACTUAL_API_KEY_HERE",
		"game_id": "YOUR_ACTUAL_GAME_ID_HERE",
		"log_level": 1
	})
```

**Option C: Use Environment Variables (Best for Web Builds)**
Create a configuration script:

```gdscript
# scripts/config.gd
extends Node

const SW_API_KEY = "YOUR_API_KEY"
const SW_GAME_ID = "YOUR_GAME_ID"

func _ready():
	SilentWolf.configure({
		"api_key": SW_API_KEY,
		"game_id": SW_GAME_ID,
		"log_level": 1
	})
```

## Testing

### Local Testing:
1. Run the game in Godot Editor
2. Play until you get a high score
3. Enter a nickname
4. Watch the console for:
   - "Posting score to SilentWolf: [name] - [score]"
   - "Score posted successfully!"

### Check the Leaderboard:
1. Open the leaderboard in-game
2. You should see "Loading leaderboard..." briefly
3. Scores should appear from the online database

### Error Checking:
If you see errors like:
- "SilentWolf API Key not configured!" → Update your API credentials
- "Network error" → Check internet connection or API limits
- "Failed to post score" → Verify API key and game ID are correct

## Architecture & Features

### Signals Used:
**OnlineLeaderboard.gd:**
- `score_post_completed(success: bool, error_message: String)`
- `leaderboard_received(scores: Array[Dictionary])`
- `leaderboard_error(error_message: String)`

**RegistrationScreen.gd:**
- `nickname_submitted(success: bool)` - Updated to include success status

### Error Handling:
- ✅ Network failures fallback to local leaderboard
- ✅ Invalid credentials are detected and reported
- ✅ User sees clear status messages
- ✅ Game continues even if online service fails

### User Feedback:
- **Loading States:** Buttons disabled during submission
- **Status Messages:** Color-coded feedback (Yellow=Loading, Green=Success, Orange=Fallback, Red=Error)
- **Graceful Degradation:** Always saves locally even if online fails

## Web Platform Considerations

For web builds, ensure:
1. Enable CORS on your SilentWolf backend
2. The web export includes the `enable_coi.js` script (already present in your web/ folder)
3. Test in actual browser environment, not just editor

### Web Build HTTPS Requirements:
SilentWolf API requires HTTPS. If testing locally:
- Use `python -m http.server --bind localhost 8000` (HTTP only works for localhost)
- For production, deploy to HTTPS-enabled hosting

## Best Practices Implemented

✅ **Strict Static Typing:** All functions use `: void`, `: int`, `: String`, etc.
✅ **Signal-Based Communication:** No direct node dependencies
✅ **Error Handling:** All API calls have error callbacks
✅ **Timeout Handling:** Built into SilentWolf HTTP requests
✅ **Fallback System:** Local storage ensures no data loss
✅ **Loading States:** Users see clear feedback during network operations

## Troubleshooting

### Problem: "SilentWolf autoload not found"
**Solution:** Ensure SilentWolf plugin is enabled in Project Settings → Plugins

### Problem: Scores not appearing online
**Solution:** 
1. Check API credentials are correct
2. Verify internet connection
3. Check SilentWolf dashboard for rate limits
4. Look at console for specific error messages

### Problem: "Request timeout"
**Solution:** 
- Slow connection or SilentWolf API is down
- Local scores will still be saved
- Try again later

### Problem: StatusLabel node not found
**Solution:** Add the StatusLabel to both scene files as described above

## Next Steps

1. **Test thoroughly** in both editor and exported builds
2. **Monitor** the SilentWolf dashboard for player scores
3. **Customize** the status messages and colors to match your game's theme
4. **Consider** adding player authentication for more features
5. **Implement** additional SilentWolf features (player profiles, achievements, etc.)

## API Reference

### OnlineLeaderboard.gd Methods:
```gdscript
post_score_online(player_name: String, score: int) -> void
get_top_scores(limit: int = 10) -> void
is_web_platform() -> bool
```

### SilentWolf Score Format:
```gdscript
{
	"player_name": String,
	"score": int,
	"score_id": String,
	"created_at": String (ISO timestamp),
	"metadata": Dictionary (optional)
}
```

## Support

- **SilentWolf Documentation:** https://silentwolf.com/docs
- **SilentWolf Discord:** https://discord.gg/silentwolf
- **Godot 4.6 Docs:** https://docs.godotengine.org/en/4.6/

---

**Implementation Complete!** 🎉
Your game now has a fully functional online leaderboard with robust error handling and user feedback.
