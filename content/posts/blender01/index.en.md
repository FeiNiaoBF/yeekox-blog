---
aliases:
  - /blog/blender01/
title: "Turning Blender Into a Hobby"
date: 2025-03-07T19:18:10+08:00
draft: false
authors:
  - name: "Yeelight"
    link: https://github.com/FeiNiaoBF
    image: https://github.com/FeiNiaoBF.png

math: false
toc: true
comments: true
tags:
  - Blender
  - 3D Modeling
  - Tutorial
---

## Building a Foundation

  <!--more-->
- **Download and Install Blender**
  - Grab the latest version from the official site (free and open-source). Stick with the **Long-Term Support (LTS)** release for stability.

- **First Encounter — Don't Panic**
  - Open Blender and check out the built-in **Quick Start tutorial** (on the splash screen or in the Help menu).
  - Goal: get familiar with the basic layout — 3D Viewport, Timeline, Properties panel, etc.

- **Memorize 3 Core Shortcuts**
  - `G` (move objects), `S` (scale), `R` (rotate)
  - `Tab` to toggle between Object Mode and Edit Mode
  - Middle-mouse drag to rotate view, `Shift + middle click` to pan

## Keyboard Shortcuts

### 1. Basic Operations

1. **Move / Rotate / Scale**
    - `G`: Move selected object
    - `R`: Rotate selected object
    - `S`: Scale selected object
    - Press `X/Y/Z` to lock to an axis (e.g. `G → X` moves along the X axis)
2. **Selection and Deletion**
    - `A`: Select all / deselect all (press `A` twice)
    - `B`: Box select, `C`: Circle select
    - `X` or `Delete`: Delete selected object
    - `Shift + D`: Duplicate object
3. **Mode Switching**
    - `Tab`: Toggle between Object Mode and Edit Mode
    - `Ctrl + Tab`: Switch between vertex/edge/face selection modes (in Edit Mode)

---

### 2. Viewport Control

1. **View Navigation**
    - Middle-mouse drag: Rotate view
    - `Shift + middle mouse`: Pan view
    - Scroll wheel: Zoom view
2. **Quick View Switching**
    - Numpad `1`: Front view, `3`: Right view, `7`: Top view
    - Numpad `0`: Camera view
    - `/`: Focus on selected object and hide everything else
3. **Viewport Display**
    - `Z`: Toggle wireframe / solid / rendered shading
    - `Alt + Z`: Toggle perspective / orthographic view

---

### 3. Modeling & Editing

1. **Basic Modeling Tools**
    - `E`: Extrude selected elements (faces / edges / vertices)
    - `Ctrl + R`: Loop cut (scroll wheel to increase number of cuts)
    - `Ctrl + B`: Bevel edges or vertices
2. **Edit Mode Operations**
    - `Alt + left-click an edge`: Select edge loop
    - `F`: Fill a face from selected edges
    - `M`: Merge vertices or edges
3. **Advanced Operations**
    - `Shift + S`: Snap menu (align to cursor / grid, etc.)
    - `Alt + G/S/R`: Reset object location / scale / rotation

---

### 4. Animation & Rendering

- `I`: Insert keyframe (location / rotation / scale)
- `Alt + A`: Play / pause animation
- `F12`: Render the current scene

---

### 5. UI & Efficiency

- `N`: Show / hide the right-side properties panel
- `T`: Show / hide the left-side tools panel
- `Ctrl + Space`: Maximize current window
- `Shift + Space`: Quick tool menu
- `Q`: Quick Favorites (customize your frequently used tools)

---

## Getting to Know the Interface

**Top Bar**

**3D Viewport**

- **View operations**:
  - Middle-mouse drag to rotate view
  - `Shift + middle click` to pan view
  - `Ctrl + middle click` or scroll wheel to zoom
- **Mode switching**:
  - Object Mode / Edit Mode (`Tab` to toggle)
  - Sculpt Mode / Weight Paint, etc.

**Timeline**

- **Core features**:
  - Animation keyframe management (press `I` to insert keyframes)
  - Playback controls (Space to play/pause)
  - Frame range settings (set animation start and end frames)

**Properties Panel**

- **Core features**: 9 functional modules (switch via icons):

1. Scene Properties: Global render settings
2. Object Properties: Location / rotation / dimensions
3. Modifiers: Add and manage modifiers
4. Particle Systems
5. Physics: Simulate fluids, cloth, etc.
6. Object Data: Mesh / curve data
7. Material Properties
8. Texture Properties
9. Render Properties

## Cursor and Origin Points

## Render Engines

[【Kurt】Blender Beginner Tutorial | Essential Series for Chinese Learners (Finished)](https://www.bilibili.com/video/BV14u41147YH/?p=5&t=888)

## My First Project

![Pearl Girl](https://s2.loli.net/2025/03/07/bFjAyNwX75s462d.png)


## Cursor and Origin Points

Blender has two easily confused "centers":

| Concept | Icon | Purpose |
|------|------|------|
| **3D Cursor** | 🎯 Red-white circle | Where new objects spawn; rotation/scaling pivot point |
| **Object Origin** | 🟡 Orange dot | The zero point of an object's own coordinate system |

**Cursor operations**:
- `Shift + Right-click`: Move cursor to mouse position
- `Shift + S`: Open cursor menu (Cursor → Selected / Cursor → World Origin / Selected → Cursor, etc.)

**Why the cursor matters?**
New objects always appear at the cursor position. Before you start modeling, make it a habit to press `Shift + C` (cursor back to world origin).

## Render Engines: Eevee vs Cycles

Blender comes with two built-in render engines. Choose based on your needs:

| | Eevee | Cycles |
|------|-------|--------|
| **Type** | Real-time renderer (rasterization) | Physically-based renderer (ray tracing) |
| **Speed** | 🚀 Extremely fast, near-instant | 🐢 Slow, needs sampling |
| **Quality** | Good enough, lighting is "faked" | Photorealistic lighting and shadows |
| **Use cases** | Animation previews, low-end machines, stylized art | Final renders, product shots, realistic art |
| **Where to set** | Properties → Render Properties → Render Engine | Same |

Beginner tip: Use Eevee while practicing — it's fast and gives immediate feedback. Switch to Cycles when you want a "cinematic" result.

## My First Project

![Pearl Girl](https://s2.loli.net/2025/03/07/bFjAyNwX75s462d.png)

This was my first 3D piece, following Kurt's tutorial. It's rough around the edges, but I walked through all the key steps:

1. Build the character structure from basic primitives
2. Sculpt facial contours in Sculpt Mode
3. Apply materials and lighting
4. Render the final image with Eevee

It felt pretty rewarding once it was done — starting from a cube and slowly shaping it into a person.

Blender's learning curve is steep, no doubt, but the key is to **finish your first thing first**. Even if it looks terrible, going through the whole pipeline once teaches you more than watching ten tutorials.
