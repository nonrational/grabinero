$(document).ready(function(){
	//show/hide initial forms
    $('.askform, .solicitform').hide();


    function coolRunnings(primary, secondary){
        var startingHidden = $(primary).is(':hidden');

        $(primary).slideToggle(function(){});
        $(secondary).slideUp();
        if(!startingHidden){
            $('article.main').fadeTo(250, 1)
        } else {
            $('article.main').fadeTo(250, .5)        }
    }
    

    $('.askopen').click( function() {
        coolRunnings('.askform', '.solicitform');
    });

    // click open on right, slide up left and toggle right
    $('.solicitopen').click( function() {
        coolRunnings('.solicitform', '.askform')        
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
