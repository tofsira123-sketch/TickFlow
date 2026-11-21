#!/usr/bin/env python3
"""Configure generated Android platform files for TickFlow on GitHub Actions."""

import re
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ANDROID_APP = ROOT / "android" / "app"
MANIFEST = ANDROID_APP / "src" / "main" / "AndroidManifest.xml"
RES_DIR = ANDROID_APP / "src" / "main" / "res"
ICONS_SRC = ROOT / "assets" / "android_icons"


def patch_manifest() -> None:
    text = MANIFEST.read_text(encoding="utf-8")

    # Set display name to TickFlow
    text = re.sub(r'android:label="[^"]*"', 'android:label="TickFlow"', text, count=1)

    permissions = [
        '    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>',
        '    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>',
        '    <uses-permission android:name="android.permission.VIBRATE"/>',
    ]
    missing = [p for p in permissions if p.strip() not in text]
    if missing:
        block = "\n".join(missing) + "\n\n    <application"
        text = text.replace("<application", block, 1)

    MANIFEST.write_text(text, encoding="utf-8")
    print("Patched AndroidManifest.xml with TickFlow label and notification permissions.")


def patch_gradle() -> None:
    kts_path = ANDROID_APP / "build.gradle.kts"
    groovy_path = ANDROID_APP / "build.gradle"

    if kts_path.exists():
        text = kts_path.read_text(encoding="utf-8")

        # Ensure compileSdk = 35 for flutter_local_notifications
        text = re.sub(r"compileSdk\s*=\s*flutter\.compileSdkVersion", "compileSdk = 35", text)

        # Enable core library desugaring in compileOptions
        if "isCoreLibraryDesugaringEnabled" not in text:
            text = text.replace(
                "compileOptions {",
                "compileOptions {\n        isCoreLibraryDesugaringEnabled = true",
                1,
            )

        # Enable multiDex in defaultConfig
        if "multiDexEnabled" not in text:
            text = text.replace(
                "defaultConfig {",
                "defaultConfig {\n        multiDexEnabled = true",
                1,
            )

        # Append desugaring dependency
        if "desugar_jdk_libs" not in text:
            text += (
                "\ndependencies {\n"
                '    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")\n'
                "}\n"
            )

        kts_path.write_text(text, encoding="utf-8")
        print("Patched android/app/build.gradle.kts (compileSdk=35, desugaring, multiDex).")

    elif groovy_path.exists():
        text = groovy_path.read_text(encoding="utf-8")

        text = re.sub(r"compileSdk\s*=?\s*flutter\.compileSdkVersion", "compileSdk = 35", text)
        text = re.sub(r"compileSdkVersion\s+flutter\.compileSdkVersion", "compileSdkVersion 35", text)

        if "coreLibraryDesugaringEnabled" not in text:
            text = text.replace(
                "compileOptions {",
                "compileOptions {\n        coreLibraryDesugaringEnabled true",
                1,
            )

        if "multiDexEnabled" not in text:
            text = text.replace(
                "defaultConfig {",
                "defaultConfig {\n        multiDexEnabled true",
                1,
            )

        if "desugar_jdk_libs" not in text:
            text += (
                "\ndependencies {\n"
                "    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'\n"
                "}\n"
            )

        groovy_path.write_text(text, encoding="utf-8")
        print("Patched android/app/build.gradle (compileSdk=35, desugaring, multiDex).")
    else:
        raise FileNotFoundError("Neither build.gradle.kts nor build.gradle found in android/app/")


def copy_icons() -> None:
    if not ICONS_SRC.exists():
        print("Warning: assets/android_icons not found.")
        return

    count = 0
    for mipmap_dir in ICONS_SRC.iterdir():
        if mipmap_dir.is_dir():
            dest_dir = RES_DIR / mipmap_dir.name
            dest_dir.mkdir(parents=True, exist_ok=True)
            for icon_file in mipmap_dir.glob("*.png"):
                shutil.copy2(icon_file, dest_dir / icon_file.name)
                count += 1
    print(f"Copied {count} TickFlow launcher icon files into android/app/src/main/res/.")


if __name__ == "__main__":
    patch_manifest()
    patch_gradle()
    copy_icons()
    print("Android configuration for TickFlow complete!")
