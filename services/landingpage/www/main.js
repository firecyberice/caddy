jQuery.fn.extend({
    linklist: function (kwargs) {
        var self = $(this);
        $.ajax({
            url: dataurl,
            async:true,
            contentType:"application/json",
            dataType: "json",
            success: function(data){
                $.each(data, function(key, attributes){
                 var my_link = (typeof attributes['link'] != 'undefined') ? attributes['link'] : "";
                 var my_button = (typeof attributes['button'] != 'undefined') ? attributes['button'] : "";
                 var my_name = (typeof attributes['name'] != 'undefined') ? attributes['name'] : "";
                 var my_image = ((typeof attributes['image'] != 'undefined') && (attributes['image'] == "empty")) ? my_name : attributes['image'];

                 var new_div = $("<li>");
                        var new_anchor = $("<a>");
                        $(new_anchor).attr("href", my_link);
                        $(new_anchor).addClass("btn");
                        $(new_anchor).addClass(my_button);
                        $(new_anchor).attr("style", "height:150px");
                            if ((typeof my_image != 'undefined') && (my_image != "empty")) {
                                var new_content = $("<span>");
                                if (my_image != my_name) {
                                     $(new_anchor).html(my_name);
                                     new_content = $("<img>");
                                     $(new_content).addClass("img-responsive");
                                     $(new_content).attr("src", my_image);
                                }else{
                                    var new_br = $("<br>");
                                    $(new_br).appendTo(new_anchor);
                                    new_content = $("<div>");
                                    $(new_content).attr("style", "width:100px;height:100px");
                                    $(new_content).html(my_name);
                                }
                                $(new_content).appendTo(new_anchor);
                            }
                        $(new_anchor).appendTo(new_div);
                        console.log(new_div);
                    $(new_div).appendTo(self);
                });
            }
        });
    }
});

jQuery.fn.extend({
    impress: function (kwargs) {
        var self = $(this);
        $.ajax({
            url: "vcf/api.php",
            async:true,
            contentType:"text/html",
            dataType: "html",
            success: function(data){
                $(self).html(data);
            }
        });
    }
});

$(document).ready(function(){
    $("#content").linklist();
    $("#impressum").impress();
});
