package com.provaluer.model;

import jakarta.persistence.*;

@Entity
@Table(name = "template_questions_dictionary")
public class TemplateQuestion {

    @Id
    @Column(name = "placeholder_key", nullable = false)
    private String placeholderKey;

    @Column(name = "question_text", nullable = false, columnDefinition = "TEXT")
    private String questionText;

    public TemplateQuestion() {}

    public TemplateQuestion(String placeholderKey, String questionText) {
        this.placeholderKey = placeholderKey;
        this.questionText = questionText;
    }

    public String getPlaceholderKey() {
        return placeholderKey;
    }

    public void setPlaceholderKey(String placeholderKey) {
        this.placeholderKey = placeholderKey;
    }

    public String getQuestionText() {
        return questionText;
    }

    public void setQuestionText(String questionText) {
        this.questionText = questionText;
    }
}
