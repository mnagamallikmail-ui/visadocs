package com.provaluer.model;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

public enum PhotoCategory {
    FRONT_ELEVATION("Front Elevation", true, 1, 5),
    REAR_ELEVATION("Rear Elevation", true, 1, 5),
    SIDE_VIEW_LEFT("Left Side View", true, 1, 3),
    SIDE_VIEW_RIGHT("Right Side View", true, 1, 3),
    STREET_VIEW("Street / Road View", true, 1, 4),
    ACCESS_ROAD("Access Road", true, 1, 4),
    SURROUNDINGS("Surrounding Area", true, 2, 10),
    BOUNDARY_NORTH("North Boundary", false, 0, 3),
    BOUNDARY_SOUTH("South Boundary", false, 0, 3),
    BOUNDARY_EAST("East Boundary", false, 0, 3),
    BOUNDARY_WEST("West Boundary", false, 0, 3),
    INTERIOR("Interior (if accessible)", false, 0, 20),
    ADDITIONAL("Additional / Misc", false, 0, 20);

    private final String displayName;
    private final boolean mandatory;
    private final int minPhotos;
    private final int maxPhotos;

    PhotoCategory(String displayName, boolean mandatory, int minPhotos, int maxPhotos) {
        this.displayName = displayName;
        this.mandatory = mandatory;
        this.minPhotos = minPhotos;
        this.maxPhotos = maxPhotos;
    }

    public String getDisplayName() { return displayName; }
    public boolean isMandatory() { return mandatory; }
    public int getMinPhotos() { return minPhotos; }
    public int getMaxPhotos() { return maxPhotos; }

    public static Optional<PhotoCategory> fromCode(String code) {
        if (code == null) return Optional.empty();
        return Arrays.stream(values())
                .filter(c -> c.name().equalsIgnoreCase(code.trim()))
                .findFirst();
    }

    public static boolean isValid(String code) {
        return fromCode(code).isPresent();
    }

    public static List<PhotoCategory> getMandatoryCategories() {
        return Arrays.stream(values())
                .filter(PhotoCategory::isMandatory)
                .collect(Collectors.toList());
    }
}
