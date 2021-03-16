<div align="center">
  <img src="https://i.ibb.co/2Wq0495/ic-launcher.png" width="100" height="100"/>

  <h1 align="center">notatod</h1>
</div>

<p align="center">
  <img src="https://images.unsplash.com/photo-1505968409348-bd000797c92e?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=800&q=80"/>
</p>

<p align="center">
  <a href="#"><img alt="bintray" src="https://badgen.net/badge/macOS/10.15/blue?icon=apple"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/badge/License-Apache%202.0-blue.svg"></a>
  <a href="https://github.com/utsmannn/notatod/pulls"><img alt="Pull request" src="https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat"></a>
  <a href="https://twitter.com/utsmannn"><img alt="Twitter" src="https://img.shields.io/twitter/follow/utsmannn"></a>
  <a href="https://github.com/utsmannn"><img alt="Github" src="https://img.shields.io/github/followers/utsmannn?label=follow&style=social"></a>
  <p align="center">Simple note application popover on your MacOS<br>Run in menubar and build with SwiftUI</p>
</p>

|dark theme|light theme|
|---|---|
|![](images/img1.png)|![](images/img2.png)|

|drive account connected|note file in drive|
|---|---|
|![](images/img3.png)|![](images/img4.png)|

## Compatibility
- This app work with 10.15 (Catalina) or later
- Work with Intel arch x86_64
- Work with Apple Silicon M1

## Download
Go to [release page](https://github.com/utsmannn/notatod/releases) and download *.dmg asset of the latest release
```
Version 1.1.0-alpha-4 (latest version)
- Add Dropbox Integration
- Add new route (/v1) for feature update api
- Fix editor in High Sierra

Version 1.1.0-alpha-3
- Add keyboard shortcut
- Add window when app open
- Add Google OAuth2 performance

Version 1.1.0-alpha-2
- Add backward compability until Catalina
- Add resize popover window
- Enable google drive sync (internal tester)
- Change icon to Fluent Icon by Microsoft
- Add about page
- Fix updater API

Version 1.0.0-alpha-1
- First release with DMG installer
```

- [Privacy Policy](https://utsmannn.github.io/notatod/privacy-policy)
- [Terms & Conditions](https://utsmannn.github.io/notatod/terms-and-conditions)

## Feature
- [x] Simple editor
- [x] Font size customizable
- [x] Preferences menu
- [x] Simple ui
- [x] Synchronized with Google Drive (internal testing)
- [x] Add Dropbox API for Google Drive API alternative
- [x] Keyboard shortcut

## Roadmap
- [ ] Signing code and validate app for macos
- [ ] Enable launch at login
- [ ] Image inserting
- [ ] Code highlighter
- [ ] Mobile client support

## Build with
- Swift
- SwiftUI
- AppCode + XCode
- MVVM Clean Arch
- Google Drive API (REST)
- Dropbox API (REST)
- KeyboardShortcuts (by [Sindre Sorhus](https://github.com/sindresorhus/KeyboardShortcuts))
- Kotlin Ktor for updater API

## License
```
Copyright 2021 Muhammad Utsman

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
