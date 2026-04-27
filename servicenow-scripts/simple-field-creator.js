// Simple ServiceNow Field Creator
// Run in: System Definition > Scripts > Background Script

// Create windsurf_sn field
var gr = new GlideRecord('sys_dictionary');
gr.addQuery('name', 'windsurf_sn');
gr.addQuery('table', 'x_2022294_incident_ai_table');
gr.query();

if (gr.next()) {
    gs.log('Field windsurf_sn already exists');
} else {
    var newField = new GlideRecord('sys_dictionary');
    newField.initialize();
    newField.name = 'windsurf_sn';
    newField.element = 'windsurf_sn';
    newField.table = 'x_2022294_incident_ai_table';
    newField.column_label = 'Windsurf SN';
    newField.label = 'Windsurf SN';
    newField.type = 'string';
    newField.max_length = 255;
    newField.mandatory = false;
    newField.read_only = false;
    newField.active = true;
    
    var result = newField.insert();
    gs.log('Field created with Sys ID: ' + result);
}
