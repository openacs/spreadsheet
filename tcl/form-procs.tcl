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
ad_proc -public qf_get_inputs {
    {-form_array_name __form_input_arr}
} {
    get inputs from form submission
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
        
        # The name of the argument passed in the form
        set __form_key [ns_set key $__form $__form_counter_i]

        # This is the value
        set __form_input [ns_set value $__form $__form_counter_i]
        if { [info exists --form_input_arr($__form_key) ] } {
            if { $__form_input ne $__form_input_arr($__form_key) } {
                # which one is correct? log error
                ns_log Error "qf_get_form_input: form input error. duplcate key provided for ${__form_key}"
                ad_script_abort
            } else {
                ns_log Warning "qf_get_form_input: notice, form has two keys with same info.."
            }
        } else {
            set __form_input_arr($__form_key) [ns_set value $__form $__form_counter_i]
        }
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
    {-action ""}
    {-class ""}
    {-id ""}
    {-method "post"}
    {-name ""}
    {-style ""}
    {-target ""}
    {-title ""}
} {
    initiates a form with form tag and supplied attributes. Returns an id. A clumsy url based id is provided if not passed (not recommended).
} {
    set attributes_list [list action class id method name style target title]
    array set attributes_arr [list action $action class $class id $id method $method name $name style $style target $target title $title]
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar __form_ids_list __form_ids_list, __form_arr __form_arr
    upvar __qf_remember_attributes __qf_remember_attributes, __qf_arr __qf_arr
    if { ![info exists __qf_remember_attributes] } {
        set __qf_remember_attributes 0
    }
    if { ![info exists __form_ids_list] } {
        set __form_ids_list [list]
    }
    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && $attributes_arr($attribute) eq "" && [info exists __qf_arr(form_$attribute)] } {
                set attriubtes_arr($attribute) $__qf_arr(form_$attribute)
            }
        }
    }
    # every form gets an id, if only to help identify it in debugging
    if { $attributes_arr(id) eq "" } { 
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
    if { [lsearch $__form_ids_list $id] == -1 } {
        lappend __form_ids_list $id
    }
    return $attributes_arr(id)
}


ad_proc -public qf_fieldset { 
    {-id ""}
    {-align ""}
    {-class ""}
    {-sytle ""}
    {-title ""}
    {-valign ""}
} {
    starts a form fieldset by appending a fieldset tag.  Fieldset closes when form closed or another fieldset defined in same form.
} {
    set attributes_list [list align class id style title valign]
    array set attributes_arr [list align $align class $class id $id style $style title $title valign $valign]
    # use upvar to set form content, set/change defaults
    # __qf_arr contains last attribute values of tag, indexed by {tag}_attribute, __form_last_id is in __qf_arr(form_id)
    upvar __form_ids_list __form_ids_list, __form_arr __form_arr
    upvar __qf_remember_attributes __qf_remember_attributes, __qf_arr __qf_arr
    upvar __form_ids_fieldset_open_list __form_ids_fieldset_open_list
    if { ![info exists __qf_remember_attributes] } {
        ns_log Error "qf_fieldset: invoked before qf_form or used in a different namespace than qf_form.."
    }
    if { ![info exists __form_ids_list] } {
        ns_log Error "qf_fieldset: invoked before qf_form or used in a different namespace than qf_form.."
    }
    # default to last modified form id
    if { $id eq "" } { 
        set id $__qf_arr(form_id) 
    }
    if { [lsearch $__form_ids_list $id] == -1 } {
        ns_log Error "qf_fieldset: unknown form id $id"
    }

    # use previous tag attribute values?
    if { $__qf_remember_attributes } {
        foreach attribute $attributes_list {
            if { $attribute ne "id" && $attributes_arr($attribute) eq "" && [info exists __qf_arr(fieldset_$attribute)] } {
                set attriubtes_arr($attribute) $__qf_arr(form_$attribute)
            }
        }
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
    set tag_html ""
    set previous_fs 0
    # first close any existing fieldset tag with form id
    set __fieldset_open_list_exists [info exists __form_ids_fieldset_open_list]
    if { $__fieldset_open_list_exists } {
        if { [lsearch $__form_ids_fieldset_open_list $id] > -1 } {
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
            lappend __form_ids_fieldset_open_list $id
        } else {
            set __form_ids_fieldset_open_list [list $id]
        }
    }
    # set results  __form_arr, we checked form id above.
    append __form_arr($id) "$tag_html\n"

}

ad_proc -public qf_textarea { 
    {-value ""}
    {-accesskey ""}
    {-align ""}
    {-cols ""}
    {-class ""}
    {-id ""}
    {-name ""}
    {-readonly ""}
    {-rows ""}
    {-style ""}
    {-tabindex ""}
    {-title ""}
    {-wrap ""}
} {
    creates a form textarea tag, supplying attributes where nonempty values are supplied.
} {
# use upvar to set form content, set/change defaults
    return 
}

ad_proc -public qf_select { 
    {-value_name_list ""}
    {-selected ""}
    {-accesskey ""}
    {-align ""}
    {-class ""}
    {-id ""}
    {-multiple ""}
    {-name ""}
    {-size ""}
    {-style ""}
    {-tabindex ""}
} {
    creates a form select/options tag, supplying attributes where nonempty values are supplied. set multiple to 1 to activate.
} {
# use upvar to set form content, set/change defaults
    return 
}


ad_proc -public qf_close { 
    {-id ""}
} {
    closes a form by appending a close form tag. if id supplied, only closes that referenced form and any fieldsets associated with it.  
} {
# use upvar to set form content, set/change defaults
    return 
}

ad_proc -public qf_read { 
    {-id ""}
} {
    returns the content of forms. If the form is not closed, returns the form in its partial state of completeness. If an id is supplied, returns the content of a specific form.
} {
# use upvar to set form content, set/change defaults
    return 
}


ad_proc -public qf_button {
    {-type ""}
    {-accesskey ""}
    {-class ""}
    {-id ""}
    {-name ""}
    {-tabindex ""}
    {-title ""}
    {-value ""}
} {
    creates a form button tag, supplying attributes where nonempty values are supplied.
} {

# use upvar to set form content, set/change defaults
    return 
}

ad_proc -public qf_input {
    {-type ""}
    {-accesskey ""}
    {-align ""}
    {-alt ""}
    {-border ""}
    {-checked ""}
    {-class ""}
    {-id ""}
    {-maxlength ""}
    {-name ""}
    {-readonly ""}
    {-size ""}
    {-src ""}
    {-tabindex ""}
    {-value ""}
} {
    creates a form input tag, supplying attributes where nonempty values are supplied. when using CHECKED, set the attribute to 1.
} {

# use upvar to set form content, set/change defaults
    return 
}

ad_proc -public qf_insert_html { 
    {html ""}
    {-id ""}
} {
    inserts html in a form by appending supplied html. if id supplied, appends form with supplied id.
} {
# use upvar to set form content, set/change defaults
    return 
}

ad_proc -private qf_insert_attributes {
    args_list
 } {
    returns args_list of tag attribute pairs (attribute,value) as html to be inserted into a tag
 } {
     set html ""
     foreach {attribute value} $args_list {
         if { [string range $attribute 1 1] eq "-" } {
             set $attribute [string range $attribute 2 end]
         }
         append html " $attribute=$value"
     }
     return $html
 }
