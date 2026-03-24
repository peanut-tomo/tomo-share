package com.tomo.share.tomo_share

import android.content.ClipData
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.core.content.FileProvider
import java.io.File
import java.io.FileNotFoundException
import java.net.URLConnection
import java.util.Locale
import android.webkit.MimeTypeMap
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class TomoSharePlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context

    private val telegramPackages = listOf(
        "org.telegram.messenger",
        "org.thunderdog.challegram",
    )

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "tomo_share")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "shareTelegram" -> shareTelegram(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun shareTelegram(call: MethodCall, result: Result) {
        val text = call.argument<String>("text")?.trim()
        val imageFile = call.argument<String>("imageFile")?.trim()?.takeUnless { it.isEmpty() }

        if (text.isNullOrEmpty()) {
            result.error("invalid_args", "text is required", null)
            return
        }

        val targetPackage = resolveTelegramPackage()
        if (targetPackage == null) {
            result.error("telegram_not_installed", "Telegram is not installed", null)
            return
        }

        try {
            val shareIntent = buildShareIntent(
                text = text,
                imagePath = imageFile,
                targetPackage = targetPackage,
            )
            applicationContext.startActivity(shareIntent)
            result.success(null)
        } catch (error: Throwable) {
            result.error(
                "share_failed",
                error.message ?: "Unable to share to Telegram",
                null,
            )
        }
    }

    private fun buildShareIntent(
        text: String,
        imagePath: String?,
        targetPackage: String,
    ): Intent {
        val intent = Intent(Intent.ACTION_SEND).apply {
            `package` = targetPackage
            putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }

        if (imagePath == null) {
            intent.type = "text/plain"
            return intent
        }

        val sharedFile = copyToCache(File(imagePath))
        val sharedUri = FileProvider.getUriForFile(
            applicationContext,
            "${applicationContext.packageName}.tomo_share.fileprovider",
            sharedFile,
        )

        intent.apply {
            type = resolveMimeType(sharedFile) ?: "image/*"
            putExtra(Intent.EXTRA_STREAM, sharedUri)
            clipData = ClipData.newUri(
                applicationContext.contentResolver,
                sharedFile.name,
                sharedUri,
            )
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        return intent
    }

    private fun resolveTelegramPackage(): String? {
        val packageManager = applicationContext.packageManager
        return telegramPackages.firstOrNull { packageName ->
            try {
                @Suppress("DEPRECATION")
                packageManager.getPackageInfo(packageName, 0)
                true
            } catch (_: PackageManager.NameNotFoundException) {
                false
            }
        }
    }

    private fun copyToCache(sourceFile: File): File {
        if (!sourceFile.exists()) {
            throw FileNotFoundException("imageFile does not exist: ${sourceFile.path}")
        }

        val cacheDirectory = File(applicationContext.cacheDir, "tomo_share").apply {
            mkdirs()
        }
        val safeName = sourceFile.name.ifBlank { "telegram_share" }
        val targetFile = File(
            cacheDirectory,
            "${System.currentTimeMillis()}_$safeName",
        )

        sourceFile.inputStream().use { input ->
            targetFile.outputStream().use { output ->
                input.copyTo(output)
            }
        }

        return targetFile
    }

    private fun resolveMimeType(file: File): String? {
        val extension = file.extension.lowercase(Locale.US)
        if (extension.isNotEmpty()) {
            MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension)?.let { mimeType ->
                return mimeType
            }
        }
        return URLConnection.guessContentTypeFromName(file.name)
    }
}
