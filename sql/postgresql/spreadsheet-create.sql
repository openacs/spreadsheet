-- spreadsheet-create.sql
--
-- @author Dekka Corp.
-- @license GNU GENERAL PUBLIC LICENSE, Version 2, June 1991
-- @cvs-id
--

-- we are not going to reference acs_objects directly, so that this can be used
-- separate from acs-core.
CREATE TABLE qss_sheets_object_id_map (
     sheet_id integer,
     object_id integer constraint qss_sheets_sheet_id_fk 
                references acs_objects(object_id) 
                on delete cascade constraint qss_sheets_sheets_id_pk primary key,
        -- sheet_id constrained to object_id for permissions
);


CREATE SEQUENCE qss_id start 10000;
SELECT nextval ('qss_id');


    CREATE TABLE qss_sheets (
        id integer DEFAULT nextval ( 'qss_id' ), 

        instance_id integer,
        -- object_id of mounted instance (context_id)

        name_abbrev varchar(40),
        -- no spaces, single word reference that can be used in urls, filenames etc

        style_ref varchar(300),
        --  might be an absolute ref to a css page, or extended to other style references

        sheet_title varchar(80),
        sheet_description text,
        orientation varchar(2) default 'RC',
        -- rc = row reference, column reference

        row_count integer,
        -- use value if not null

        column_count integer,
        -- use value if not null

        last_calculated timestamptz,
        -- should be the max(qss_cells.last_calculated) for a sheet_id

        last_modified timestamptz,
        -- should be the max(qss_cells.last_modified) for a sheet_id

        sheet_status varchar(8)
        -- value will likely be one of
        -- ready      values have been calculated and no active processes working
        -- working    the spreadsheet is in a recalculating process
        -- recalc     values have expired, spreadsheet needs to be recalculated 
    );

    CREATE TABLE qss_cells (
        id integer DEFAULT nextval ( 'qss_id' ),  
        sheet_id varchar(40) not null,
        --  should be a value from qss_sheets.sheet_id
        cell_row integer not null,
        cell_column integer not null,

        cell_value varchar(1025),
        -- returned by function or user input value
        -- cell_row = 0 is default value for other cells in same column

        cell_value_sq varchar(80),
        -- square of cell_value, used frequently in statistics
        -- values in this column are calculated when
        -- cell_row = 0 and cell_value is a number 

        cell_format varchar(80),
        -- formatting, css style class
        -- cell_row = 0 is default value for other cells in same column
        -- allow some kind of odd/even row formatting change
        --   maybe two styles separated by comma
        --   in row 0 represents first,second alternating

        cell_proc varchar(1025),
        -- usually blank or contains a function
        -- cell_row = 0 is default proc for other cells in same column
        -- we are calling this a proc because theoretically
        -- an admin could define a macro-like proc that returns
        -- a value after executing some task, for example, retrieving
        -- a value from a url on the net.
        -- See ecommerce templating for a similar implementation

        cell_calc_depth integer not null default '0',
        -- this value is to be automatically generated and show this
        -- cells order of calculation based on calculation dependencies
        -- for example, calc_depth = max (calc_depth of all dependent cells) + 1

        cell_name varchar(40),
        -- usually blank, an alternate reference to RC format
        -- unique to a sheet
        -- if cell_row is 0 then this is a column_name

        cell_title varchar(80),
        -- a label when displaying cell as a single value
        -- if cell_row is 0 then this is a column_title

        last_calculated timestamptz,
        -- handy for checking when cell value dependencies have changed

        last_modified timestamptz
        -- data entry (cell value) last changed

    );
