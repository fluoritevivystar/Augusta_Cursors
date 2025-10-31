## 🧭 Branch Workflow Guide

Hey! Here’s how we’re managing the repo branches so things stay clean and organized.
We’re using two main branches: main and nightly.

## 🌿 Branch Purposes

### main branch

Always stable and release-ready.
This is what users will download or use.
No broken or experimental stuff here (in future).

### nightly branch

This is our workbench for testing and adding new things.
It can be messy or unfinished — totally fine.
Once something’s confirmed working, we’ll merge it into main.

## 🔄 How to Work Properly

1. Do all work on the nightly branch
```
git checkout nightly
# make your changes
git add .
git commit -m "Describe your change here"
git push origin nightly
```

2. When we’re happy with changes, merge into main
```
git checkout main
git merge nightly
git push origin main
```

3. (Optional but good)
We can tag versions when we release updates:
```
git tag v1.0
git push origin v1.0
```
## 👥 Collaboration Rules

We both work on the nightly branch.

We use pull requests when merging nightly → main.

Before merging, we test everything to make sure it’s stable.

If main ever changes (like bug fixes), we can pull those into nightly to stay up to date:
```
git checkout nightly
git merge main
```
## ⚠️ Important Notes

✅ Always pull before you start working:
```
git pull origin nightly
```

❌ Don’t push experimental stuff directly to main.
✅ Only merge to main when we’re sure it’s working.

## 🌙 Future Idea (Optional)

Later on, we can set up GitHub Actions to automatically create a “Nightly Build” whenever nightly updates.
That way, users can test the latest features easily.

</br></br>
Definitely not made using AI 😏
