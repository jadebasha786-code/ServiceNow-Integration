// ServiceNow Script to Create windsurf_sn Field
// Run this script in ServiceNow: System Definition > Scripts - Background Script

// Field configuration
var tableName = 'x_2022294_incident_ai_table';
var fieldName = 'windsurf_sn';
var fieldLabel = 'Windsurf SN';
var fieldType = 'string';
var maxLength = 255;

gs.log('Starting field creation for: ' + fieldName + ' in table: ' + tableName);

// Check if field already exists
var grDict = new GlideRecord('sys_dictionary');
grDict.addQuery('name', fieldName);
grDict.addQuery('table', tableName);
grDict.query();

if (grDict.next()) {
    gs.log('Field ' + fieldName + ' already exists in table ' + tableName);
    gs.log('Field details:');
    gs.log('  Label: ' + grDict.label);
    gs.log('  Type: ' + grDict.type);
    gs.log('  Active: ' + grDict.active);
} else {
    gs.log('Field does not exist, creating new field...');
    
    // Create the field
    var newField = new GlideRecord('sys_dictionary');
    newField.initialize();
    newField.name = fieldName;
    newField.element = fieldName;
    newField.table = tableName;
    newField.column_label = fieldLabel;
    newField.label = fieldLabel;
    newField.type = fieldType;
    newField.max_length = maxLength;
    newField.mandatory = false;
    newField.read_only = false;
    newField.active = true;
    newField.default_value = '';
    
    var fieldId = newField.insert();
    
    if (fieldId) {
        gs.log('SUCCESS: Field created successfully!');
        gs.log('Field Sys ID: ' + fieldId);
        gs.log('Field Name: ' + fieldName);
        gs.log('Table: ' + tableName);
        gs.log('Label: ' + fieldLabel);
        gs.log('Type: ' + fieldType);
        
        // Verify the field was created
        var verifyGr = new GlideRecord('sys_dictionary');
        if (verifyGr.get(fieldId)) {
            gs.log('VERIFICATION: Field confirmed in database');
            gs.log('  Active: ' + verifyGr.active);
            gs.log('  Created: ' + verifyGr.sys_created_on);
            gs.log('  Created by: ' + verifyGr.sys_created_by);
        }
        
    } else {
        gs.log('ERROR: Failed to create field');
        gs.log('Check if you have proper permissions to create dictionary entries');
    }
}

// Additional check - List all fields in the table to verify
gs.log('=== Current fields in table: ' + tableName + ' ===');
var tableFields = new GlideRecord('sys_dictionary');
tableFields.addQuery('table', tableName);
tableFields.addQuery('active', true);
tableFields.orderBy('name');
tableFields.query();

var fieldCount = 0;
while (tableFields.next()) {
    fieldCount++;
    gs.log('  ' + tableFields.name + ' (' + tableFields.label + ') - Type: ' + tableFields.type);
}

gs.log('Total active fields in table: ' + fieldCount);

// Check if our field is now in the list
var finalCheck = new GlideRecord('sys_dictionary');
finalCheck.addQuery('name', fieldName);
finalCheck.addQuery('table', tableName);
finalCheck.addQuery('active', true);
finalCheck.query();

if (finalCheck.next()) {
    gs.log('✅ FINAL VERIFICATION: Field ' + fieldName + ' is now active and accessible!');
} else {
    gs.log('❌ FINAL VERIFICATION: Field still not found');
}
