// ServiceNow Script to Create windsurf_sn Field and Add to Form
// Run this script in ServiceNow: System Definition > Scripts - Background Script

gs.log('=== Creating windsurf_sn Field and Adding to Form ===');

// Step 1: Create the field in dictionary
var tableName = 'x_2022294_incident_ai_table';
var fieldName = 'windsurf_sn';
var fieldLabel = 'Windsurf SN';

// Check if field exists
var dictGr = new GlideRecord('sys_dictionary');
dictGr.addQuery('name', fieldName);
dictGr.addQuery('table', tableName);
dictGr.query();

if (!dictGr.next()) {
    // Create the field
    var newDict = new GlideRecord('sys_dictionary');
    newDict.initialize();
    newDict.name = fieldName;
    newDict.element = fieldName;
    newDict.table = tableName;
    newDict.column_label = fieldLabel;
    newDict.label = fieldLabel;
    newDict.type = 'string';
    newDict.max_length = 255;
    newDict.mandatory = false;
    newDict.read_only = false;
    newDict.active = true;
    
    var dictId = newDict.insert();
    gs.log('Field created in dictionary with ID: ' + dictId);
} else {
    gs.log('Field already exists in dictionary');
}

// Step 2: Add field to form layout
var formGr = new GlideRecord('sys_ui_form');
formGr.addQuery('name', tableName);
formGr.query();

if (formGr.next()) {
    gs.log('Found form: ' + formGr.name);
    
    // Check if field is already in any section
    var sectionGr = new GlideRecord('sys_ui_form_section');
    sectionGr.addQuery('sys_ui_form', formGr.sys_id);
    sectionGr.query();
    
    var fieldExists = false;
    while (sectionGr.next()) {
        if (sectionGr.field.indexOf(fieldName) >= 0) {
            fieldExists = true;
            gs.log('Field already exists in form section');
            break;
        }
    }
    
    if (!fieldExists) {
        // Get the first section or create a new one
        var targetSection = new GlideRecord('sys_ui_form_section');
        targetSection.addQuery('sys_ui_form', formGr.sys_id);
        targetSection.orderBy('position');
        targetSection.query();
        
        if (targetSection.next()) {
            // Add field to existing section
            var currentFields = targetSection.field.toString();
            if (currentFields && currentFields !== '') {
                targetSection.field = currentFields + ',' + fieldName;
            } else {
                targetSection.field = fieldName;
            }
            targetSection.update();
            gs.log('Added field to existing form section');
        } else {
            // Create new section
            var newSection = new GlideRecord('sys_ui_form_section');
            newSection.initialize();
            newSection.sys_ui_form = formGr.sys_id;
            newSection.caption = 'Windsurf Fields';
            newSection.field = fieldName;
            newSection.position = 1000;
            newSection.insert();
            gs.log('Created new form section and added field');
        }
    }
} else {
    gs.log('No form found for table: ' + tableName);
}

// Step 3: Verify everything
gs.log('=== Verification ===');

// Check dictionary
var verifyDict = new GlideRecord('sys_dictionary');
verifyDict.addQuery('name', fieldName);
verifyDict.addQuery('table', tableName);
verifyDict.query();

if (verifyDict.next()) {
    gs.log('✅ Field verified in dictionary');
    gs.log('   Label: ' + verifyDict.label);
    gs.log('   Type: ' + verifyDict.type);
    gs.log('   Active: ' + verifyDict.active);
} else {
    gs.log('❌ Field not found in dictionary');
}

// Check form sections
var verifySection = new GlideRecord('sys_ui_form_section');
verifySection.addQuery('field', 'CONTAINS', fieldName);
verifySection.query();

if (verifySection.next()) {
    gs.log('✅ Field found in form section');
    gs.log('   Section: ' + verifySection.caption);
    gs.log('   Position: ' + verifySection.position);
} else {
    gs.log('❌ Field not found in any form section');
}

gs.log('=== Script completed ===');
