package com.apparence.camerawesome.cameraX

import android.annotation.SuppressLint
import android.graphics.*
import android.util.Log
import android.util.Size
import androidx.camera.core.AspectRatio
import androidx.camera.core.ImageAnalysis
import androidx.camera.core.ImageProxy
import androidx.camera.core.internal.utils.ImageUtil
import com.apparence.camerawesome.utils.ResettableCountDownLatch
import io.flutter.plugin.common.EventChannel
import kotlinx.coroutines.*
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executor
import kotlin.math.roundToInt
import kotlin.math.roundToLong


enum class OutputImageFormat {
    JPEG, YUV_420_888, NV21,
}

class ImageAnalysisBuilder private constructor(
    private val format: OutputImageFormat,
    private val width: Int,
    private val height: Int,
    private val executor: Executor,
    var previewStreamSink: EventChannel.EventSink? = null,
    private val maxFramesPerSecond: Double?,
) {
    private var lastImageEmittedTimeStamp: Long? = null
    private var countDownLatch = ResettableCountDownLatch(1)
    fun lastFrameAnalysisFinished() {
        countDownLatch.countDown()
    }

    companion object {
        fun configure(
            aspectRatio: Int,
            format: OutputImageFormat,
            executor: Executor,
            width: Long?,
            maxFramesPerSecond: Double?,
        ): ImageAnalysisBuilder {
            var widthOrDefault = 1024
            if (width != null && width > 0) {
                widthOrDefault = width.toInt()
            }
            val analysisAspectRatio = when (aspectRatio) {
                AspectRatio.RATIO_4_3 -> 4f / 3
                else -> 16f / 9
            }
            val height = widthOrDefault * (1 / analysisAspectRatio)
            val maxFps = if (maxFramesPerSecond == 0.0) null else maxFramesPerSecond
            return ImageAnalysisBuilder(
                format,
                480,
                640,
                executor,
                maxFramesPerSecond = maxFps,
            )
        }
    }

    @SuppressLint("RestrictedApi")
    fun build(): ImageAnalysis {
        countDownLatch.reset()
        val imageAnalysis = ImageAnalysis.Builder().setTargetResolution(Size(480, 640))
            .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
            .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_YUV_420_888).build()
        Log.d("AnalysisAZER", "maxFps: $maxFramesPerSecond")
        imageAnalysis.setAnalyzer(Dispatchers.IO.asExecutor()) { imageProxy ->
            if (previewStreamSink == null) {
                return@setAnalyzer
            }
            Log.d("WXCVBN", "image analysis image...")
            when (format) {
                OutputImageFormat.JPEG -> {
                    val jpegImage = ImageUtil.yuvImageToJpegByteArray(
                        imageProxy, Rect(0, 0, imageProxy.width, imageProxy.height), 100
                    )
                    val imageMap = imageProxyBaseAdapter(imageProxy)

                    imageMap["jpegImage"] = jpegImage
                    imageMap["cropRect"] = cropRect(imageProxy)
                    imageMap["displayImage"] = getDisplayImage(imageProxy)
                    executor.execute { previewStreamSink?.success(imageMap) }
                }
                OutputImageFormat.YUV_420_888 -> {
                    val planes = imagePlanesAdapter(imageProxy)
                    val imageMap = imageProxyBaseAdapter(imageProxy)

                    imageMap["planes"] = planes
                    imageMap["cropRect"] = cropRect(imageProxy)
                    imageMap["displayImage"] = getDisplayImage(imageProxy)
                    executor.execute { previewStreamSink?.success(imageMap) }
                }
                OutputImageFormat.NV21 -> {
                    val nv21Image = ImageUtil.yuv_420_888toNv21(imageProxy)
                    val planes = imagePlanesAdapter(imageProxy)
                    val imageMap = imageProxyBaseAdapter(imageProxy)
                    imageMap["nv21Image"] = nv21Image
                    imageMap["planes"] = planes
                    imageMap["cropRect"] = cropRect(imageProxy)
                    imageMap["displayImage"] = getDisplayImage(imageProxy)
                    executor.execute { previewStreamSink?.success(imageMap) }
                }
            }
            CoroutineScope(Dispatchers.IO).launch {
                maxFramesPerSecond?.let {
                    if (lastImageEmittedTimeStamp == null) {
                        delay((1000 / it).roundToLong())
                    } else {
                        delay(
                            (1000 / it).roundToInt() - (System.currentTimeMillis() - lastImageEmittedTimeStamp!!)
                        )
                    }
                }
                countDownLatch.await()
                imageProxy.close()
            }
            lastImageEmittedTimeStamp = System.currentTimeMillis()
        }
        return imageAnalysis
    }

    private fun getDisplayImage(imageProxy: ImageProxy): ByteArray {
        val image = imageProxy.getImage();

        val planes = image!!.getPlanes();
        val yBuffer = planes[0].getBuffer();
        val uBuffer = planes[1].getBuffer();
        val vBuffer = planes[2].getBuffer();

        val ySize = yBuffer.remaining();
        val uSize = uBuffer.remaining();
        val vSize = vBuffer.remaining();

        val nv21 = ImageUtil.yuv_420_888toNv21(imageProxy)
        //U and V are swapped
        yBuffer.get(nv21, 0, ySize);
        vBuffer.get(nv21, ySize, vSize);
        uBuffer.get(nv21, ySize + vSize, uSize);

        val yuvImage = YuvImage(nv21, ImageFormat.NV21, image.width, image.height, null);
        val out = ByteArrayOutputStream();
        yuvImage.compressToJpeg(Rect(0, 0, yuvImage.getWidth(), yuvImage.getHeight()), 100, out);
        return rotateImage(out.toByteArray(), imageProxy);
    }

    private fun rotateImage(bytes: ByteArray, imageProxy: ImageProxy): ByteArray {
        val rotate = imageProxy.imageInfo.rotationDegrees;
        val matrix = Matrix();
        val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size);
        matrix.postRotate(rotate.toFloat());

        val bmp = Bitmap.createBitmap(
            bitmap, 0, 0, bitmap.getWidth(),
            bitmap.getHeight(), matrix, true
        );

        val stream = ByteArrayOutputStream()
        bmp.compress(Bitmap.CompressFormat.JPEG, 100, stream)
        return stream.toByteArray()
    }


    private fun cropRect(imageProxy: ImageProxy): Map<String, Any> {
        return mapOf(
            "left" to imageProxy.cropRect.left,
            "top" to imageProxy.cropRect.top,
            "right" to imageProxy.cropRect.right,
            "bottom" to imageProxy.cropRect.bottom,
        )
    }

    @SuppressLint("RestrictedApi", "UnsafeOptInUsageError")
    private fun imageProxyBaseAdapter(imageProxy: ImageProxy): MutableMap<String, Any> {
        return mutableMapOf(
            "height" to imageProxy.image!!.height,
            "width" to imageProxy.image!!.width,
            "format" to format.name.lowercase(),
            "rotation" to "rotation${imageProxy.imageInfo.rotationDegrees}deg",
        )
    }

    @SuppressLint("RestrictedApi", "UnsafeOptInUsageError")
    private fun imagePlanesAdapter(imageProxy: ImageProxy): List<Map<String, Any>> {
        return imageProxy.image!!.planes.map {
            val byteArray = ByteArray(it.buffer.remaining())
            it.buffer.get(byteArray, 0, byteArray.size)
            mapOf(
                "bytes" to byteArray, "rowStride" to it.rowStride, "pixelStride" to it.pixelStride
            )
        }
    }

}
