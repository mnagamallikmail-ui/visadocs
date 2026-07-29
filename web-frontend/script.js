document.addEventListener('DOMContentLoaded', () => {
    // Add interactive hover state logic if needed,
    // though most of it is handled cleanly via CSS.

    const buttons = document.querySelectorAll('button');
    buttons.forEach(btn => {
        btn.addEventListener('click', (e) => {
            // Simple ripple or interaction effect placeholder
            console.log('Button clicked:', e.target.textContent.trim());
        });
    });

    const formFields = document.querySelectorAll('.form-field');
    formFields.forEach(field => {
        field.addEventListener('focus', () => {
            console.log('Field focused:', field.id || field.placeholder);
        });
    });
});
