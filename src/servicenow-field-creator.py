#!/usr/bin/env python3
"""
ServiceNow Field Creator Script
Creates the windsurf_sn field in the x_2022294_incident_ai_table
"""

import requests
import json
import sys
from typing import Dict, Any

class ServiceNowFieldCreator:
    def __init__(self, config_path: str = "config/servicenow-config.json"):
        """Initialize with configuration file"""
        self.config = self.load_config(config_path)
        self.session = requests.Session()
        self.session.auth = (self.config['instance']['username'], 
                           self.config['instance']['password'])
        self.session.headers.update({
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        })

    def load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from JSON file"""
        try:
            with open(config_path, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            print(f"Error: Configuration file {config_path} not found")
            sys.exit(1)
        except json.JSONDecodeError:
            print(f"Error: Invalid JSON in configuration file {config_path}")
            sys.exit(1)

    def test_connection(self) -> bool:
        """Test connection to ServiceNow instance"""
        try:
            url = f"{self.config['instance']['url']}/api/now/table/sys_user"
            response = self.session.get(url, params={'sysparm_limit': 1})
            return response.status_code == 200
        except requests.exceptions.RequestException as e:
            print(f"Connection error: {e}")
            return False

    def create_field(self) -> Dict[str, Any]:
        """Create the windsurf_sn field in the specified table"""
        field_config = self.config['table']['field_to_create']
        table_name = self.config['table']['name']
        
        # Prepare field definition for ServiceNow
        field_data = {
            "name": field_config['name'],
            "element": field_config['name'],
            "column_label": field_config['column_label'],
            "label": field_config['label'],
            "type": field_config['type'],
            "max_length": field_config['max_length'],
            "mandatory": field_config['mandatory'],
            "read_only": field_config['read_only'],
            "default_value": field_config['default_value'],
            "table": table_name,
            "active": True
        }

        try:
            # Create field in sys_dictionary
            url = f"{self.config['instance']['url']}/api/now/table/sys_dictionary"
            response = self.session.post(url, json=field_data)
            
            if response.status_code == 201:
                result = response.json()
                print(f"Field '{field_config['name']}' created successfully!")
                print(f"Field Sys ID: {result.get('result', {}).get('sys_id')}")
                return result
            else:
                print(f"Error creating field: {response.status_code}")
                print(f"Response: {response.text}")
                return None
                
        except requests.exceptions.RequestException as e:
            print(f"Request error: {e}")
            return None

    def verify_field_created(self) -> bool:
        """Verify that the field was created successfully"""
        field_name = self.config['table']['field_to_create']['name']
        table_name = self.config['table']['name']
        
        try:
            url = f"{self.config['instance']['url']}/api/now/table/sys_dictionary"
            params = {
                'sysparm_query': f'name={field_name}^table={table_name}',
                'sysparm_fields': 'name,element,label,type,active'
            }
            
            response = self.session.get(url, params=params)
            
            if response.status_code == 200:
                result = response.json()
                if result.get('result') and len(result['result']) > 0:
                    field_info = result['result'][0]
                    print(f"Field verification successful:")
                    print(f"  Name: {field_info.get('name')}")
                    print(f"  Label: {field_info.get('label')}")
                    print(f"  Type: {field_info.get('type')}")
                    print(f"  Active: {field_info.get('active')}")
                    return True
                else:
                    print("Field not found in table")
                    return False
            else:
                print(f"Error verifying field: {response.status_code}")
                return False
                
        except requests.exceptions.RequestException as e:
            print(f"Verification error: {e}")
            return False

def main():
    """Main execution function"""
    print("ServiceNow Field Creator - windsurf_sn Field")
    print("=" * 50)
    
    # Initialize the field creator
    creator = ServiceNowFieldCreator()
    
    # Check configuration
    if not creator.config['instance']['username'] or not creator.config['instance']['password']:
        print("Error: Please update the configuration file with your ServiceNow credentials")
        print("File: config/servicenow-config.json")
        return
    
    # Test connection
    print("Testing connection to ServiceNow...")
    if not creator.test_connection():
        print("Failed to connect to ServiceNow instance")
        return
    print("Connection successful!")
    
    # Create the field
    print(f"\nCreating field '{creator.config['table']['field_to_create']['name']}'...")
    result = creator.create_field()
    
    if result:
        # Verify the field was created
        print("\nVerifying field creation...")
        if creator.verify_field_created():
            print("\n✅ Field created and verified successfully!")
        else:
            print("\n⚠️  Field creation may have failed - verification failed")
    else:
        print("\n❌ Field creation failed")

if __name__ == "__main__":
    main()
