# Zero Budget

A zero-based budgeting app built with Flutter. Plan your month before you
spend it, so that every euro gets a job.

## Why Zero Budget?

Most budgeting apps track spending: they show you where your money went
after it's gone. Zero Budget is meant to work the other way around. You
**plan first, then spend**.

The idea is **zero-based budgeting**. At the start of each month, you give
every euro of your income a job until nothing is left unassigned. Each euro
goes to rent, groceries, a holiday fund or savings. Your income minus
everything you've assigned comes out to exactly zero. Then you lock in your
plan and track your spending against it for the rest of the month.

This turns your budget into a tool for reaching your goals. You decide up
front what matters to you, both what you spend and what you save. The app
then helps you stick to that.

Spending is entered **manually** for now. Pulling transactions from your bank
automatically is complicated, and entering expenses by hand keeps you aware
of where your money goes.

Zero Budget is also a personal project that was **largely vibe coded**. Most
of the code was written by an AI coding assistant from descriptions of how
the app should work, then tried out and refined step by step. It started as
a quick way to get the app I wanted, without writing every line by hand.

### Features

- **Monthly plan:** add your incomes and assign all of it to budgets. The
  plan can only be locked in once every euro has a job. Whatever is left at
  the end of a month carries over to the next one.
- **Step-by-step planning:** a guided walk through your income, giving, the
  essentials (rent, utilities, groceries and transportation), savings and
  everything else.
- **Budget types:**
  - **Everyday budgets**, like groceries or fun, are tracked as you spend.
  - **Fixed costs**, like rent, count as spent in full once the plan is
    locked in.
  - **Sinking funds** save up over several months for costs that don't come
    every month, like a yearly insurance fee.
- **Categories:** each budget is for giving, an essential, savings or
  something else, and shows it as a tag. Savings budgets count towards your
  savings goal. Budgets are listed by category, from A to Z, or in an order
  you drag them into.
- **New months:** a few days before a month starts, the app offers to plan
  it. The new month starts as a copy of the last one: you pick which budgets
  to keep, then plan step by step or adjust the plan directly.
- **Tracking:** add expenses with one tap. You can see what's left to spend
  overall and in each budget, and a diagram shows where your money goes.
- **Savings goal:** set a goal per quarter or per year, and watch a plant
  grow as you put money aside.
- **History and notes:** look back at past months, and keep notes on goals
  or things to take care of.
- **Bank balance check:** shows what should be in your bank account right
  now, including a safety buffer you choose.
- **Currency:** amounts are in euro by default. You can switch to US
  dollars, British pounds or Swiss francs in the settings.

All data stays on your device, in a local SQLite database.

## Download

Get the APK for Android from the
[Releases page](https://github.com/Techthy/zero_budget/releases):

- **Latest release:** the stable version, recommended for everyday use.
- **Nightly:** the newest build with the latest changes, but possibly with
  bugs.

Both install over each other and keep your data. To get updates
automatically, add the repository's URL to
[Obtainium](https://github.com/ImranR98/Obtainium). It can follow either
stable releases only, or include the nightly builds too.

## Getting started

### Requirements

- [Flutter](https://docs.flutter.dev/get-started/install) 3.47 or newer,
  which includes Dart 3.13
- For Android: the Android SDK, installed with
  [Android Studio](https://developer.android.com/studio) or the command-line
  tools
- For Linux desktop: the
  [Linux desktop dependencies](https://docs.flutter.dev/platform-integration/linux/setup)
  (`clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev`)

To check your setup, run `flutter doctor`.

### Run the app

```sh
git clone https://github.com/Techthy/zero_budget.git
cd zero_budget
flutter pub get
flutter run            # pick a device, or e.g. `flutter run -d linux`
```

To see which devices are available, run `flutter devices`. In debug builds a
**debug bar** at the top lets you move through days and months, to try out
how the app behaves when a new month starts. You can hide it in the settings.

### Build

| Platform      | Command                                     | Output                                          |
| ------------- | ------------------------------------------- | ----------------------------------------------- |
| Android (APK) | `flutter build apk --release`               | `build/app/outputs/flutter-apk/app-release.apk` |
| Linux         | `flutter build linux --release`             | `build/linux/x64/release/bundle/`               |
| Web           | `flutter build web --release`               | `build/web/`                                    |
| Windows       | `flutter build windows --release`           | `build\windows\x64\runner\Release\`             |
| macOS / iOS   | `flutter build macos` / `flutter build ios` | needs a Mac with Xcode                          |

## Build and install the Android APK

1. **Build the APK:**

   ```sh
   flutter build apk --release
   ```

   This creates `build/app/outputs/flutter-apk/app-release.apk`. If you want
   smaller files, `flutter build apk --split-per-abi` builds one APK per
   processor type instead. Most current phones need the `arm64-v8a` one.

2. **Install it on your phone.** You can do this in either of two ways.

   **Over USB:**
   1. On the phone, turn on
      [Developer options and USB debugging](https://developer.android.com/studio/debug/dev-options).
   2. Connect the phone, then run:

      ```sh
      flutter install        # or: adb install build/app/outputs/flutter-apk/app-release.apk
      ```

   **Without a cable:**
   1. Copy the APK to the phone, for example over a cloud drive, email or a
      USB file transfer.
   2. Open it on the phone. Android asks you to allow installing apps from
      that source. Allow it, then confirm the install.

> **Note on signing:** without a release key (see
> [Releases and nightly builds](#releases-and-nightly-builds)), your local
> builds are signed with Flutter's debug key. That's fine for trying the app
> out. Android only installs an update when it's signed with the same key as
> the installed app, though. So to switch between your own builds and the
> published ones, you'd have to uninstall first, which deletes the app's
> data.

## Releases and nightly builds

A [GitHub Actions workflow](.github/workflows/android.yml) builds the app at
three levels:

| Trigger                   | What happens                                                                                     |
| ------------------------- | ------------------------------------------------------------------------------------------------ |
| Pull request              | Analyze, test and build. The APK is attached to the run under **Artifacts**.                     |
| Push to `master`          | The same checks, then the **Nightly** pre-release is replaced with the new build.                |
| Version tag like `v1.2.0` | The same checks, then a **stable release** with release notes is published and marked as latest. |

Nightly and stable builds are the same app, signed with the same key. They
install as updates of each other and keep your data. Each build uses the
workflow's run number as its version code, so a newer build always replaces
an older one.

### Publishing a release

1. Set the new version in `pubspec.yaml`, for example `version: 1.2.0`, and
   commit it.
2. Tag the commit and push the tag:

   ```sh
   git tag v1.2.0
   git push origin v1.2.0
   ```

The workflow checks that the tag matches the version in `pubspec.yaml`.
Nightlies are named after the next release, for example `1.2.0-nightly.57`.
The nightly pre-release shows that version in its title, and the app shows
its own version under **Settings → About**.

### Setting up the release key (once)

Published builds are signed with a release key that's stored as a GitHub
secret. Until it's set up, the workflow still builds, but it publishes
nothing.

> [!WARNING]
> Keep the key and its password safe, and back them up somewhere outside this
> computer. If you lose them, you can never publish an update again. Users
> would have to uninstall the app and lose their data to switch to a new key.
> Never commit the key to git.

1. Create the key. `keytool` comes with Java; choose a strong password when
   it asks for one.

   ```sh
   keytool -genkeypair -v -keystore ~/zero-budget-release.jks \
     -keyalg RSA -keysize 4096 -validity 10000 -alias zero-budget
   ```

2. Add it to the repository's secrets, either with the
   [GitHub CLI](https://cli.github.com/) or under **Settings → Secrets and
   variables → Actions**:

   ```sh
   base64 -w0 ~/zero-budget-release.jks | gh secret set ANDROID_KEYSTORE
   gh secret set ANDROID_KEYSTORE_PASSWORD   # asks for the password
   gh secret set ANDROID_KEY_ALIAS --body zero-budget
   ```

3. To sign your local builds with the same key, create
   `android/key.properties`. It's ignored by git.

   ```properties
   storeFile=/home/you/zero-budget-release.jks
   storePassword=your password
   keyAlias=zero-budget
   keyPassword=your password
   ```

   Then `flutter build apk --release` produces APKs that update the published
   ones and the other way round.

## Contributing

Contributions are welcome, whether bug reports, ideas or pull requests.

Since the app was largely vibe coded, expect some rough edges in the code.
Code reviews, refactorings and more tests are especially welcome. If you use
AI tools for your own changes too, please read and test the result before
opening a pull request.

1. Fork the repository and create a branch for your change.
2. Make your change. Before opening a pull request, check:

   ```sh
   flutter analyze
   flutter test test/database_test.dart
   ```

3. Open a pull request that describes what you changed and why.

### Code generation

The database ([drift](https://drift.simonbinder.eu/)) and the state
management ([Riverpod](https://riverpod.dev/)) use generated code: the
`*.drift.dart` and `*.g.dart` files. Whenever you change a table or a
`@riverpod` provider, regenerate the code:

```sh
dart run build_runner build       # once
dart run build_runner watch       # or keep it running while you work
```

### Changing the database

If you change a table, increase `schemaVersion` in
[lib/data/database.dart](lib/data/database.dart). Then add a migration step
for it to `onUpgrade`, so existing users keep their data. The upgrade tests
in [test/database_test.dart](test/database_test.dart) open databases from
every earlier schema version. When you add a new version, add it to those
tests too.

### Project structure

```text
lib/
  *.dart      the app, its home screen, and helpers for money, dates and
              sorting budgets
  data/       database tables, queries and migrations (drift)
  welcome/    the Plan tab: incomes, budgets, step-by-step planning,
              setting up a new month, locking the plan in
  spending/   the Track tab and adding expenses
  savings/    the savings goal and its growing plant
  history/    past months
  settings/   settings, like the buffer and the currency, and the about
              section
  widgets/    shared widgets, like the money flow diagram and the new month
              card
  theme/      colours, text styles and shapes of the design system
  debug/      the debug bar for moving through days and months
assets/icon/  the app icon and logo
```

### App icon

The launcher icons are generated from
[assets/icon/icon.png](assets/icon/icon.png). On Android, the adaptive icon
uses [assets/icon/icon_adaptive.png](assets/icon/icon_adaptive.png). After
you change either image, run:

```sh
dart run flutter_launcher_icons
```

## License

Zero Budget is released under the [MIT License](LICENSE). You're free to
use, change and share it. It comes without any warranty, and the authors
aren't liable for anything that results from using it. In particular, Zero
Budget is not financial advice.
