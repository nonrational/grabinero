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

});