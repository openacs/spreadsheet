<master>

<div style="float: left; width: 500px;">
<if @user_message_html@ not nil>
   <ul>
    @user_message_html;noquote@
   </ul>
</if>
<h3>@title@</h3>
  <div style="text-align: right;">

@form_html;noquote@
  </div>
</div>
