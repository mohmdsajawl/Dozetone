package com.velcruxlab.dozetone

import com.ryanheise.audioservice.AudioServiceActivity

/**
 * MainActivity for Dozetone.
 * Inherits from AudioServiceActivity to properly bridge background
 * media controls, notification actions, and lock screen callbacks.
 */
class MainActivity : AudioServiceActivity()
