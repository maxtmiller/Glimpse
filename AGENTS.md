# Glimpse developer notes

## Build and install a release locally

Use Xcode’s toolchain when building on macOS:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
CONFIGURATION=release ./scripts/bundle-macos-app.sh
```

This creates `.build/Glimpse.app` and opens it. Test the app before packaging it. To install the tested build:

```bash
rm -rf /Applications/Glimpse.app
cp -R .build/Glimpse.app /Applications/Glimpse.app
open /Applications/Glimpse.app
```

If an older installation remains, remove `/Applications/Glimpse.app` before launching Glimpse. Check for leftover processes with:

```bash
ps axo pid,comm,args | grep -Ei '[n]otch|[p]erch'
```

## Create an unsigned DMG

After testing `.build/Glimpse.app`:

```bash
rm -rf .build/Glimpse-dmg
mkdir -p .build/Glimpse-dmg
cp -R .build/Glimpse.app .build/Glimpse-dmg/
ln -s /Applications .build/Glimpse-dmg/Applications
hdiutil create \
  -volname "Glimpse" \
  -srcfolder .build/Glimpse-dmg \
  -ov \
  -format UDZO \
  Glimpse.dmg
hdiutil verify Glimpse.dmg
```

`Glimpse.dmg` is ignored by Git. Upload it as an asset when creating the GitHub release.

## Publish a release

Commit and push source changes, then create a GitHub release with the matching version tag and upload `Glimpse.dmg`:

```bash
git add -A
git commit -m "Prepare Glimpse 1.0.1 release"
git push origin main
```

The current unsigned-release note should tell users to open the installed app by Control-clicking `Glimpse.app`, choosing **Open**, and confirming the macOS security prompt. Update the version, tag, and commit message for future releases.
