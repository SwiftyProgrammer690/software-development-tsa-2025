# 2152-901 Software Development HS

Hello judges! This is our entire codebase for software development! We have made this document so that it is easier to navigate our github! Before we get into it, we first want to thank you for your time and your service, it truly means a lot to us competitors!

## File Organization and Navigation

```
lib/
  main.dart                       App entry point, theme, color blind filters
  screens/
    home_screen.dart              Dashboard and navigation
    captions_screen.dart          Live speech-to-text (hearing)
    alerts_screen.dart            Haptic and visual alerts (hearing)
    scene_reader_screen.dart      Camera OCR + text-to-speech (vision)
    notes_screen.dart             Spoken notes with TTS playback (vision)
    onboarding_screen.dart        First-launch walkthrough
    about_screen.dart             Project info and tech details
  services/
    native_vibration.dart         Platform channel to Android vibration API

android/app/src/main/kotlin/
  MainActivity.kt                 Native vibration implementation

```

Since we used Flutter to make our apps, it creates a lot of other junk and build files. Most of the other folders and directories are mainly just build files and other system junk that don't have actual code/raw binary in them. The ones we listed above are the ones that are the most important!

## Where to start reading

First, navigate your way to [here!](https://github.com/SwiftyProgrammer690/software-development-tsa-2025/tree/main/lib)

Start with `main.dart`, it sets up the app theme, color blind simulation filters, and high contrast mode. From there, `home_screen.dart` shows how screens are structured and navigated. (You will have to go through the different directories in the lib folder!)

Each screen is self-contained and independently readable. The most technically interesting files are `captions_screen.dart` (speech recognition loop), `alerts_screen.dart` (animation + native platform channel), and `scene_reader_screen.dart` (MLKit OCR pipeline).

----------

## Comments

Every file includes inline comments explaining the reasoning behind key decisions, not just what the code does. We also added comments so its easier for us and other judges or people who read our code to understand what our code does!

----------

## Have any questions?

We would love to answer them during our preliminary round when we meet you in person!

----------

## That's all!

We hope you like our creation, and we also hope that you have a wonderful time at the PA TSA state conference this year!

From Team 2152-901

![Pennsylvania Technology Student Association](https://patsa.org/assets/images/patsa_logo.png)
