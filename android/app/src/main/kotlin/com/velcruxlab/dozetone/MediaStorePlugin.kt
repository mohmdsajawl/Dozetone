package com.velcruxlab.dozetone

import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.graphics.Bitmap
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Native Android MediaStore query and management plugin.
 *
 * Implements direct Android MediaStore queries and scoped storage file deletion
 * and rename through ContentResolver and MediaStore createWriteRequest / createDeleteRequest.
 */
class MediaStorePlugin(private val activity: Activity) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.velcruxlab.dozetone/media_store"
        const val DELETE_REQUEST_CODE = 4041
        const val RENAME_REQUEST_CODE = 4042

        fun registerWith(flutterEngine: FlutterEngine, activity: Activity): MediaStorePlugin {
            val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            val plugin = MediaStorePlugin(activity)
            channel.setMethodCallHandler(plugin)
            return plugin
        }
    }

    private val scope = CoroutineScope(Dispatchers.Main)
    private var pendingDeleteResult: MethodChannel.Result? = null

    fun handleActivityResult(requestCode: Int, resultCode: Int) {
        if (requestCode == DELETE_REQUEST_CODE) {
            val success = (resultCode == Activity.RESULT_OK)
            pendingDeleteResult?.success(success)
            pendingDeleteResult = null
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "querySongs" -> {
                val excludeWhatsapp = call.argument<Boolean>("excludeWhatsapp") ?: true
                scope.launch {
                    try {
                        val songs = withContext(Dispatchers.IO) { loadSongs(excludeWhatsapp) }
                        result.success(songs)
                    } catch (e: Exception) {
                        result.error("MEDIA_STORE_ERROR", e.message, null)
                    }
                }
            }
            "queryArtwork" -> {
                val songId = (call.argument<Number>("songId"))?.toLong() ?: 0L
                val albumId = (call.argument<Number>("albumId"))?.toLong() ?: 0L
                val dataUri = call.argument<String>("dataUri") ?: ""
                scope.launch {
                    try {
                        val bytes = withContext(Dispatchers.IO) { loadArtwork(songId, albumId, dataUri) }
                        result.success(bytes)
                    } catch (_: Exception) {
                        result.success(null)
                    }
                }
            }
            "deleteSong" -> {
                val songId = (call.argument<Number>("songId"))?.toLong() ?: 0L
                val dataUri = call.argument<String>("dataUri") ?: ""
                deleteSong(songId, dataUri, result)
            }
            "renameSong" -> {
                val songId = (call.argument<Number>("songId"))?.toLong() ?: 0L
                val dataUri = call.argument<String>("dataUri") ?: ""
                val newTitle = call.argument<String>("newTitle") ?: ""
                renameSong(songId, dataUri, newTitle, result)
            }
            else -> result.notImplemented()
        }
    }

    private fun deleteSong(songId: Long, dataUri: String, result: MethodChannel.Result) {
        // Step 1: Try deleting physical file directly
        if (dataUri.isNotEmpty()) {
            try {
                val file = File(dataUri)
                if (file.exists() && file.delete()) {
                    val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, songId)
                    activity.contentResolver.delete(uri, null, null)
                    result.success(true)
                    return
                }
            } catch (_: Exception) {
            }
        }

        // Step 2: Try direct ContentResolver deletion
        val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, songId)
        try {
            val count = activity.contentResolver.delete(uri, null, null)
            if (count > 0) {
                result.success(true)
                return
            }
        } catch (se: SecurityException) {
            // Step 3: On Android 11+ (API 30+), Scoped Storage requires system consent for other apps' files
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try {
                    val pendingIntent = MediaStore.createDeleteRequest(
                        activity.contentResolver,
                        listOf(uri)
                    )
                    pendingDeleteResult = result
                    activity.startIntentSenderForResult(
                        pendingIntent.intentSender,
                        DELETE_REQUEST_CODE,
                        null,
                        0,
                        0,
                        0
                    )
                    return
                } catch (_: Exception) {
                }
            }
        } catch (_: Exception) {
        }

        result.success(false)
    }

    private fun renameSong(songId: Long, dataUri: String, newTitle: String, result: MethodChannel.Result) {
        if (newTitle.trim().isEmpty()) {
            result.success(false)
            return
        }

        scope.launch {
            val success = withContext(Dispatchers.IO) {
                performRename(songId, dataUri, newTitle.trim())
            }
            result.success(success)
        }
    }

    private fun performRename(songId: Long, dataUri: String, newTitle: String): Boolean {
        var renamed = false

        // Step 1: Try physical file rename if accessible and permitted
        if (dataUri.isNotEmpty()) {
            try {
                val file = File(dataUri)
                if (file.exists() && file.canWrite()) {
                    val ext = file.extension
                    val newFileName = if (ext.isNotEmpty()) "$newTitle.$ext" else newTitle
                    val parent = file.parentFile
                    if (parent != null) {
                        val target = File(parent, newFileName)
                        if (!target.exists() && file.renameTo(target)) {
                            renamed = true
                        }
                    }
                }
            } catch (_: Exception) {
            }
        }

        // Step 2: Try MediaStore entry update
        try {
            val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, songId)
            val values = ContentValues().apply {
                put(MediaStore.Audio.Media.TITLE, newTitle)
            }
            val count = activity.contentResolver.update(uri, values, null, null)
            if (count > 0) {
                renamed = true
            }
        } catch (_: Exception) {
        }

        return renamed
    }

    private fun isExcludedAudio(data: String): Boolean {
        if (data.isBlank()) return false
        val normalized = data.lowercase().replace('\\', '/')
        if (normalized.contains("/whatsapp/") ||
            normalized.contains("/com.whatsapp") ||
            normalized.contains("/whatsapp audio/") ||
            normalized.contains("/whatsapp voice notes/") ||
            normalized.contains("/voice notes/") ||
            normalized.contains("/voicenotes/") ||
            normalized.contains("/telegram/telegram audio/") ||
            normalized.contains("/callrecordings/") ||
            normalized.contains("/call_rec/") ||
            normalized.contains("/soundrecorder/")) {
            return true
        }
        val fileName = normalized.substringAfterLast('/')
        if ((fileName.startsWith("aud-") || fileName.startsWith("ptt-")) && fileName.contains("-wa")) {
            return true
        }
        return false
    }

    private fun loadSongs(excludeWhatsapp: Boolean = true): List<Map<String, Any?>> {
        val songList = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.ALBUM_ID,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.DATA,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.IS_RINGTONE,
            MediaStore.Audio.Media.IS_NOTIFICATION,
            MediaStore.Audio.Media.IS_ALARM
        )

        // Filter: audio files >= 30 seconds (30000 ms)
        val selection = "${MediaStore.Audio.Media.DURATION} >= 30000"
        val sortOrder = "${MediaStore.Audio.Media.TITLE} COLLATE NOCASE ASC"
        val uri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI

        activity.contentResolver.query(uri, projection, selection, null, sortOrder)?.use { cursor ->
            val idCol = cursor.getColumnIndex(MediaStore.Audio.Media._ID)
            val titleCol = cursor.getColumnIndex(MediaStore.Audio.Media.TITLE)
            val artistCol = cursor.getColumnIndex(MediaStore.Audio.Media.ARTIST)
            val albumCol = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM)
            val albumIdCol = cursor.getColumnIndex(MediaStore.Audio.Media.ALBUM_ID)
            val durationCol = cursor.getColumnIndex(MediaStore.Audio.Media.DURATION)
            val dataCol = cursor.getColumnIndex(MediaStore.Audio.Media.DATA)
            val sizeCol = cursor.getColumnIndex(MediaStore.Audio.Media.SIZE)
            val dateAddedCol = cursor.getColumnIndex(MediaStore.Audio.Media.DATE_ADDED)
            val isRingtoneCol = cursor.getColumnIndex(MediaStore.Audio.Media.IS_RINGTONE)
            val isNotificationCol = cursor.getColumnIndex(MediaStore.Audio.Media.IS_NOTIFICATION)
            val isAlarmCol = cursor.getColumnIndex(MediaStore.Audio.Media.IS_ALARM)

            while (cursor.moveToNext()) {
                // Filter out ringtones, notifications, and alarms
                if (isRingtoneCol != -1 && cursor.getInt(isRingtoneCol) != 0) continue
                if (isNotificationCol != -1 && cursor.getInt(isNotificationCol) != 0) continue
                if (isAlarmCol != -1 && cursor.getInt(isAlarmCol) != 0) continue

                val data = if (dataCol != -1) cursor.getString(dataCol) ?: "" else ""
                if (excludeWhatsapp && isExcludedAudio(data)) continue

                val id = if (idCol != -1) cursor.getLong(idCol) else 0L
                val rawTitle = if (titleCol != -1) cursor.getString(titleCol) else null
                val rawArtist = if (artistCol != -1) cursor.getString(artistCol) else null
                val album = if (albumCol != -1) cursor.getString(albumCol) else null
                val albumId = if (albumIdCol != -1) cursor.getLong(albumIdCol) else 0L
                val duration = if (durationCol != -1) cursor.getLong(durationCol) else 0L
                val size = if (sizeCol != -1) cursor.getLong(sizeCol) else 0L
                val dateAdded = if (dateAddedCol != -1) cursor.getLong(dateAddedCol) else 0L

                var title = if (!rawTitle.isNullOrBlank()) rawTitle.trim() else "Unknown Title"
                var artist = if (!rawArtist.isNullOrBlank() && rawArtist != "<unknown>") {
                    rawArtist.trim()
                } else {
                    "Unknown Artist"
                }

                // If artist is unknown and title follows standard "Artist - Track" convention
                if (artist == "Unknown Artist" && title.contains(" - ")) {
                    val parts = title.split(" - ", limit = 2)
                    if (parts[0].trim().isNotEmpty() && parts[1].trim().isNotEmpty()) {
                        artist = parts[0].trim()
                        title = parts[1].trim()
                    }
                }

                val songMap = mapOf<String, Any?>(
                    "id" to id,
                    "title" to title,
                    "artist" to artist,
                    "album" to album,
                    "albumId" to albumId,
                    "duration" to duration,
                    "dataUri" to data,
                    "size" to size,
                    "dateAdded" to dateAdded
                )
                songList.add(songMap)
            }
        }
        return songList
    }

    private fun loadArtwork(songId: Long, albumId: Long, dataUriParam: String): ByteArray? {
        var dataUri = dataUriParam

        // Resolve dataUri from MediaStore if not provided
        if (dataUri.isBlank() && songId > 0) {
            try {
                val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, songId)
                val proj = arrayOf(MediaStore.Audio.Media.DATA)
                activity.contentResolver.query(uri, proj, null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        dataUri = cursor.getString(0) ?: ""
                    }
                }
            } catch (_: Exception) {
            }
        }

        // Tier 1: Direct Container ID3 Extraction via MediaMetadataRetriever
        // Reads genuine embedded APIC/PIC frame directly from the physical audio file
        if (dataUri.isNotBlank()) {
            try {
                val file = File(dataUri)
                if (file.exists() && file.canRead()) {
                    val retriever = android.media.MediaMetadataRetriever()
                    retriever.setDataSource(file.absolutePath)
                    val embeddedArt = retriever.embeddedPicture
                    retriever.release()
                    if (embeddedArt != null && embeddedArt.isNotEmpty()) {
                        return embeddedArt
                    }
                }
            } catch (_: Exception) {
            }
        }

        // Tier 2: Dedicated Album Folder Art (Whitelisted standard filenames, non-shared folders)
        if (dataUri.isNotBlank()) {
            try {
                val file = File(dataUri)
                val parent = file.parentFile
                if (parent != null && parent.exists() && parent.isDirectory) {
                    val parentName = parent.name.lowercase()
                    // Never inspect generic shared folders where unrelated downloads/images bleed
                    val isSharedFolder = parentName == "download" ||
                            parentName == "downloads" ||
                            parentName == "whatsapp" ||
                            parentName == "telegram" ||
                            parentName == "bluetooth" ||
                            parentName == "0" ||
                            parentName == "sdcard"

                    if (!isSharedFolder) {
                        val candidates = arrayOf("cover.jpg", "cover.png", "folder.jpg", "albumart.jpg", "front.jpg")
                        for (candidate in candidates) {
                            val candidateFile = File(parent, candidate)
                            if (candidateFile.exists() && candidateFile.isFile && candidateFile.length() > 0) {
                                return candidateFile.readBytes()
                            }
                        }
                    }
                }
            } catch (_: Exception) {
            }
        }

        // Tier 3: Return null to allow clean procedural vector fallback.
        // NOTE: We deliberately do NOT query MediaStore albumart table because of Android's
        // documented folder-pollution cache bug.
        return null
    }
}
