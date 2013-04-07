$(document).ready(function(){
	//show/hide initial forms
    $('.askform').hide();
    $('.askopen').click( function() {
        $('.askform').slideToggle();

    });
    $('.solicitform').hide();
    $('.solicitopen').click( function() {
        $('.solicitform').slideToggle();

    });

    //show/hide action buttons
    $('.requesteditems .action').hide();
    $('.requesteditems tr').hover( function() {
        $('.requesteditems .action').show();
    }, function() {
        $('.requesteditems .action').hide();
    });

 //    //show/hide login fields
	// $('.show_login').click( function() {
 //        $('.login').slideToggle();
 //        //$('.show_login').fadeOut('1000');
 //    });
 //    $('.close_login').click( function() {
 //        $('.login').slideToggle();
 //        //$('.show_login').show();
        
 //    });
	
	// //show/hide site map in footer
	// $('a.sitemap').click(function(o){
	// 	$('section.sitemap').slideToggle(400);
	// });
	
 //    $(".social-component").click(
 //        function(o){ var t = $(o.target).data("service"); $(".social-box").hide(); $(".social-box." + t).fadeIn(275); return false; }
 //    );
 //    $("span.youtube-uploads").youTubeChannel({userName:"betterment",channel:"uploads",numberToDisplay:1,linksInNewWindow:true});
 //    $('.backtotop a').click(
 //        function () { $('body,html').animate({ scrollTop: 0 }, 800); return false; }
 //    );

});