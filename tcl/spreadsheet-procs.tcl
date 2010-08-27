ad_library {

    routines for accessing and managing spreadsheets
    @creation-date 25 August 2010
    @cs-id $Id:
}

namespace eval spreadsheet {}

ad_proc -public spreadsheet::new_id { 
} {
    gets new spreadsheet id
} {
    set spreadsheet_id [db_nextval qss_id_seq]
    return $spreadsheet_id
}

ad_proc -private spreadsheet::status_q { 
    sheet_id
} {
    gets spreadsheet status
} {
    db_0or1row get_spreadsheet_status "select sheet_status from qss_sheets where id = :sheet_id"
    if { ![info exists sheet_status] } {
        set sheet_status ""
    }
    return $sheet_status
}

ad_proc -private spreadsheet::exists_for_rwd_q { 
    sheet_id
    instance_id
} {
    returns 1 if sheet_id exists. This is handy for reads, writes, and deletes. Use status_q instead if you want to check for the existence of the id only.
} {
    db_0or1row spreadsheet_exists_q "select sheet_status from qss_sheets where id = :sheet_id and instance_id = :instance_id"
    if { ![info exists sheet_status] } {
        set exists_p 0
    } else {
        set exists_p 1
    }
    return $exists_p
}


ad_proc -public spreadsheet::create { 
    id
    name_abbrev
    sheet_title
    style_ref
    sheet_description
    {orientation "RC"}
} {
    creates spreadsheet
    Orientation RC means fixed columns, variable number of rows.
    Orientation CR means fixed rows, variable number of columns.
} {
    # if id exists, assume it's a double click or bad info, ignore
    set success 0
    if { [spreadsheet::status_q $id] eq "" } {
        set package_id [ad_conn package_id]
        set user_id [ad_conn user_id]
        set create_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege create]
        if { $create_p } { 
            db_dml create_new_sheet {insert into qss_sheets 
           (id, instance_id, name_abbrev, style_ref, sheet_description, orientation,row_count,column_count,last_calclated,last_modified, last_modified_by) 
            values (:id, :package_id, :name_abbrev, :style_ref, :sheet_description, :orientation, '0', '0', now(), now(), :user_id ) }
        }
        set success $create_p
    } 
    return $success
}

ad_proc -public spreadsheet::list { 
    package_id
    {user_id "0"}
} {
    returns list of lists of existing sheets: {id name_abbrev sheet_title last_modified by_user} 
    If user_id is passed, results are sheets that the user has created or modified within package_id.
} {
    if { $user_id eq 0 } {
        set table [db_list_of_lists get_list_of_spreadsheets {select id, name_abbrev, sheet_title, last_modified, by_user from qss_sheets where instance_id = :package_id order by sheet_title } ]
    } else {
        set table [db_list_of_lists get_list_of_spreadsheets_for_user_id {select id, name_abbrev, sheet_title, last_modified, by_user
            from qss_sheets where ( instance_id = :package_id and user_id = :user_id ) or instance_id in 
              ( select instance_id from qss_cells where sheet_id in ( select id from qss_sheets where instance_id = :package_id unique ) and last_modified_by = :user_id ) order by sheet_title } ]
    } 
}

ad_proc -public spreadsheet::attributes { 
    sheet_id
} {
    returns attributes of a sheet in list format: {id name_abbrev sheet_title last_modified by_user orientation row_count column_count last_calculated last_modified sheet_status} 
} {
    set package_id [ad_conn package_id]
    set user_id [ad_conn user_id]
    set read_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege read]
    if { $read_p && [spreadsheet::exists_for_rwd_q $sheet_id $package_id] } {
        set sheet_list [db_list get_spreadsheet_attributes {select id, name_abbrev, sheet_title, last_modified, by_user, orientation, row_count, column_count, last_calculated, last_modified, sheet_status from qss_sheets where instance_id = :package_id and id = :sheet_id } ]
    } else {
        set sheet_list [list ]
    }
}

ad_proc -public spreadsheet::cells_read { 
    sheet_id
    {start ""}
    {count ""}
} {
    reads spreadsheet, returns list_of_lists, each cell is an element in the list
    If orientation is RC, cells are sorted first by row.
    If orientation is CR, cells are sorted first by column.
    first element contains header references
} {
    if { [ad_var_type_check_number_p $start] && $start > 0 && [ad_var_type_check_number_p $count] && $count > 0 } {
        set page_start $start
        set page_size $count
    }
    set package_id [ad_conn package_id]
    set user_id [ad_conn user_id]
    set read_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege read]
    # if orientation is RC, start is start_row, count is num_of_rows
    # if orientation is CR, start is start_col, count is num_of_columns
    if { $read_p && [spreadsheet::exists_for_rwd_q $sheet_id $package_id] } {
        if { [info exists $page_start] } {
            set table [db_list_of_lists get_all_cells_of_sheet {select id, cell_row, cell_column, cell_value, cell_value_sq, cell_format, cell_proc, cell_calc_depth, cell_name, cell_title from qss_cells where sheet_id = :sheet_id} limit :page_size offest :page_start ]
        } else {
            set table [db_list_of_lists get_all_cells_of_sheet {select id, cell_row, cell_column, cell_value, cell_value_sq, cell_format, cell_proc, cell_calc_depth, cell_name, cell_title from qss_cells where sheet_id = :sheet_id} ]
        }
    } else {
        set table [list ]
    }        
    set table [linsert $table 0 [list id cell_row cell_column cell_value cell_value_sq cell_format cell_proc cell_calc_depth cell_name cell_title]
    return $table
}

ad_proc -public spreadsheet::cells_write {
    sheet_id
    list_of_lists
} {
    writes spreadsheet cells. 
    assumes first element of list is a list of header references to columns (if orientatin is RC) or rows (if CR).
    if row or column reference is not provided, appends new lines.
    Reserved header references (attribute) have features automatically attached to them:
    cell_row (positive integer) if RC orientation, replaces an existing cell_row if it exists.
    cell_column (positive integer) if CR orientation, replaces an existing cell_column if it exists.
    id (positive integer) replaces existing id if it exists.
    other attrributes: cell_format cell_proc cell_name cell_title
} {
    set success 0
    set package_id [ad_conn package_id]
    set user_id [ad_conn user_id]
    set write_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege write]
    if { $write_p && [spreadsheet::exists_for_rwd_q $sheet_id $package_id] } {
        # collect allowed attributes from first element
        set attributes_list [list id cell_row cell_column cell_value cell_format cell_proc cell_name cell_title]
        set maybe_attributes_list [lindex $list_of_lists 0]
        set attributes_passed_list [list ]
        foreach attribute_test $maybe_attributes_list {
            set attribute_index [lsearch -exact $attributes_list $attribute_test]
            if { $attribute_index > 0 } {
                set attribute_arr($attribute_test) $attribute_index
                lappend attributes_passed_list $attribute_test
            }
        }
        
        # loop that grabs a cell
        set cells_list [lreplace $list_of_lists 0 0]
        set id_exists_p [expr { [lsearch -exact $attributes_passed_list id] > 0 } ]
        foreach cell_attributes_input_list $cells_list {
            # if id exists, use that reference over cell_row or cell_column
            
            # loop that assigns cell attributes


            #  write cell attributes
        

        }

    }
    return $success
}

ad_proc -public spreadsheet::delete {
    spreadsheet_id
} {
    deletes spreadsheet
} {
   # validate permission, and confirm its existence
    set package_id [ad_conn package_id]
    set user_id [ad_conn user_id]
    set delete_p [permission::permission_p -party_id $user_id -object_id $package_id -privilege delete]
    if { $delete_p } {
        # delete references in qss_cells
        db_1row {spreadsheet_cell_count "select rows(*) as row_count from qss_cells where sheet_id = :spreadsheet_id and instance_id = :package_id"}
        if { $row_count > 0 } {
            db_dml spreadsheet_cells_delete_all "delete from qss_cells where sheet_id = :spreadsheet_id  and instance_id = :package_id"
        }
        # delete reference in qss_sheets
        db_1row {spreadsheet_cell_count "select rows(*) as sheet_exists_q from qss_cells where id = :spreadsheet_id and instance_id = :package_id"}
        if { $sheet_exists_q } {
            db_dml  spreadsheet_delete "delete from qss_sheets where id = :spreadsheet_id  and instance_id = :package_id"
        }
        set success 1
    } else {
        set success 0
    }
    return $success
} 

ad_proc -public spreadsheet::list {
} {
    returns list_of_lists of available spreadsheets
    each list item contains:
    id, name_abbrev, sheet_title,row_count,column_count,last_calculated,last_modified,status
} {

}
