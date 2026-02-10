# 🔐 Secure API Key Setup Guide

This guide explains how to handle SilentWolf API keys securely for both local development and production deployment.

---

## 📋 Security Model

- **Local Development**: You manually replace placeholders with your real keys in `scripts/config.gd` (don't commit changes)
- **Production (GitHub Actions)**: Secrets are stored in GitHub and automatically injected during build
- **Git Safety**: `config.gd` WITH PLACEHOLDERS is committed - only commit if it has placeholders, never real keys

---

## 🏠 Local Development Setup

### Step 1: Get Your SilentWolf Credentials

1. Go to [https://silentwolf.com/](https://silentwolf.com/)
2. Sign in to your account
3. Find your game "NeonCatcher"
4. Copy your **API Key** and **Game ID**

### Step 2: Configure config.gd

1. Open `scripts/config.gd` in Godot or your text editor
2. Replace the placeholders:

```gdscript
# ❌ BEFORE (placeholders)
const SW_API_KEY: String = "SW_API_KEY_PLACEHOLDER"
const SW_GAME_ID: String = "SW_GAME_ID_PLACEHOLDER"

# ✅ AFTER (your real keys)
const SW_API_KEY: String = "API"
const SW_GAME_ID: String = "ID"
```

3. Save the file
4. **DON'T commit this change!** Keep it local only for development

### Step 3: Test Locally

1. Run your game in Godot
2. Check the Output console for:
   ```
   [Config] ✓ Credentials loaded
   [SilentWolfManager] ✓ Successfully configured!
   ```
3. If you see "PLACEHOLDER keys" warning, you forgot to replace them

---

## 🚀 Production Setup (GitHub Actions)

### Step 1: Add Secrets to GitHub Repository

1. Go to your GitHub repository: [https://github.com/Fuheshka/Neon-Catcher](https://github.com/Fuheshka/Neon-Catcher)
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add two secrets:

   **Secret 1:**
   - Name: `SILENTWOLF_API_KEY`
   - Value: `API` (your actual API key)
   
   **Secret 2:**
   - Name: `SILENTWOLF_GAME_ID`
   - Value: `ID` (your actual Game ID)

### Step 2: Verify Workflow Configuration

The `.github/workflows/deploy.yml` should have this step (already configured):

```yaml
- name: Inject SilentWolf API Keys
  run: |
    echo "🔐 Injecting SilentWolf API credentials..."
    sed -i 's/SW_API_KEY_PLACEHOLDER/${{ secrets.SILENTWOLF_API_KEY }}/g' scripts/config.gd
    sed -i 's/SW_GAME_ID_PLACEHOLDER/${{ secrets.SILENTWOLF_GAME_ID }}/g' scripts/config.gd
    echo "✓ API keys injected successfully"
```

### Step 3: Commit and Push

1. **Before committing**, make sure `config.gd` has PLACEHOLDERS (reset if you changed them locally):
   ```bash
   # Verify placeholders are present
   cat scripts/config.gd | grep PLACEHOLDER
   
   # If you see real keys instead, reset the file:
   git checkout scripts/config.gd
   ```

2. Commit your code:
   ```bash
   git add .
   git commit -m "feat: Add secure API key management"
   git push origin main
   ```

3. GitHub Actions will:
   - Check out your code
   - Replace placeholders with real secrets
   - Build the game
   - Deploy to GitHub Pages

### Step 4: Verify Deployment

1. Go to **Actions** tab in your GitHub repository
2. Watch the workflow run
3. Look for "🔐 Injecting SilentWolf API credentials..." in the logs
4. Once deployed, test your game at: [https://fuheshka.github.io/Neon-Catcher/](https://fuheshka.github.io/Neon-Catcher/)

---

## 🔍 Troubleshooting

### "Running with PLACEHOLDER keys!" Warning

**Problem**: You see this warning when running the game.

**Solution**:
- **Local dev**: Open `config.gd` and replace placeholders with real keys
- **GitHub Actions**: Check that secrets are added to repository settings

### Build Fails in GitHub Actions

**Problem**: GitHub Actions workflow fails during "Inject SilentWolf API Keys" step.

**Solution**:
1. Verify secrets are added: Settings → Secrets and variables → Actions
2. Check secret names are exactly: `SILENTWOLF_API_KEY` and `SILENTWOLF_GAME_ID`
3. Re-run the workflow from Actions tab

### Leaderboard Shows "Connection Failed"

**Problem**: Game loads but leaderboard can't connect.

**Solution**:
1. Open browser console (F12 → Console)
2. Look for errors:
   - "401 Unauthorized" = Wrong API key
   - "403 Forbidden" = Wrong Game ID or CORS issue
   - "404 Not Found" = Wrong endpoint or game doesn't exist
3. Verify secrets in GitHub match your SilentWolf dashboard

---

## 📁 File Structure

```
neon-catcher/
├── .github/
│   └── workflows/
│       └── deploy.yml          # ✅ Configured with sed commands
├── scripts/
│   ├── config.gd               # ✅ Committed with PLACEHOLDERS (replace locally, don't commit)
│   ├── config.gd.template      # ✅ Template reference (same as config.gd)
│   ├── SilentWolfManager.gd    # ✅ Checks for placeholders
│   └── ...
└── .gitignore                  # ℹ️ config.gd is NOT ignored (committed with placeholders)
```

---

## ✅ Security Checklist

- [ ] `config.gd` is committed with PLACEHOLDERS only
- [ ] Real keys are only in your local `config.gd` (not committed)
- [ ] GitHub secrets are added: `SILENTWOLF_API_KEY` and `SILENTWOLF_GAME_ID`
- [ ] `deploy.yml` has "Inject SilentWolf API Keys" step
- [ ] Team members know to replace placeholders locally (never commit real keys)
- [ ] `config.gd.template` exists as reference

---

## 🎯 Quick Commands

```bash
# Check if config.gd has placeholders (should show 2 lines)
grep "PLACEHOLDER" scripts/config.gd

# Reset config.gd to placeholders before commit
git checkout scripts/config.gd

# View GitHub Actions logs
# Go to: https://github.com/Fuheshka/Neon-Catcher/actions

# Force re-run latest workflow
gh workflow run deploy.yml  # requires GitHub CLI
```

---

## 📚 Additional Resources

- [SilentWolf Documentation](https://silentwolf.com/docs)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Godot Web Export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
