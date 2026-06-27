<!-- markdownlint-disable MD032 MD033-->
# Project AudittAnimus

<p align="left">
  <img width="100%" src="https://i.imgur.com/xFCDTkc.png" alt="@Josee9988/project-template's">
  <br>
  <a href="https://github.com/LeonelMachado-Dev/Project_AUDITTANIMUS/issues">
	<img src="https://img.shields.io/github/issues/LeonelMachado-Dev/Project_AUDITTANIMUS?color=0088ff&style=for-the-badge&logo=github" alt="AudittAnimus issues"/>
  </a>
  <a href="https://github.com/LeonelMachado-Dev/Project_AUDITTANIMUS/pulls">
	<img src="https://img.shields.io/github/issues-pr/LeonelMachado-Dev/Project_AUDITTANIMUS?color=0088ff&style=for-the-badge&logo=github" alt="@LeonelMachado-Dev pull requests"/>
  </a>
</p>

---
## DISCLAIMER!!

THIS IS A NON-PROFIT, FAN-MADE PROJECT CREATED FOR FANS WHO APPRECIATE THE ASSASSIN'S CREED 2 ANIMUS INTERFACE. ALL ASSETS, FILES, AND INTELLECTUAL PROPERTY FROM THE ORIGINAL GAME BELONG STRICTLY TO UBISOFT ENTERTAINMENT. NO COPYRIGHT INFRINGEMENT IS INTENDED.

---

## 🤔 **What is AudittAnimus?**

AudittAnimus is a database visualizer designed to store and manage subjects, locations, and user memories. The system is completely inspired by the Animus 2.0 from Assassin's Creed 2, featuring the unforgettable white background with the plexus effect, moving data blocks in the menus, among other iconic visual elements.

The main application was built entirely in Godot and is accompanied by a web client that allows users to view the database from other devices on the same local network. This client was developed in Python using the Flask and Tkinter libraries.

Currently, the project is in an early stage of development. However, I will be working as hard as possible to deliver the smoothest and most pleasant experience.

It will surely bring back all the nostalgia!

Please note that this is a non-profit project, created solely to revive that mysterious and captivating feeling of the Animus that allowed us to connect with Ezio Auditore.

Hope you enjoy it!

---

## 💻 **Minimum Requeriments 🖥️**

* OS: Windows 10 (22H2 or higher) or Windows 11
* CPU: Intel Core i3 (5th generation)
* Memory: 2 GB RAM
* Graphics: Intel HD Graphics 4400 (or better)
* Storage: 300 MB available on space.
* A 1280x768 screen resolution.

---

## 📝 **What’s Inside**

* User's subjects, favorite locations, and memories (Basically, a local cloud...)
* Web client to look at the database from other devices, just if they are in the same local network.
* Assassin's Creed 2 Atmosphere and customizable background music
* Supports touchpad gestures. Controller support coming soon!
* Powered by SQLite for database management.
* Multi-Language Support! (English and Spanish for now...)

---

## 📸 **Screenshots**

A couple of screenshots to delight you... Soon!

### 🔺 Main Menu

<p align="center">
  <img width="70%" height="70%" src="https://i.imgur.com/dDMnDvO.png" alt="Main Menu">
</p>

### 🔻 Subjects Screen

<p align="center">
  <img width="70%" height="70%" src="https://i.imgur.com/gc1lkht.png" alt="The subjects screen">
</p>

---

## ⚡ **Installation**

Step 1. Download the latest release and run the AudittAnimus.exe file.

Step 2. Enjoy ✨

---

### 🌲 **Project tree**

This is the current folders structure.

```text
.
└── Project_AUDITTANIMUS/
	├── .editorconfig
	├── .gitattributes
	├── .gitignore
	├── adn_animus.gdshader
	├── adn_animus.gdshader.uid
	├── AnimusADN.gdshader
	├── AnimusADN.gdshader.uid
	├── DatabaseManager.gd
	├── DatabaseManager.gd.uid
	├── default_bus_layout.tres
	├── DetallesSujeto.tscn
	├── detalles_sujeto.gd
	├── detalles_sujeto.gd.uid
	├── Documentacion.txt
	├── entrada_sujeto.gd
	├── entrada_sujeto.gd.uid
	├── entrada_sujeto.tscn
	├── Global.gd
	├── Global.gd.uid
	├── icon.svg
	├── icon.svg.import
	├── LICENSE
	├── main.gd
	├── main.gd.uid
	├── main.gdshader
	├── main.gdshader.uid
	├── main.tscn
	├── main_menu.gd
	├── main_menu.gd.uid
	├── main_menu.tscn
	├── main_menu_Documentation.txt
	├── MemoryGrid.gdshader
	├── MemoryGrid.gdshader.uid
	├── memoryLines.gdshader
	├── memoryLines.gdshader.uid
	├── musica_global.tscn
	├── neblina_animus.gdshader
	├── neblina_animus.gdshader.uid
	├── plexus_system.gd
	├── plexus_system.gd.uid
	├── project.godot
	├── README.md
	├── some codes to use later.txt
	├── subject_editor.gd
	├── subject_editor.gd.uid
	├── subject_editor.tscn
	├── data/
	│   └── animus_data.db
	├── music/
	│   ├── animus2.0_theme.mp3
	│   ├── animus2.0_theme.mp3.import
	│   ├── Click-sound-AC2-Soundtrack.mp3
	│   ├── Click-sound-AC2-Soundtrack.mp3.import
	│   ├── Glitch effect 6.mp3
	│   └── Glitch effect 6.mp3.import
	├── addons/
	│   └── godot-sqlite/
	│       ├── gdsqlite.gdextension
	│       ├── gdsqlite.gdextension.uid
	│       ├── godot-sqlite.gd
	│       ├── godot-sqlite.gd.uid
	│       ├── LICENSE.md
	│       ├── plugin.cfg
	│       └── bin/
	│           ├── libgdsqlite.android.template_debug.arm64.so
	│           ├── libgdsqlite.android.template_debug.x86_64.so
	│           ├── libgdsqlite.android.template_release.arm64.so
	│           ├── libgdsqlite.android.template_release.x86_64.so
	│           ├── libgdsqlite.ios.template_debug.arm64.dylib
	│           ├── libgdsqlite.ios.template_release.arm64.dylib
	│           ├── libgdsqlite.linux.template_debug.x86_64.so
	│           ├── libgdsqlite.linux.template_release.x86_64.so
	│           ├── libgdsqlite.web.template_debug.wasm32.nothreads.wasm
	│           ├── libgdsqlite.web.template_debug.wasm32.wasm
	│           ├── libgdsqlite.web.template_release.wasm32.nothreads.wasm
	│           ├── libgdsqlite.web.template_release.wasm32.wasm
	│           ├── libgdsqlite.windows.template_debug.x86_64.dll
	│           ├── libgdsqlite.windows.template_release.x86_64.dll
	│           ├── ~libgdsqlite.windows.template_debug.x86_64.dll
	│           ├── libgdsqlite.ios.template_debug.xcframework/
	│           │   ├── Info.plist
	│           │   ├── ios-arm64/
	│           │   │   └── libgdsqlite.ios.template_debug.a
	│           │   └── ios-arm64_x86_64-simulator/
	│           │       └── libgdsqlite.ios.template_debug.simulator.a
	│           ├── libgdsqlite.ios.template_release.xcframework/
	│           │   ├── Info.plist
	│           │   ├── ios-arm64/
	│           │   │   └── libgdsqlite.ios.template_release.a
	│           │   └── ios-arm64_x86_64-simulator/
	│           │       └── libgdsqlite.ios.template_release.simulator.a
	│           ├── libgdsqlite.macos.template_debug.framework/
	│           │   ├── libgdsqlite.macos.template_debug
	│           │   ├── libmacos.libgdsqlite.template_debug
	│           │   └── Resources/
	│           │       └── Info.plist
	│           ├── libgdsqlite.macos.template_release.framework/
	│           │   ├── libgdsqlite.macos.template_release
	│           │   ├── libmacos.libgdsqlite.template_release
	│           │   └── Resources/
	│           │       └── Info.plist
	│           ├── libgodot-cpp.ios.template_debug.xcframework/
	│           │   ├── Info.plist
	│           │   ├── ios-arm64/
	│           │   │   └── libgodot-cpp.ios.template_debug.arm64.a
	│           │   └── ios-arm64_x86_64-simulator/
	│           │       └── libgodot-cpp.ios.template_debug.universal.simulator.a
	│           └── libgodot-cpp.ios.template_release.xcframework/
	│               ├── Info.plist
	│               ├── ios-arm64/
	│               │   └── libgodot-cpp.ios.template_release.arm64.a
	│               └── ios-arm64_x86_64-simulator/
	│                   └── libgodot-cpp.ios.template_release.universal.simulator.a
	└── Images/
		└── TEST SUBJECTS/
			├── no_foto.png
			└── no_foto.png.import

*This will change often during his development
```

---

Enjoy! 😃
