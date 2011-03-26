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
# __form_ids_open_list = list that contains ids of forms that are not closed
# __form_ids_fieldset_open_list = list that contains form ids where a fieldset tag is open
# __form_arr contains an array of forms. Each form built as a string by appending tags, indexed by form id, for example __form_arr($id)
# __qf_arr contains last attribute values of a tag (for all forms), indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
# a blank id passed in anything other than qf_form assumes the current (most recent used form_id)

# to fix:  id for nonform tag should not be same as form id. use an attribute "form_id" for assigning tags to specific forms.

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
    upvar 1 $form_array_name __form_input_arr
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
    {arg1 "1"}
} {
    changes qf_* form building procs to use the previous attribute values used with the last tag of same type (input,select,button etc). passing anything other than 0 defaults to 1 (true).
} {
    upvar __qf_remember_attributes __qf_remember_attributes
    if { $arg1 eq 0 } {
        set __qf_remember_attributes 0
    } else {
        set __qf_remember_attributes 1
    }
}

ad_proc -public qf_form { 
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
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __form_ids_open_list __form_ids_open_list
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr

    # if proc was passed a list of parameters, parse
    if { [llength $arg1] > 1 && [llength $arg2] == 0 } {
        set arg1_list $arg1
        set lposition 1
        foreach arg $arg1_list {
            set arg${lposition} $arg
            incr lposition
        }
        unset arg1_list
    }

    set attributes_full_list [list action class id method name style target title]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # ignore
        } else {
            ns_log Error "qf_form: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }
    if { ![info exists attributes_arr(method)] } {
        set attributes_arr(method) "post"
    }

    if { ![info exists __qf_remember_attributes] } {
ns_log Notice "qf_form L134: set __qf_remember_attributes 0"
        set __qf_remember_attributes 0
    }
    if { ![info exists __form_ids_list] } {
ns_log Notice "qf_form L138: set __form_ids_list.."
        set __form_ids_list [list]
    }
    if { ![info exists __form_ids_open_list] } {
        set __form_ids_open_list [list]
    }
    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(form_$attribute)] } {
                set attributes_arr($attribute) $__qf_arr(form_$attribute)
            } 
        }
    }
    # every form gets an id, if only to help identify it in debugging
    if { ![info exists attributes_arr(id) ] || $attributes_arr(id) eq "" } { 
        set attributes_arr(id) "[ad_conn url]-[llength $__form_ids_list]"
ns_log Notice "qf_form: generating form_id $attributes_arr(id)"
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
    append __form_arr($attributes_arr(id)) "$tag_html\n"
    if { [lsearch $__form_ids_list $attributes_arr(id)] == -1 } {
        lappend __form_ids_list $attributes_arr(id)

    }
    if { [lsearch $__form_ids_open_list $attributes_arr(id)] == -1 } {
        lappend __form_ids_open_list $attributes_arr(id)
    }
    set __qf_arr(form_id) $attributes_arr(id)
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
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    # if proc was passed a list of parameters, parse
    if { [llength $arg1] > 1 && [llength $arg2] == 0 } {
        set arg1_list $arg1
        set lposition 1
        foreach arg $arg1_list {
            set arg${lposition} $arg
            incr lposition
        }
        unset arg1_list
    }

    set attributes_full_list [list align class id style title valign]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_fieldset: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_fieldset: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_fieldset: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form id
    if { ![info exists attributes_arr(id)] || $attributes_arr(id) eq "" } { 
        set attributes_arr(id) $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(id)] == -1 } {
        ns_log Error "qf_fieldset: unknown form id $attributes_arr(id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(fieldset_$attribute)] } {
                set attributes_arr($attribute) $__qf_arr(form_$attribute)
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
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    # if proc was passed a list of parameters, parse
    if { [llength $arg1] > 1 && [llength $arg2] == 0 } {
        set arg1_list $arg1
        set lposition 1
        foreach arg $arg1_list {
            set arg${lposition} $arg
            incr lposition
        }
        unset arg1_list
    }

    set attributes_full_list [list value accesskey align class cols id name readonly rows style tabindex title wrap]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24 $arg25 $arg26]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_textarea: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_textarea: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_textarea: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form id
    if { ![info exists attributes_arr(id)] || $attributes_arr(id) eq "" } { 
        set id $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(id)] == -1 } {
        ns_log Error "qf_textarea: unknown form id $attributes_arr(id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && $attribute ne "value" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(textarea_$attribute)] } {
                set attributes_arr($attribute) $__qf_arr(textarea_$attribute)
            }
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        if { $attribute ne "value" } {
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
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_select_open_list __form_ids_select_open_list

    # if proc was passed a list of parameters, parse
    if { [llength $arg1] > 1 && [llength $arg2] == 0 } {
        set arg1_list $arg1
        set lposition 1
        foreach arg $arg1_list {
            set arg${lposition} $arg
            incr lposition
        }
        unset arg1_list
    }

    set attributes_full_list [list value accesskey align class cols id name readonly rows style tabindex title wrap]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_select: [ad_quotehtml [string range $attribute 0 15]] is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_select: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_select: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form id
    if { ![info exists attributes_arr(id)] || $attributes_arr(id) eq "" } { 
        set id $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(id)] == -1 } {
        ns_log Error "qf_select: unknown form id $attributes_arr(id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && $attribute ne "value" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(select_$attribute)] } {
                set attributes_arr($attribute) $__qf_arr(select_$attribute)
            }
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        if { $attribute ne "value" } {
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
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_options: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        if { $attribute ne "name" && $attribute ne "selected" } {
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
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __form_ids_open_list __form_ids_open_list
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    set attributes_full_list [list id]
    set arg_list [list $arg1 $arg2]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_close: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_close: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
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
    {arg1 ""}
    {arg2 ""}
} {

    returns the content of forms. If a form is not closed, returns the form in its partial state of completeness. If an id or form_id is supplied, returns the content of a specific form. Defaults to return all forms in a list.
} {
    # use upvar to set form content, set/change defaults
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr

    set attributes_full_list [list id]
    set arg_list [list $arg1 $arg2]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_read: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_read: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # normalize code using id instead of form_id
    if { [info exists attributes_arr(form_id)] } {
        set attributes_arr(id) $attributes_arr(form_id)
        unset attributes_arr(form_id)
    }
    # defaults to all ids
    if { ![info exists attributes_arr(id)] || $attributes_arr(id) eq "" } { 
        # note, attributes_arr(id) might become a list or a scalar..
        if { [llength $__form_ids_list ] == 1 } {
            set specified_1 1
            set attributes_arr(id) [lindex $__forms_id_list 0]
        } else {
            set specified_1 0
            set attributes_arr(id) $__form_ids_list
        }
    } else {
        set specified_1 1
    }

    if { $specified_1 } {
        # a form specified in argument
        if { ![info exists __form_arr($attriubtes_arr(id)) ] } {
            ns_log Warning "qf_read: unknown form id $attributes_arr(id)"
        } else {
             set form_s $__form_arr($attributes_arr(id))
        }
    } else {
        set forms_list [list]
        foreach id $attributes_arr(id) {
            # check if id is valid
            set form_id_position [lsearch $__form_ids_list $attributes_arr(id)]
            if { $form_id_position == -1 } {
                ns_log Warning "qf_read: unknown form id $attributes_arr(id)"
            } else {
                lappend forms_list $__form_arr($id)
            }
        }
        set form_s $forms_list
    }
    return $form_s
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
    allowed attributes: type accesskey align alt border checked class id maxlength name readonly size src tabindex value.
    other allowed: form_id label. label is used to wrap the input tag with a label tag containing a label that is associated with the input.
    checkbox and radio inputs present label after input tag, other inputs are preceeded by label. Omit label attribute to not use this feature.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    set attributes_full_list [list type accesskey align alt border checked class id maxlength name readonly size src tabindex value form_id label]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24 $arg25 $arg26 $arg27 $arg28 $arg29 $arg30 $arg31 $arg32]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_input: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
        }
    }

    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_input(L801): invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_input:(L805) invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form id
    if { ![info exists attributes_arr(form_id)] || $attributes_arr(form_id) eq "" } { 
        set form_id $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_input: unknown form id $attributes_arr(id)"
        ad_script_abort
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && $attribute ne "value" && ![info exists attributes_arr($attribute)] && [info exists __qf_arr(input_$attribute)] } {
                set attributes_arr($attribute) $__qf_arr(input_$attribute)
            }
        }
    }

    # prepare attributes to process
    set tag_attributes_list [list]
    foreach attribute $attributes_list {
        if { $attribute ne "value" } {
            set __qf_arr(input_$attribute) $attributes_arr($attribute)
            lappend tag_attributes_list $attribute $attributes_arr($attribute)
        } 
    }

    # by default, wrap the input with a label tag for better UI
    if { [info exists attributes_arr(id) ] && [info exists attributes_arr(label)] && [info exists attributes_arr(type) ] && $attributes_arr(type) ne "hidden" } {
        if { $attributes_arr(type) eq "checkbox" || $attributes_arr(type) eq "radio" } {
            set tag_html "<label for=\"${attributes_arr(id)}\"><input[qf_insert_attributes $tag_attributes_list]>$label</label>"
        } else {
            set tag_html "<label for=\"${attributes_arr(id)}\">$label<input[qf_insert_attributes $tag_attributes_list]></label>"
        }
    } else {
        set tag_html "<input[qf_insert_attributes $tag_attributes_list]>$value"
    }

    # set results  __form_arr, we checked form id above.
    append __form_arr($attributes_arr(form_id)) "${tag_html}\n"
     
    return 
}

ad_proc -public qf_insert_html { 
    {arg1 ""}
    {arg2 ""}
    {arg3 ""}
    {arg4 ""}
    {arg5 ""}
    {arg6 ""}
} {
    inserts html in a form by appending supplied html. if form_id supplied, appends form with supplied form_id.
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_fieldset_open_list __form_ids_fieldset_open_list

    set attributes_full_list [list html form_id]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6]
    set attributes_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_insert_html: $attribute is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }

    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_insert_html: invoked before qf_form or used in a different namespace than qf_form.."
        ad_script_abort
    }
    # default to last modified form id
    if { ![info exists attributes_arr(form_id)] || $attributes_arr(form_id) eq "" } { 
        set form_id $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $attributes_arr(form_id)] == -1 } {
        ns_log Error "qf_insert_html: unknown form id $attributes_arr(id)"
        ad_script_abort
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
             set $attribute [string range $attribute 1 end]
         }
         regsub -all -- {\"} $value {\"} value
         append args_html " $attribute=\"$value\""
     }
     return $args_html
}

ad_proc -public qf_choice {
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
} {
    returns html of a select/option bar or radio button list (where only 1 value is returned to a posted form).
     set "type" to "select" for select bar, or "radio" for radio buttons
    
     required attributes:  name, value
     "selected" is not required, default is not selected, set "selected" to 1 to indicate item selected.
     if label not provided, value is used for label.
    "value" argument is a list_of_lists, each list item contains attribute/value pairs for a radio or option/bar item
        where the list_of_lists represents a list of OPTION tag attribute/value pairs. 
} {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_select_open_list __form_ids_select_open_list

    set attributes_full_list [list value accesskey align class cols id name readonly rows style tabindex title wrap type form_id]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24]
    set attributes_list [list]
    set select_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
            if { $attribute ne "type" && $attribute ne "form_id" && $attribute ne "id" } {
                # create a list to pass to qf_select without it balking at unknown parameters
                lappend select_list $attribute $value
            } 
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_select: [string range $attribute 0 15] is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }
    # for passing select_list, we need to change id with form_id, since we left those off, we can just add form_id as id:
    if { [info exists $attributes_arr(form_id) ] } {
        lappend select_list id $attributes_arr(form_id)
    }
    

    # if attributes_arr(type) = select, then items are option tags wrapped by a select tag
    # if attributes_arr(type) = radio, then items are input tags, wrapped in a list for now
    # if needing to paginate radio buttons, build the radio buttons using qf_input directly.

    if { $attributes_arr(type) ne "radio" } {
        set type "select"
    } else {
        set type "radio"
    }
    
    # call qf_select if type is "select" instead of duplicating purpose of that code

    if { $type eq "radio" } {
        # create wrapping tag
        set tag_wrapping "ul"
        set args_html "<${tag_wrapping}"
        foreach {attribute value} $args_list {
            # ignore proc parameters that are not tag attributes
            if { $attribute ne "value" } {
                if { [string range $attribute 1 1] eq "-" } {
                    set $attribute [string range $attribute 1 end]
                }
                # quoting unquoted double quotes in attribute values, so as to not inadvertently break the tag
                regsub -all -- {\"} $value {\"} value

                append args_html " $attribute=\"$value\""
            }
        }
        append args_html ">\n"
        qf_insert_html $attributes_arr(form_id) $args_html
        set args_html ""

        # verify this is a list of lists.
        set list_length [llength $attributes_arr(value)]
        # test on the second input, less chance its a special case
        set second_input_attributes_count [llength [index $attributes_arr(value) 1]]
        if { $list_length > 1 && $second_input_attributes_count < 2 } {
            # a list was passed instead of a list of lists. Adjust..
            set attributes_arr(value) [list $attributes_arr(value)]
        }
        
        foreach input_attributes_list $attributes_arr(value) {
            lappend input_attributes_list form_id $attribute_arr(form_id) 
            qf_input $input_attributes_list
        }

        append args_html "</${tag_wrapping}>"
        qf_insert_html $attributes_arr(form_id) $args_html
    } else {
        set args_html [qf_select $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24]
    }

    
}

ad_proc -public qf_choices {
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
 } {
    returns html of a select/option bar or radio button list (where only 1 value is returned to a posted form).
     set "type" to "select" for select bar, or "checkbox" for checkboxes
    
     required attributes:  name, value
     "selected" is not required, default is not selected, set "selected" to 1 to indicate item selected.
     if label not provided, value is used for label.
    "value" argument is a list_of_lists, each list item contains attribute/value pairs for a radio or option/bar item
        where the list_of_lists represents a list of OPTION tag attribute/value pairs. 
     if label not provided, value is used for label.
 } {
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar 1 __form_ids_list __form_ids_list
    upvar 1 __form_arr __form_arr
    upvar 1 __qf_remember_attributes __qf_remember_attributes
    upvar 1 __qf_arr __qf_arr
    upvar 1 __form_ids_select_open_list __form_ids_select_open_list

    set attributes_full_list [list value accesskey align class cols id name readonly rows style tabindex title wrap type form_id]
    set arg_list [list $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24]
    set attributes_list [list]
    set select_list [list]
    foreach {attribute value} $arg_list {
        set attribute_index [lsearch -exact $attributes_full_list $attribute]
        if { $attribute_index > -1 } {
            set attributes_arr($attribute) $value
            lappend attributes_list $attribute
            if { $attribute ne "type" && $attribute ne "form_id" && $attribute ne "id" } {
                # create a list to pass to qf_select without it balking at unknown parameters
                lappend select_list $attribute $value
            } 
        } elseif { $value eq "" } {
            # do nothing                  
        } else {
            ns_log Error "qf_select: [string range $attribute 0 15] is not a valid attribute. invoke with attribute value pairs. Separate each with a space."
            ad_script_abort
        }
    }
    # for passing select_list, we need to change id with form_id, since we left those off, we can just add form_id as id:
    if { [info exists $attributes_arr(form_id) ] } {
        lappend select_list id $attributes_arr(form_id)
    }
    

    # if attributes_arr(type) = select, then items are option tags wrapped by a select tag
    # if attributes_arr(type) = checkbox, then items are input tags, wrapped in a list for now
    # if needing to paginate checkboxes, build the checkboxes using qf_input directly.

    if { $attributes_arr(type) ne "checkbox" } {
        set type "select"
    } else {
        set type "checkbox"
    }
    
    # call qf_select if type is "select" instead of duplicating purpose of that code

    if { $type eq "checkbox" } {
        # create wrapping tag
        set tag_wrapping "ul"
        set args_html "<${tag_wrapping}"
        foreach {attribute value} $args_list {
            # ignore proc parameters that are not tag attributes
            if { $attribute ne "value" } {
                if { [string range $attribute 1 1] eq "-" } {
                    set $attribute [string range $attribute 1 end]
                }
                # quoting unquoted double quotes in attribute values, so as to not inadvertently break the tag
                regsub -all -- {\"} $value {\"} value
                append args_html " $attribute=\"$value\""
            }
        }
        append args_html ">\n"
        qf_insert_html $attributes_arr(form_id) $args_html
        set args_html ""

        # verify this is a list of lists.
        set list_length [llength $attributes_arr(value)]
        # test on the second input, less chance its a special case
        set second_input_attributes_count [llength [index $attributes_arr(value) 1]]
        if { $list_length > 1 && $second_input_attributes_count < 2 } {
            # a list was passed instead of a list of lists. Adjust..
            set attributes_arr(value) [list $attributes_arr(value)]
        }
        
        foreach input_attributes_list $attributes_arr(value) {
            lappend input_attributes_list form_id $attribute_arr(form_id) 
            qf_input $input_attributes_list
        }

        append args_html "</${tag_wrapping}>"
        qf_insert_html $attributes_arr(form_id) $args_html
    } else {
        set args_html [qf_select $arg1 $arg2 $arg3 $arg4 $arg5 $arg6 $arg7 $arg8 $arg9 $arg10 $arg11 $arg12 $arg13 $arg14 $arg15 $arg16 $arg17 $arg18 $arg19 $arg20 $arg21 $arg22 $arg23 $arg24]
    }

}    
