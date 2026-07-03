# Plan: Fix Git Repository for LifeTracker Flutter Project

## Problem
Git repository is corrupted with old/incorrect remote URL in `.git/config` causing "fatal: repository 'https://github.com' not found" error. Standard git commands are ignored due to VS Code process locking or caching.

## Solution Steps
1. **Remove .git folder completely** using Windows PowerShell `Remove-Item -Path .git -Recurse -Force`
2. **Initialize new git repository** with `git init`
3. **Add all project files** with `git add .`
4. **Create initial commit** with `git commit -m "Initial commit"`
5. **Set correct remote origin** with `git remote add origin https://github.com/donyor-mahmudovv/life-tracker.git`
6. **Force push to main branch** with `git push --force origin main`

## Single Command for PowerShell
```
Remove-Item -Path .git -Recurse -Force -ErrorAction SilentlyContinue; git init; git add .; git commit -m "Initial commit"; git remote add origin https://github.com/donyor-mahmudovv/life-tracker.git; git push --force origin main
```

## Notes
- This command removes all git history (intentional for fresh start)
- Requires PowerShell terminal (not CMD)
- May require admin privileges if files are locked
- Remote repository must exist at https://github.com/donyor-mahmudovv/life-tracker.git
