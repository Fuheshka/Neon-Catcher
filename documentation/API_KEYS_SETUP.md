# API Keys Setup (Secret Configuration)

## For Developers

The `scripts/config.gd` file contains confidential API keys and **is NOT committed to Git**.

### Initial Setup:

1. **Copy the template:**
   ```bash
   cp scripts/config.gd.example scripts/config.gd
   ```

2. **Get SilentWolf credentials:**
   - Open https://silentwolf.com/
   - Sign up or log in
   - Create a new project
   - Copy your **API Key** and **Game ID**

3. **Replace in `scripts/config.gd`:**
   ```gdscript
   const SW_API_KEY: String = "your_actual_api_key"
   const SW_GAME_ID: String = "your_game_id"
   ```

4. **Done!** Keys will be automatically loaded when the game starts.

### Security:

✅ `scripts/config.gd` is added to `.gitignore`  
✅ Your keys won't end up in the repository  
✅ Each developer uses their own keys  
✅ Template `config.gd.example` can be safely committed  

### For New Team Members:

When cloning the repository:
```bash
git clone <repository>
cd neon-catcher
cp scripts/config.gd.example scripts/config.gd
# Edit scripts/config.gd and add your keys
```

### Verification:

Run the game - you should see in the console:
```
✓ SilentWolf configured with game_id: YOUR_GAME_ID
```

If you see warning "⚠️ SilentWolf credentials not configured!" - you need to configure `config.gd`.

## For Production (Game Export)

When exporting the game, keys from `config.gd` will be included in the `.pck` file.  
This is normal - in client-side games keys are visible to users.  
SilentWolf is protected by other mechanisms (rate limiting, CORS).
