ad_library {

    routines for creating, managing input via html forms
    @creation-date 21 Nov 2010
    @cs-id $Id:
}

# use _ to clear a new default
# use upvar to grab previous defaults and re-use (with qf_input only)
# main namespace vars:
# __form_input_arr = array that contains existing form input and defaults, only one form can be posted at a time
# __form_ids_list  = list that contains existing form ids
# __form_ids_open_list = list that contains forms that are not closed
# __form_ids_fieldset_open_list = list that contains form ids where a fieldset tag is open
# __form_arr contains forms built as strings by appending tags to strings, indexed by form id, for example __form_arr($id)
# __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
# a blank id passed in anything other than qf_form assumes the current (most recent used form_id)

# to fix:  id for not form tag should not be same as form id. add an attribute -form_id for assigning tags to specific forms.

#use following to limit access to page requests via post.. to reduce vulnerability to url hack and insertion attacks from web:
#if { [ad_conn method] != POST } {
#  ad_script_abort
#}
#also see patch: http://openacs.org/forums/message-view?message_id=182057

ad_proc -public qf_get_inputs_as_array {
    {form_array_name "__form_input_arr"}
} {
    get inputs from form submission, quotes all input values. use ad_unquotehtml to unquote a value.
} {
    upvar $form_array_name __form_input_arr
    # get form variables passed with connection
    set __form [ns_getform]
    if { $__form eq "" } {
        set __form_size 0
    } else {
        set __form_size [ns_set size $__form]
    }
    for { set __form_counter_i 0 } { $__form_counter_i < $__form_size } { incr __form_counter_i } {
        
        # no inserting tcl commands etc!
        if { ![regexp -nocase -- {^[a-z][a-z0-9_\.\:\(\)]*$} [ns_set key $__form $__form_counter_i]] } {
            # let's make this an error for now, so we log any attempts
            ns_log Error "qf_get_inputs_as_array: attempt to insert unallowed characters to user input '{__form_key}'."
            ad_script_abort
        } else {
            # The name of the argument passed in the form
            # no legitimate argument should be affected by quoting:
            set __form_key [ad_quotehtml [ns_set key $__form $__form_counter_i]]
        }

        # This is the value
        set __form_input [ad_quotehtml [ns_set value $__form $__form_counter_i]]
        if { [info exists --form_input_arr($__form_key) ] } {
            if { $__form_input ne $__form_input_arr($__form_key) } {
                # which one is correct? log error
                ns_log Error "qf_get_form_input: form input error. duplcate key provided for ${__form_key}"
                ad_script_abort
            } else {
                ns_log Warning "qf_get_form_input: notice, form has two keys with same info.."
            }
        } else {
            set __form_input_arr($__form_key) $__form_input
        }
        # next key-value pair
    }
}

ad_proc -public qf_remember_attributes {
} {
    changes qf_* form building procs to use the previous attribute values used with the last tag of same type (input,select,button etc).
} {
    upvar __qf_remember_attributes __qf_remember_attributes
    set __qf_remember_attributes 1
}

ad_proc -public qf_open { 
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
    {arg13 ""}
    {arg14 ""}
    {arg15 ""}
    {arg16 ""}

} {
    initiates a form with form tag and supplied attributes. Returns an id. A clumsy url based id is provided if not passed (not recommended).
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar __form_ids_list __form_ids_list, __form_arr __form_arr
    upvar __form_ids_open_list __form_ids_open_list
    upvar __qf_remember_attributes __qf_remember_attributes, __qf_arr __qf_arr

    set attributes_full_list [list action class id method name style target title]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16]
    set arrtibutes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attriubte_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } else {
            ns_log Error "qf_open: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }
    if { ![info exists attributes_arr(method)] } {
        set attributes_arr(method) "post"
    }

    if { ![info exists __qf_remember_attributes] } {
        set __qf_remember_attributes 0
    }
    if { ![info exists __form_ids_list] } {
        set __form_ids_list [list]
    }
    if { ![info exists __form_ids_open_list] } {
        set __form_ids_open_list [list]
    }
    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(form_$attribute)] } {
                set attriubtes_arr($attribute) $__qf_arr(form_$attribute)
            } 
        }
    }
    # every form gets an id, if only to help identify it in debugging
    if { ![info exists attributes_arr(id) || $attributes_arr(id) eq "" } { 
        set attributes_arr(id) "[ad_conn url]-[llength $__form_ids_list]"
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        set __qf_arr(form_$attribute) $attributes_arr($attribute)
        # if a form tag requires an attribute, the following test needs to  be forced true
        if { $attributes_arr($attribute) ne "" } {
            lappend tag_attributes_list $attribute $attributes_arr($attribute)
        }
    }
    
    set tag_html "<form[qf_insert_attributes $tag_attributes_list]>"
    # set results  __form_arr 
    append __form_arr($id) "$tag_html\n"
    if { [lsearch $__form_ids_list $attributes_arr(id)] == -1 } {
        lappend __form_ids_list $attributes_arr(id)

    }
    if { [lsearch $__form_ids_open_list $attributes_arr(id)] == -1 } {
        lappend __form_ids_open_list $attributes_arr(id)
    }
    return $attributes_arr(id)
}


ad_proc -public qf_fieldset { 
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
} {
    starts a form fieldset by appending a fieldset tag.  Fieldset closes when form closed or another fieldset defined in same form.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar __form_ids_list __form_ids_list, __form_arr __form_arr
    upvar __qf_remember_attributes __qf_remember_attributes, __qf_arr __qf_arr
    upvar __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    set attributes_full_list [list align class id style title valign]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12]
    set arrtibutes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attriubte_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } else {
            ns_log Error "qf_fieldset: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_fieldset: invoked before qf_form or used in a different namespace than qf_form.."
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_fieldset: invoked before qf_form or used in a different namespace than qf_form.."
    }
    # default to last modified form id
    if { ![info exists attributes_arr(id)] || $attributes_arr(id) eq "" } { 
        set attributes_arr(id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(id)] == -1 } {
        ns_log Error "qf_fieldset: unknown form id $attributes_arr(id)"
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(fieldset_$attribute)] } {
                set attriubtes_arr($attribute) $__qf_arr(form_$attribute)
            }
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        set __qf_arr(fieldset_$attribute) $attributes_arr($attribute)
        lappend tag_attributes_list $attribute $attributes_arr($attribute)
    }
    set tag_html ""
    set previous_fs 0
    # first close any existing fieldset tag with form id
    set __fieldset_open_list_exists [info exists __form_ids_fieldset_open_list]
    if { $__fieldset_open_list_exists } {
        if { [lsearch $__form_ids_fieldset_open_list $attributes_arr(id)] > -1 } {
            append tag_html "</fieldset>\n"
            set previous_fs 1
        }
    }
    append tag_html "<fieldset[qf_insert_attributes $tag_attributes_list]>"

    # set results __form_ids_fieldset_open_list
    if { $previous_fs } {
        # no changes needed, "fieldset open" already indicated
    } else {
        if { $__fieldset_open_list_exists } {
            lappend __form_ids_fieldset_open_list $attributes_arr(id)
        } else {
            set __form_ids_fieldset_open_list [list $attributes_arr(id)]
        }
    }
    # set results  __form_arr, we checked form id above.
    append __form_arr($attributes_arr(id)) "$tag_html\n"

}

ad_proc -public qf_textarea { 
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
    {arg13 ""}
    {arg14 ""}
    {arg15 ""}
    {arg16 ""}
    {arg17 ""}
    {arg18 ""}
    {arg19 ""}
    {arg20 ""}
    {arg21 ""}
    {arg22 ""}
    {arg23 ""}
    {arg24 ""}
    {arg25 ""}
    {arg26 ""}
} {
    creates a form textarea tag, supplying attributes where nonempty values are supplied.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar __form_ids_list __form_ids_list, __form_arr __form_arr
    upvar __qf_remember_attributes __qf_remember_attributes, __qf_arr __qf_arr
    upvar __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    set attributes_full_list [list value accesskey align class cols id name readonly rows style tabindex title wrap]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24 $arg25 $arg26]
    set arrtibutes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attriubte_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } else {
            ns_log Error "qf_textarea: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_textarea: invoked before qf_form or used in a different namespace than qf_form.."
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_textarea: invoked before qf_form or used in a different namespace than qf_form.."
    }
    # default to last modified form id
    if { ![info exists attributes_arr(id)] || $attributes_arr(id) eq "" } { 
        set id $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(id)] == -1 } {
        ns_log Error "qf_textarea: unknown form id $attributes_arr(id)"
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && $attribute ne "value" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(textarea_$attribute)] } {
                set attriubtes_arr($attribute) $__qf_arr(textarea_$attribute)
            }
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        if { $attribute ne value } {
            set __qf_arr(textarea_$attribute) $attributes_arr($attribute)
            lappend tag_attributes_list $attribute $attributes_arr($attribute)
        } 
    }
    set tag_html "<textarea[qf_insert_attributes $tag_attributes_list]>$value</textarea>"
    # set results  __form_arr, we checked form id above.
    append __form_arr($attributes_arr(id)) "${tag_html}\n"
     
}

ad_proc -public qf_select { 
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
    {arg13 ""}
    {arg14 ""}
    {arg15 ""}
    {arg16 ""}
    {arg17 ""}
    {arg18 ""}
    {arg19 ""}
    {arg20 ""}
    {arg21 ""}
    {arg22 ""}
} {
    creates a form select/options tag, supplying attributes where nonempty values are supplied. set multiple to 1 to activate multiple attribute.
    "value" argument is a list_of_lists passed to qf_options, where the list_of_lists represents a list of OPTION tag attribute/value pairs. 
    Alternate to passing "value", you can pass pure html containing literal Option tags as "value_html"
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar __form_ids_list __form_ids_list, __form_arr __form_arr
    upvar __qf_remember_attributes __qf_remember_attributes, __qf_arr __qf_arr
    upvar __form_ids_select_open_list __form_ids_select_open_list

    set attributes_full_list [list value accesskey align class cols id name readonly rows style tabindex title wrap]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22]
    set arrtibutes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attriubte_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } else {
            ns_log Error "qf_select: [string range $attribute 0 15] is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_select: invoked before qf_form or used in a different namespace than qf_form.."
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_select: invoked before qf_form or used in a different namespace than qf_form.."
    }
    # default to last modified form id
    if { ![info exists attributes_arr(id)] || $attributes_arr(id) eq "" } { 
        set id $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(id)] == -1 } {
        ns_log Error "qf_select: unknown form id $attributes_arr(id)"
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && $attribute ne "value" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(select_$attribute)] } {
                set attriubtes_arr($attribute) $__qf_arr(select_$attribute)
            }
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        if { $attribute ne value } {
            set __qf_arr(select_$attribute) $attributes_arr($attribute)
            lappend tag_attributes_list $attribute $attributes_arr($attribute)
        } 
    }


    set tag_html ""
    set previous_select 0
    # first close any existing selects tag with form id
    set __select_open_list_exists [info exists __form_ids_select_open_list]
    if { $__select_open_list_exists } {
        if { [lsearch $__form_ids_select_open_list $attributes_arr(id)] > -1 } {
            append tag_html "</select>\n"
            set previous_select 1
        }
    }
    # set results __form_ids_select_open_list
    if { $previous_select } {
        # no changes needed, "select open" already indicated
    } else {
        if { $__select_open_list_exists } {
            lappend __form_ids_select_open_list $attributes_arr(id)
        } else {
            set __form_ids_select_open_list [list $attributes_arr(id)]
        }
    }

    # add options tag
    if { [info exists attributes_arr(value_html)] } {
        set value_list_html $attributes_arr(value_html)
    } else {
        set value_list_html ""
    }
    if { [info exists attributes_arr(value)] } {
        append value_list_html [qf_options $attributes_arr(value)]
    }

    append tag_html "<select[qf_insert_attributes $tag_attributes_list]>$value_list_html"
    # set results  __form_arr, we checked form id above.
    append __form_arr($attributes_arr(id)) "${tag_html}\n"

}

ad_proc -private qf_options {
    {options_list_of_lists ""}
} {
    Returns the sequence of options tags usually associated with SELECT tag. 
    Does not append to an open form. These results are usually passed to qf_select that appends an open form.
    Option tags are added in sequentail order. A blank list in a list_of_lists is ignored. 
    To add a blank option, include the value attribute with a blank/empty value; 
    The option tag will wrap an attribute called "name".  
    To indicate "SELECTED" attribute, include the attribute "selected" with the paired value of 1.
} {
    # options_list is expected to be a list like this:
    # \[list \[list attribute1 value attribute2 value attribute3 value attribute4 value attribute5 value...\] \[list {second option tag attribute-value pairs} etc\] \]

    # for this proc, we need to check the individual options for each OPTION tag, to provide the most flexibility.
    set list_length [llength $options_list_of_lists]
    # is this a list of lists, or just a list (1 list of list)
    # test the second row to see if it has multiple list members
    set multiple_option_tags_p [expr { [llength [lindex $options_list_of_lists 1] ] > 1 } ]
    if { $list_length > 1 && $multiple_option_tags_p == 0 } {
        # options_list is malformed, by providing only a list, not list of lists, adjust it:
        set options_list_of_lists [list $options_list_of_lists]
    }

    set options_html ""
    foreach option_tag_attribute_list $options_lists_of_lists {
        append options_html [qf_option $option_tag_attribute_list]
    }
    return $options_html
}

ad_proc -private qf_option {
    {option_attributes_list ""}
} {
    returns an OPTION tag usually associated with SELECT tag. Does not append to an open form. These results are usually passed to qf_select that appends an open form.
    Creates only one option tag. For multiple OPTION tags, see qf_options
    To add a blank attribute, include attribute with a blank/empty value; 
    The option tag will wrap an attribute called "name".  
    To indicate "SELECTED" attribute, include the attribute "selected" with the paired value of 1.
} {

    set attributes_full_list [list class dir disabled id label lang language selected style title value name]
    set arg_list $option_attributes_list
    set arrtibutes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attriubte_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } else {
            ns_log Error "qf_options: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        if { $attribute ne name && $attribute ne selected } {
            lappend tag_attributes_list $attribute $attributes_arr($attribute)
        } 
    }

    if { [info exists attributes_arr(name)] } {
        set name_html $attributes_arr(name)
    } else {
        set name_html ""
    }
    if { [info exists attributes_arr(selected)] && $attributes_arr(selected) == 1 } {
        set option_html "<option[qf_insert_attributes $tag_attributes_list] selected>$name_html</option>\n"
    } else {
        set option_html "<option[qf_insert_attributes $tag_attributes_list]>$name_html</option>\n"
    }
    return $option_html
}


ad_proc -public qf_close { 
    {arg1 ""}
    {arg2 ""}
} {
    closes a form by appending a close form tag (and fieldset tag if any are open). if id supplied, only closes that referenced form and any fieldsets associated with it.  
} {
    # use upvar to set form content, set/change defaults
    upvar __form_ids_list __form_ids_list, __form_arr __form_arr
    upvar __form_ids_open_list __form_ids_open_list
    upvar __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    set attributes_full_list [list id]
    set arg_list [list $arg1 $arg2]
    set arrtibutes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attriubte_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } else {
            ns_log Error "qf_close: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }

    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_close: invoked before qf_form or used in a different namespace than qf_form.."
    }
    # default to all open ids
    if { ![info exists attributes_arr(id)] || $attributes_arr(id) eq "" } { 
        set attributes_arr(id) $__form_ids_open_list
    }
    # attributes_arr(id) might be a list or a single value. Following loop should work either way.

    # close chosen id(s) 
    foreach id $attributes_arr(id) {
        # check if id is valid
            set form_id_position [lsearch $__form_ids_list $attributes_arr(id)]
        if { $form_id_position == -1 } {
            ns_log Warning "qf_close: unknown form id $attributes_arr(id)"
        } else {
            # close fieldset tag if form has an open one.
            set form_id_fs_position [lsearch $__form_ids_fieldset_open_list $id]
            if { $form_id_fs_position > -1 } {
                append __form_arr($id) "</fieldset>\n"
                # remove id from __form_ids_fieldset_open_list
                set __form_ids_fieldset_open_list [lreplace $__form_ids_fieldset_open_list $form_id_fs_position $form_id_fs_position]
            }
            # close form
            append __form_arr($id) "</form>\n"    
            # remove id from __form_ids_open_list            
            set __form_ids_open_list [lreplace $__form_ids_open_list $form_id_position $form_id_position]

        }

    }

}

ad_proc -public qf_read { 
    {-id ""}
} {

    returns the content of forms. If the form is not closed, returns the form in its partial state of completeness. If an id is supplied, returns the content of a specific form.
} {
# use upvar to set form content, set/change defaults
    return 
}


ad_proc -public qf_input {
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
    {arg7 ""}
    {arg8 ""}
    {arg9 ""}
    {arg10 ""}
    {arg11 ""}
    {arg12 ""}
    {arg13 ""}
    {arg14 ""}
    {arg15 ""}
    {arg16 ""}
    {arg17 ""}
    {arg18 ""}
    {arg19 ""}
    {arg20 ""}
    {arg21 ""}
    {arg22 ""}
    {arg23 ""}
    {arg24 ""}
    {arg25 ""}
    {arg26 ""}
    {arg27 ""}
    {arg28 ""}
    {arg29 ""}
    {arg30 ""}
    {arg31 ""}
    {arg32 ""}
} {
    creates a form input tag, supplying attributes where nonempty values are supplied. when using CHECKED, set the attribute to 1.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar __form_ids_list __form_ids_list, __form_arr __form_arr
    upvar __qf_remember_attributes __qf_remember_attributes, __qf_arr __qf_arr
    upvar __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    set attributes_full_list [list type accesskey align alt border checked class id maxlength name readonly size src tabindex value form_id]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24 $arg25 $arg26 $arg27 $arg28 $arg29 $arg30 $arg31 $arg32]
    set arrtibutes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attriubte_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } else {
            ns_log Error "qf_input: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_input: invoked before qf_form or used in a different namespace than qf_form.."
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_input: invoked before qf_form or used in a different namespace than qf_form.."
    }
    # default to last modified form id
    if { ![info exists attributes_arr(form_id)] || $attributes_arr(form_id) eq "" } { 
        set form_id $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_input: unknown form id $attributes_arr(id)"
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && $attribute ne "value" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(input_$attribute)] } {
                set attriubtes_arr($attribute) $__qf_arr(input_$attribute)
            }
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        if { $attribute ne value } {
            set __qf_arr(input_$attribute) $attributes_arr($attribute)
            lappend tag_attributes_list $attribute $attributes_arr($attribute)
        } 
    }
    set tag_html "<input[qf_insert_attributes $tag_attributes_list]>$value</textarea>"
    # set results  __form_arr, we checked form id above.
    append __form_arr($attributes_arr(form_id)) "${tag_html}\n"
     
    return 
}

ad_proc -public qf_insert_html { 
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
} {
    inserts html in a form by appending supplied html. if form_id supplied, appends form with supplied form_id.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar __form_ids_list __form_ids_list, __form_arr __form_arr
    upvar __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    set attributes_full_list [list html form_id]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6]
    set arrtibutes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attriubte_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } else {
            ns_log Error "qf_insert_html: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }

    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_insert_html: invoked before qf_form or used in a different namespace than qf_form.."
    }
    # default to last modified form id
    if { ![info exists attributes_arr(form_id)] || $attributes_arr(form_id) eq "" } { 
        set form_id $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_insert_html: unknown form id $attributes_arr(id)"
    }

    # set results  __form_arr, we checked form id above.
    append __form_arr($attributes_arr(form_id)) $attributes_arr(html)
    return 
}

ad_proc -private qf_insert_attributes {
    args_list
 } {
    returns args_list of tag attribute pairs (attribute,value) as html to be inserted into a tag
 } {
     set args_html ""
     foreach {attribute value} $args_list {
         if { [string range $attribute 1 1] eq "-" } {
             set $attribute [string range $attribute 2 end]
         }
         regsub {[^\\]"} $value {\"} value
         # " clearing quote in previous line to fix emacs color rendering error.
         append args_html " $attribute=\"$value\""
     }
     return $args_html
 }

ad_proc -public qf_choice {
    form_id
    type
    args_list_of_lists
 } {
    returns html of a select/option bar or radio button list (where only 1 value is returned to a posted form).
     type is "select" for select bar, or "radio" for radio buttons
     args_list_of_lists, each list item contains attribute/value pairs for a button or option/bar item
     required attributes:  name, value
     selected is not required, default is not selected, set selected to 1 to show selected.
     if label not provided, value is used for label.
 } {
     # if $type = select, then items are option tags wrapped by a select tag
     # if $type = radio, then items are input tags, wrapped in a list for now
     # if needing to paginate radio buttons, build the radio buttons using qf_input directly.
     set args_html ""
     foreach {attribute value} $args_list {
         if { [string range $attribute 1 1] eq "-" } {
             set $attribute [string range $attribute 2 end]
         }
         regsub {[^\\]"} $value {\"} value
         # " clearing quote in previous line to fix emacs color rendering error.
         append args_html " $attribute=\"$value\""
     }
     return $args_html
 }

ad_proc -public qf_choices {
    form_id
    type
    args_list_of_lists
 } {
     returns html of a multiple select/option menu or checkbox list (where multiple values can be returned to a posted form).
     type is "select" for select menu, or "checkbox" for checkboxes
     args_list_of_lists, each list item contains attribute/value pairs for a button or option/bar item
     required attributes:  name, value.
     selected is not required, default is not selected, set selected to 1 to show selected. 
     if label not provided, value is used for label.
 } {
     # if $type = select, then items are option tags wrapped by a select tag
     # if $type = checkbox, then items are input tags, wrapped in a list for now
     # if needing to paginate checkbuttons, build the checkbox lists using qf_input directly.
     set args_html ""
     foreach {attribute value} $args_list {
         if { [string range $attribute 1 1] eq "-" } {
             set $attribute [string range $attribute 2 end]
         }
         regsub {[^\\]"} $value {\"} value
         # " clearing quote in previous line to fix emacs color rendering error.
         append args_html " $attribute=\"$value\""
     }
     return $args_html
 }
