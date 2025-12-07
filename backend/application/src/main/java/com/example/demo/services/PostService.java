package com.example.demo.services;

// import java.io.IOException;
// import java.io.InputStream;
// import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
// import org.springframework.web.multipart.MultipartFile;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class PostService {

    @Value("${minio.bucket}")
    private String BUCKET_NAME;

    // final private MinioService minioService;

    // private String uploadImageToMinio(MultipartFile imageFile) {
    //     try {
    //         InputStream inputStream = imageFile.getInputStream();
    //         long contentLength = imageFile.getSize();
    //         String objectName = UUID.randomUUID().toString();

    //         return minioService.uploadImageToMinio(BUCKET_NAME, objectName, inputStream, contentLength);
    //     } catch (IOException e) {
    //         log.error("Failed to upload image to MinIO: {}", e.getMessage());
    //         throw new RuntimeException("Failed to upload image to MinIO", e);
    //     }
    // }

    // private String updateImageInMinio(MultipartFile imageFile, String imageUrl) {
    //     try {
    //         InputStream inputStream = imageFile.getInputStream();
    //         long contentLength = imageFile.getSize();
    //         String objectName = getObjectNameByImageUrl(imageUrl);

    //         return minioService.updateImageInMinio(BUCKET_NAME, objectName, inputStream, contentLength);
    //     } catch (IOException e) {
    //         log.error("Failed to update image to MinIO: {}", e.getMessage());
    //         throw new RuntimeException("Failed to update image to MinIO", e);
    //     }
    // }

    // private void deleteImageFromMinio(String imageUrl) {
    //     String objectName = getObjectNameByImageUrl(imageUrl);

    //     minioService.deleteFile(BUCKET_NAME, objectName);
    // }

    // private String getObjectNameByImageUrl(String imageUrl) {
    //     String[] urlParts = imageUrl.split("/");
    //     String objectName = urlParts[urlParts.length - 1];

    //     return objectName;
    // }
}
