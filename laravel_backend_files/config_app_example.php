<?php

/**
 * CONFIGURATION EXAMPLE: Add these to your config/app.php or .env file
 * 
 * This shows how to configure office hours and contact information
 * for the pickup instruction messages.
 */

return [
    // ... existing config ...

    /*
    |--------------------------------------------------------------------------
    | Admin Office Configuration
    |--------------------------------------------------------------------------
    |
    | Configuration for pickup instruction messages
    |
    */

    'admin_office_location' => env('ADMIN_OFFICE_LOCATION', 'Administrative Office, Carmen National High School'),
    
    'admin_office_hours' => env('ADMIN_OFFICE_HOURS', 'Monday-Friday, 8:00 AM - 5:00 PM'),
    
    'admin_email' => env('ADMIN_EMAIL', 'admin@carmenhighschool.edu.ph'),
    
    'admin_phone' => env('ADMIN_PHONE', '(XXX) XXX-XXXX'),
    
    'default_collection_deadline_days' => env('DEFAULT_COLLECTION_DEADLINE_DAYS', 7),
];




























