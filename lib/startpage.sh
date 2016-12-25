# 7

read -r -d '' WEB_MAINJS <<"EOM"
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

/*
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
*/
$(document).ready(function(){
    $("#content").linklist();
//    $("#impressum").impress();
});

EOM


read -r -d '' WEB_HTML <<"EOM"
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- The above 3 meta tags *must* come first in the head; any other head content must come *after* these tags -->
    <title>Landingpage</title>

    <!-- Bootstrap -->
    <link href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet">

    <!-- HTML5 shim and Respond.js for IE8 support of HTML5 elements and media queries -->
    <!-- WARNING: Respond.js doesn't work if you view the page via file:// -->
    <!--[if lt IE 9]>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/html5shiv/3.7.3/html5shiv.min.js"></script>
      <script src="https://cdnjs.cloudflare.com/ajax/libs/respond.js/1.4.2/respond.min.js"></script>
    <![endif]-->
    <style>
         ul {
             list-style-type: none;
         }
         li {
             float:left;
             padding:20px;
         }
    </style>
    <script>
      var dataurl="DATASOURCE"
    </script>
  </head>
  <body>
<div class="container">

    <div class="jumbotron">
         <h1>landingpage</h1>
         <p class="lead"></p>
    </div>
    <div class="container">

       <ul id="content">
         <li><a style="height:150px" class="btn btn-info" href="FIRSTLINK"><br><div style="width:100px;height:100px">FIRSTTITLE</div></a></li>

       </ul>
</div>

</div><!--/.container-->
   <hr>

   <footer>
     <p>&copy; 2015 Company, Inc.</p>
     <div id="impressum"></div>
   </footer>

    <!-- jQuery (necessary for Bootstrap's JavaScript plugins) -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.0/jquery.min.js"></script>
    <!--<script src="https://cdnjs.cloudflare.com/ajax/libs/jquery/2.2.0/jquery.min.js"></script>-->
    <!-- Include all compiled plugins (below), or include individual files as needed -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.3.7/js/bootstrap.min.js"></script>
    <script src="main.js"></script>
  </body>
</html>

EOM
