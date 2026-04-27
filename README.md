# ServiceNow Integration - AI Table Field Creator

This project creates and manages fields in ServiceNow tables, specifically for the AI Incident table.

## Purpose

This integration creates a new string field called `windsurf_sn` in the ServiceNow table `x_2022294_incident_ai_table` on the dev230337.service-now.com instance.

## Setup

1. **Install Dependencies**
   ```bash
   pip install -r requirements.txt
   ```

2. **Configure ServiceNow Credentials**
   
   Edit `config/servicenow-config.json` and add your ServiceNow credentials:
   ```json
   {
     "instance": {
       "url": "https://dev230337.service-now.com",
       "username": "your_username",
       "password": "your_password"
     }
   }
   ```

3. **Run the Field Creator**
   ```bash
   python src/servicenow-field-creator.py
   ```

## Field Details

- **Field Name**: `windsurf_sn`
- **Field Type**: String
- **Max Length**: 255 characters
- **Table**: `x_2022294_incident_ai_table`
- **Label**: "Windsurf SN"
- **Mandatory**: No
- **Read Only**: No

## Verification

The script automatically verifies that the field was created successfully by:
1. Testing the ServiceNow connection
2. Creating the field via REST API
3. Verifying the field exists in the table

## Security Notes

- Store credentials securely
- Use service accounts with minimal required permissions
- Consider using OAuth instead of basic authentication for production

## API Endpoints Used

- `/api/now/table/sys_dictionary` - For field creation
- `/api/now/table/sys_user` - For connection testing

## Troubleshooting

1. **Connection Issues**: Verify URL and credentials
2. **Permission Issues**: Ensure the user has `admin` or `table_admin` role
3. **Field Already Exists**: The script will show existing field details

## Project Structure

```
ServiceNow-Integration/
├── config/
│   └── servicenow-config.json    # ServiceNow configuration
├── src/
│   └── servicenow-field-creator.py    # Main script
├── requirements.txt               # Python dependencies
└── README.md                     # This file
```
