package com.provaluer.dto;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class TemplateDiffDTO {
    private int oldVersion;
    private int proposedVersion;
    private List<String> retainedTokens = new ArrayList<>();
    private List<String> addedTokens = new ArrayList<>();
    private List<String> removedTokens = new ArrayList<>();
    private Map<String, String> renamedTokens = new HashMap<>();
    private boolean hasBreakingChanges;
    private List<String> breakingChangeReasons = new ArrayList<>();
    private String compatibilityStatus = "SAFE"; // SAFE, SAFE_WITH_NOTICE, BREAKING_CHANGE

    public TemplateDiffDTO() {}

    public int getOldVersion() { return oldVersion; }
    public void setOldVersion(int oldVersion) { this.oldVersion = oldVersion; }

    public int getProposedVersion() { return proposedVersion; }
    public void setProposedVersion(int proposedVersion) { this.proposedVersion = proposedVersion; }

    public List<String> getRetainedTokens() { return retainedTokens; }
    public void setRetainedTokens(List<String> retainedTokens) { this.retainedTokens = retainedTokens; }

    public List<String> getAddedTokens() { return addedTokens; }
    public void setAddedTokens(List<String> addedTokens) { this.addedTokens = addedTokens; }

    public List<String> getRemovedTokens() { return removedTokens; }
    public void setRemovedTokens(List<String> removedTokens) { this.removedTokens = removedTokens; }

    public Map<String, String> getRenamedTokens() { return renamedTokens; }
    public void setRenamedTokens(Map<String, String> renamedTokens) { this.renamedTokens = renamedTokens; }

    public boolean isHasBreakingChanges() { return hasBreakingChanges; }
    public void setHasBreakingChanges(boolean hasBreakingChanges) { this.hasBreakingChanges = hasBreakingChanges; }

    public List<String> getBreakingChangeReasons() { return breakingChangeReasons; }
    public void setBreakingChangeReasons(List<String> breakingChangeReasons) { this.breakingChangeReasons = breakingChangeReasons; }

    public String getCompatibilityStatus() { return compatibilityStatus; }
    public void setCompatibilityStatus(String compatibilityStatus) { this.compatibilityStatus = compatibilityStatus; }
}
