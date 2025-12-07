package com.example.demo.dtos.event;

import java.time.LocalDateTime;
import java.util.Set;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder 
public class EventRequestDto {
    private String name;
    private String description;
    private LocalDateTime eventTime;
    private String place;
    private Set<String> tags;

    @Override
    public String toString() {
        return "EventRequestDto{" +
                "name='" + name + '\'' +
                ", eventTime=" + eventTime +
                '}';
    }
}
