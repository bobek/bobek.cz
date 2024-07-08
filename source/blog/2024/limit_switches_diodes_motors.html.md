---
title: DC Motors, Limit Switches, and Diodes
subtitle: simple reversible motor control with limit switches and diodes
category: making
date: 2024-07-08
---

Door for our chicken coop are controlled by an ESP8266 board running Tasmota. Tasmota allows for very simple configuration of timers as it supports sunrise and sunset based on timezone. The actual door movement is realized by a DC motor with string, which pulls up the door. Tasmota's [Sutters and Blinds](https://tasmota.github.io/docs/Blinds-and-Shutters/) feature. The motor is controlled by a simple H-bridge (initial version was using a cheap relays, but that turned unreliable, especially during winter). Standard configuration of blinds and shutters module uses time for defining how to get to fully open and fully closed position. This turned out to be unreliable, as motor has a gearbox and has a tendency to need slightly different time depending on the outside temperature. Also system is not able to easily recover from the manual intervention (aka somebody moved the door by hand).

We need to add limit switches to the system to be able to detect fully open and fully closed position. This will allow us to stop the motor when it reaches the limit. Signals from the switches can be wired back to GPIO pins on ESP8266 and Tasmota can be configured to stop the motor when the switch is activated. But there is way simpler solution using just two diodes.

![Schematics](motor.png) _Motor is somewhere in the middle of its travel_

Direction of the motor is controlled with the polarity of voltage on terminals `A` and `B`. Schematics captures moment, when doors are somewhere in the middle of the travel. Both switches are not activated, and they pass current as we have wired them in series using normally closed contacts (`NC`).

There are two possible states:

- `A` is positive and `B` is negative:

  - `D1` is reverse biased and blocks the current flow. But, the `SW1` has not been engaged, so flows through it. `D2` is forward biased and allows current to flow through it, but also `SW2` is not engaged, so it does not matter. Motor is running in one direction; towards `SW1`.

  - Moment they hit `SW1`, it opens, and the current stops flowing as `D1` blocks the current flow (remember `A` is positive). Motor stops.

- `A` is negative and `B` is positive -- we are moving in the opposite direction towards `SW2`:

  - `D1` is now forward biased and allows current to flow through it, bypassing `SW1`. `D2` is reverse biased, but it doesn't matter as `SW2` is closed. Motor is running in the opposite direction; towards `SW2`.
  - Moment they hit `SW2`, it opens, and the current stops flowing as `D2` blocks the current flow (remember `A` is negative). Motor stops.
