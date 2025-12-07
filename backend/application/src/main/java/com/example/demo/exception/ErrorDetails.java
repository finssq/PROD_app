package com.example.demo.exception;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@AllArgsConstructor
public class ErrorDetails {

    private int statusCode;    
    private String message;      
    private long timestamp;       
    private String error;         
    private String path;          
}
