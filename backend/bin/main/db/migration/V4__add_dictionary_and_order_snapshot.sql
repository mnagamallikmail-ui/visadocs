CREATE TABLE template_questions_dictionary (
    placeholder_key VARCHAR(255) PRIMARY KEY,
    question_text TEXT NOT NULL
);

INSERT INTO template_questions_dictionary (placeholder_key, question_text) VALUES
('GST_NUMBER', 'What is the GST registration number?'),
('CLIENT_NAME', 'What is the client''s full name?'),
('PROPERTY_ADDRESS', 'What is the complete address of the property?'),
('REGISTRATION_NUMBER', 'What is the property registration number?'),
('INSPECTION_DATE', 'When did the property inspection take place?'),
('PROPERTY_AREA_SFT', 'What is the property area in square feet?');

ALTER TABLE orders ADD COLUMN field_mapping_snapshot TEXT;
