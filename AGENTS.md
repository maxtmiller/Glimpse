# Perch developer notes

## Build and install a release locally

Use Xcode’s toolchain when building on macOS:

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
CONFIGURATION=release ./scripts/bundle-macos-app.sh
```

This creates `.build/Perch.app` and opens it. Test the app before packaging it. To install the tested build:

```bash
rm -rf /Applications/Perch.app
cp -R .build/Perch.app /Applications/Perch.app
open /Applications/Perch.app
```

If an older release was still named `Notch`, remove `/Applications/Notch.app` before launching Perch. Check for leftover processes with:

```bash
ps axo pid,comm,args | grep -Ei '[n]otch|[p]erch'
```

## Create an unsigned DMG

After testing `.build/Perch.app`:

```bash
rm -rf .build/Perch-dmg
mkdir -p .build/Perch-dmg
cp -R .build/Perch.app .build/Perch-dmg/
ln -s /Applications .build/Perch-dmg/Applications
hdiutil create \
  -volname "Perch" \
  -srcfolder .build/Perch-dmg \
  -ov \
  -format UDZO \
  Perch.dmg
hdiutil verify Perch.dmg
```

`Perch.dmg` is ignored by Git. Upload it as an asset when creating the GitHub release.

## Publish a release

Commit and push source changes, then create a GitHub release with the matching version tag and upload `Perch.dmg`:

```bash
git add -A
git commit -m "Prepare Perch 1.0.1 release"
git push origin main
```

The current unsigned-release note should tell users to open the installed app by Control-clicking `Perch.app`, choosing **Open**, and confirming the macOS security prompt. Update the version, tag, and commit message for future releases.
