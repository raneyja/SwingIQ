//
//  CalendarPermissions.swift
//  SwingIQ
//
//  Created by Amp on 7/19/25.
//

import Foundation

// MARK: - Setup Instructions for AI Calendar Analysis

/*
 ## Setup Required for AI Calendar Analysis Feature

 ### 1. Calendar Permissions (Required)
 Add these keys to your target's Info.plist through Xcode's Build Settings > Custom iOS Target Properties:
 
 - NSCalendarsUsageDescription: "SwingIQ needs access to your calendar to automatically detect upcoming tee times and golf-related events to help you prepare for your rounds."
 - NSCalendarsFullAccessUsageDescription: "SwingIQ needs full calendar access to intelligently analyze your golf events and provide personalized recommendations for your upcoming rounds."

 ### 2. Google Gemini API Key (Required for AI Analysis)
 Configure your Gemini API key using one of these methods:

 #### Option A: Environment Variable (Recommended for development)
 Set the GEMINI_API_KEY environment variable in your Xcode scheme:
 1. Product > Scheme > Edit Scheme
 2. Run > Arguments > Environment Variables
 3. Add: GEMINI_API_KEY = your_actual_api_key_here

 #### Option B: Info.plist (Good for app distribution)
 Add to your Info.plist:
 <key>GeminiAPIKey</key>
 <string>your_actual_api_key_here</string>

 #### Option C: Direct Configuration (Not recommended for production)
 Edit APIConfiguration.swift and replace nil with your API key

 ### 3. Get Your Gemini API Key
 1. Go to https://makersuite.google.com/app/apikey
 2. Create a new API key
 3. Copy the key and use it in one of the methods above

 ### 4. Testing
 The calendar AI analysis will automatically work once:
 - Calendar permissions are granted by the user
 - A valid Gemini API key is configured
 - The user has golf-related events in their calendar
 */
