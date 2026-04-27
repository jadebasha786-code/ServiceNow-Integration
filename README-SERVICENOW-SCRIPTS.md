# ServiceNow Scripts - Field Creation

This directory contains ServiceNow scripts to create the `windsurf_sn` field directly in your ServiceNow instance.

## How to Use

### Method 1: Simple Field Creator
**File**: `simple-field-creator.js`

1. Navigate to ServiceNow: **System Definition > Scripts**
2. Click **Background Script**
3. Copy and paste the script content
4. Click **Run Script**

### Method 2: Complete Field Creation with Form
**File**: `create-field-with-form.js`

This script creates the field AND adds it to the form layout:

1. Navigate to ServiceNow: **System Definition > Scripts**
2. Click **Background Script**
3. Copy and paste the script content
4. Click **Run Script**

### Method 3: Detailed Field Creation
**File**: `create-windsurf-field.js`

This script includes detailed logging and verification:

1. Navigate to ServiceNow: **System Definition > Scripts**
2. Click **Background Script**
3. Copy and paste the script content
4. Click **Run Script**

## Field Details

- **Field Name**: `windsurf_sn`
- **Field Type**: String
- **Max Length**: 255 characters
- **Table**: `x_2022294_incident_ai_table`
- **Label**: Windsurf SN
- **Mandatory**: No
- **Read Only**: No

## Verification

After running the script:

1. **Check Dictionary**: Go to **System Definition > Dictionary**
2. **Filter by Table**: `x_2022294_incident_ai_table`
3. **Look for**: `windsurf_sn` field
4. **Check Form**: Open the AI table form to see the field

## Troubleshooting

If the script doesn't work:

1. **Check Permissions**: Ensure you have admin or table_admin role
2. **Check Table Name**: Verify `x_2022294_incident_ai_table` exists
3. **Check Logs**: View system logs for any error messages
4. **Manual Creation**: Use System Definition > Dictionary if script fails

## Benefits of ServiceNow Scripts

- **No API Authentication Issues**: Runs with your ServiceNow user permissions
- **Direct Database Access**: Uses GlideRecord for direct database operations
- **Immediate Results**: Field creation is instant
- **Full Logging**: Detailed output for troubleshooting
- **Form Integration**: Can add fields to form layouts automatically

## Script Output

The scripts will output log messages that you can view in:
- **System Log**: System Logs > All
- **Background Script Output**: Directly in the script interface

Look for messages like:
- `SUCCESS: Field created successfully!`
- `Field Sys ID: [ID]`
- `✅ Field verified in database`
