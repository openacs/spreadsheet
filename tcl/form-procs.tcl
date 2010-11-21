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
    initiates a form with form tag and supplied attributes. Returns an id if one is not provided.
} {
# use upvar to set form content, set/change defaults
upvar __form_ids_list __form_ids_list, __form_last_id __form_last_id, __form_arr __form_arr
# __form_arr contains new forms, with array index (id) __form_arr(id)
    return 
}

ad_proc -public qf_fieldset { 
    {-id ""}
    {-align ""}
    {-class ""}
    {-sytle ""}
    {-title ""}
    {-valign ""}
} {
    starts a form fieldset by appending a fieldset tag. if this id is supplied with form tags, form tags are appended to this fieldset. Fieldset closes when form closed.
} {
# use upvar to set form content, set/change defaults
    return 
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
