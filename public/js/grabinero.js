$(document).ready(function(){
	//show/hide initial forms
    $('.askform').hide();
    $('.askopen').click( function() {
        $('.askform').slideToggle();
        $('.solicitform').slideUp();
        //these are for fading out the table, doesn't work properly
        //$('article.main').toggleClass('fadeout');
    });
    $('.solicitform').hide();
    $('.solicitopen').click( function() {
        $('.solicitform').slideToggle();
        $('.askform').slideUp();
        //$('article.main').toggleClass('fadeout');
    });

    //show/hide action buttons
    $('.requesteditems .action').hide();
    $('.requesteditems tr').hover( function(e) {
        $(e.currentTarget).find('.action').show();
    }, function() {
        $('.requesteditems .action').hide();
    });

    //show/hide promised form
    $('.requesteditems .promised .dropdown').hide();
    $('.requesteditems .promised .action').click( function(e) {
        $(e.currentTarget).parent().find('.dropdown').slideDown();
    });

    $('.finish-send').click(function(e){
        e.preventDefault();
        window.open($(e.currentTarget).data('url'));
    });

    $('.login-link').click(function(e){
        e.preventDefault();
        window.location = '/login';
    });
});
