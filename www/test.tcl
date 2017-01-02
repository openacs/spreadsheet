set title TEST

set context [list ]

# oacs-dev=# select table_id,label,id from qss_tips_field_defs where id in ('10769','10767','10768');
#  table_id |     label     |  id   
# ----------+---------------+-------
#     10766 | data_for_txt  | 10767
#     10766 | data_for_vc1k | 10768
#     10766 | data_for_nbr  | 10769
# (3 rows)

# instance_id | table_id | row_id | trashed_p | trashed_by | trashed_dt |            created            | user_id | field_id |           f_vc1k            |      f_nbr       |                                                  f_txt                                                  
#-------------+----------+--------+-----------+------------+------------+-------------------------------+---------+----------+-----------------------------+------------------+---------------------------------------------------------------------------------------------------------
#         147 |    10766 |  10807 | 0         |            |            | 2016-12-15 15:20:48.570363-05 |     689 |    10769 |                             | 1481833248569588 | 
#         147 |    10766 |  10807 | 0         |            |            | 2016-12-15 15:20:48.570363-05 |     689 |    10768 | uranoonen CBrramsotes CBlag |                  | 
#         147 |    10766 |  10807 | 0         |            |            | 2016-12-15 15:20:48.570363-05 |     689 |    10767 |                             |                  | D.s D.f D.nadgadralat D.l D.fayhad D.n D.klytat D.noloshomat D.tef D.f D.gonehonyd D.nyeles D.msyih D.s
#(3 rows)


set user_id [ad_conn user_id]
set instance_id [ad_conn package_id]
set instance_id 147
#qc_pkg_admin_required
#set i 5
#set j 1
#set field_id 10768
#set label "data_for_vc1k"

#set test_row_id 10807
#set t_id_arr(${i}) 10766
#set vc1k_search_val "uranoonen CBrramsotes CBlag"

#set t_label_arr(${i}) "table_1481833247"

#set val_case1 [qss_tips_cell_read $t_label_arr(${i}) [list "data_for_vc1k" $vc1k_search_val] $label]

#set value_by_id [qss_tips_cell_read_by_id $t_id_arr(${i}) $test_row_id $field_id]

#set content "qss_tips_cell_read  $t_label_arr(${i}) [list "data_for_vc1k" $vc1k_search_val] $label <br>
#returns: '${val_case1}' <br> <br>
#qss_tips_cell_read_by_id $t_id_arr(${i}) $test_row_id $field_id <br>
#returns: '${value_by_id}'"
set a [list 3 56 3453]
set b [list 3453 56 7 15]
set content "diff [set_difference $b $a]"
