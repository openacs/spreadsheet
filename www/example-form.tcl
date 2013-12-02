set title "Contact us - example"
set context [list contact]

set required_html "#acs-templating.required#"
set user_message_list [list]
set validated 0

# input default values
array set input_array [list \
  full_name "" \
  email_address "" \
  subject "" \
  message "Write your message here." \
  submit "" \
  reset "" \
]
array set title_array [list \
  full_name "Name: " \
  email_address "Email: " \
  subject "Subject: " \
  message "Message: " \
  submit "Send" \
  reset "Undo" \
]

set default_array(message) $input_array(message)
# get previous form inputs if they exist
set form_posted [qf_get_inputs_as_array input_array]


if { $form_posted } {
    set validated 1
    # validate input
    set input_array(full_name) [string range [string trim $input_array(full_name)] 0 50]
    set input_array(subject) [string range [string trim $input_array(subject)] 0 80]
    set input_array(email_address) [string range [string trim $input_array(email_address)] 0 80]
    set input_array(message) [string range [string trim $input_array(message)] 0 3000]

    if { [string length $input_array(message)] == 0 || $input_array(message) eq $default_array(message) } {
        append title_array(message) $required_html
        lappend user_message_list "Your message is blank. Please add your message before submitting."
        set validated 0
    }
    if { ![util_email_valid_p $input_array(email_address) ] } {
        append title_array(email_address) "*"
        lappend user_message_list "Please check your email address. It doesn't appear to be in a standard email format."
        set validated 0
    }
# input validation notes
# refer to these pages for some example validation code:
#     acs-tcl/tcl/tcl-documentation-procs.tcl  for general data types including ad_page_contract filters
#     acs-templating/tcl/data-procs.tcl        for generic system types
#     acs-tcl/tcl/utilties-procs.tcl           for misc. validations (tending to throw error if not valid)
#     ecommerce/tcl/ecds-procs.tcl             for some html input processing
#  but remember that these validators are not localized. 
# For localization formats, see acs-lang package, specifically:
#     acs-lang/tcl/locale-procs.tcl        for getting localization info
#     acs-lang/tcl/localization-procs.tcl  for localization formats (incomplete)
# you can also use these directly:
#   util_url_valid_p
#   util_commify_number
#   util_complete_url_p
#   util_email_valid_p
#   ad_var_type_check_dirname_p
#   ad_var_type_check_fail_p
#   ad_var_type_check_integer_p value
#   ad_var_type_check_nocheck_p value
#   ad_var_type_check_noquote_p value
#   ad_var_type_check_number_p value
#   ad_var_type_check_safefilename_p value
#   ad_var_type_check_third_urlv_integer_p args
#   ad_var_type_check_word_p value 
#   util::string_check_urlsafe
#   If not preseting values, this may be useful: value_if_exists

    if { $validated } {
        # execute validated inpute

        # generic content abuse filter
        regsub -all -nocase -- {[^a-zAZ0-9\ \?\!\&\@\.\+\_\n\-\:]} $input_array(message) " " input_array(message)
        regsub -all -nocase -- {[^a-zAZ0-9\ \?\!\&\@\.\+\_\n\-\:]} $input_array(full_name) " " input_array(full_name)
        regsub -all -nocase -- {[^a-zAZ0-9\ \?\!\&\@\.\+\_\n\-\:]} $input_array(email_address) " " input_array(email_address)
        regsub -all -nocase -- {[^a-zAZ0-9\ \?\!\&\@\.\+\_\n\-\:]} $input_array(subject) " " input_array(subject)

        set to [ad_system_owner]
        set from "$input_array(full_name) <${input_array(email_address)}>"
        set subject "via contact form: $input_array(subject)"
        set message_body $input_array(message)
        append message_body "\n\nfrom ip: [ns_conn peeraddr]"

        acs_mail_lite::send -to_addr $to -from_addr $from -subject $subject -body $message_body

        lappend user_message_list "Your message has been sent."
    } 
}

# build form

# a standard place to invoke qf_remember_attributes
qf_form action example-form id i99

qf_input type text value $input_array(full_name) name full_name label $title_array(full_name) id i967 size 40 maxlength 50
qf_append html "<br>"
qf_input type text value $input_array(email_address) name email_address label $title_array(email_address) id i968 size 40 maxlength 80
qf_append html "<br>"
qf_input type text value $input_array(subject) name subject label $title_array(subject) id i969 size 40 maxlength 80
qf_append html "<br>"
qf_textarea name message rows 30 cols 40 label $title_array(message) value $input_array(message)
qf_append html "<br>"
if { $validated == 0 } {
    qf_input type submit value $title_array(submit)
    qf_append html "&nbsp;"
    qf_input type reset value $title_array(reset)
}
qf_append html "&nbsp;"
qf_append html "<a href=\"example-form\">Clear form</a>"
qf_append html "&nbsp;"
qf_input type hidden name validated value $validated
qf_close

set form_html [qf_read ]

set user_message_html ""
foreach user_message $user_message_list {
    append user_message_html "<li>${user_message}</li>"
}