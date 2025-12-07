package com.example.demo.services;

import java.io.InputStream;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import io.minio.BucketExistsArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.RemoveObjectArgs;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Service
@RequiredArgsConstructor
public class MinioService {

    private final MinioClient minioClient;

    @Value("${minio.endpoint-for-users}")
    private String ENDPOINT_MINIO_FOR_USERS;

    public String uploadImageToMinio(String bucketName, String objectName, InputStream inputStream, long contentLength) {
        try {
            boolean isExist = minioClient.bucketExists(
                BucketExistsArgs.builder().bucket(bucketName).build());

            if (!isExist) {
                minioClient.makeBucket(
                    MakeBucketArgs.builder().bucket(bucketName).build());
            }

            String contentType = "image/jpeg";

            minioClient.putObject(PutObjectArgs.builder()
                .bucket(bucketName)
                .object(objectName)
                .contentType(contentType)
                .stream(inputStream, contentLength, -1)
                .build());
            
            String imageUrl = ENDPOINT_MINIO_FOR_USERS + "/" + bucketName + "/" + objectName;
            return imageUrl;
        } catch (Exception e) {
            log.error(e.getMessage(), e);
            return null;
        }
    }

    public String updateImageInMinio(String bucketName, String objectName, InputStream newInputStream, long newContentLength) {
        try {
            deleteFile(bucketName, objectName);
            return uploadImageToMinio(bucketName, objectName, newInputStream, newContentLength);
        } catch (Exception e) {
            log.error("Error updating file in MinIO: {}", e.getMessage(), e);
            return null;
        }
    }

    public void deleteFile(String bucketName, String objectName) {
        try {
            minioClient.removeObject(RemoveObjectArgs.builder()
                .bucket(bucketName)
                .object(objectName)
                .build());

            log.info("File {} successfully deleted from bucket {}", objectName, bucketName);
        } catch (Exception e) {
            log.error("Error deleting file from MinIO: {}", e.getMessage(), e);
        }
    }
}
