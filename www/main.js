$(document).ready(function(){
  $('#scrollUp').hide();

  $(document).on('wheel', function(e) {
    e.preventDefault();
    if (e.originalEvent.deltaY < 0) {
      $('#up').trigger('click');
    } else {
      $('#down').trigger('click');
    }
  });

  var touchStartY = null;

  $(document).on('touchstart', function (e) {
    touchStartY = e.originalEvent.touches[0].clientY;
  });

  $(document).on('touchend', function (e) {
    var touchEndY = e.originalEvent.changedTouches[0].clientY;
    var swipeThreshold = 50;

    if (touchStartY - touchEndY > swipeThreshold) {
      $('#down').trigger('click');
    } else if (touchEndY - touchStartY > swipeThreshold) {
      $('#up').trigger('click');
    }
  });

  $('#down').click(function(){
    var currentPage = $('#currentPage').attr('data-page');

    if (currentPage == 1) {
      $('#simulation').slideUp('slow');
      $('#survive').css('display', 'flex');
      $('#survive').slideDown('slow');
      $('#pagetext').text('TRADE DASHBOARD');
      $('#currentPage').text('2');
      $('#currentPage').attr("data-page", "2");
      $('#scrollUp').show();
      $('#scrollDown').show();
    } else if (currentPage == 2) {
      $('#survive').slideUp('slow');
      $('#library').css('display', 'flex');
      $('#library').slideDown('slow');
      $('#pagetext').text('SEARCH COMPANION');
      $('#currentPage').text('3');
      $('#currentPage').attr("data-page", "3");
      $('#scrollDown').hide();
      $('#scrollUp').show();
      $('.nav-spacer').show();
    } /* else if(currentPage == 3) {
      $('#library').slideUp('slow');
      $('#treatment').css('display', 'flex');
      $('#treatment').slideDown('slow');
      $('#pagetext').text('TREATMENT PROTOCOL');
      $('#currentPage').text('4');
      $('#currentPage').attr("data-page", "4");
      $('#scrollUp').show();
      $('#scrollDown').hide();
      $('.nav-spacer').show();
    } */
  });

  $('#up').click(function() {
    var currentPage = $('#currentPage').attr('data-page');

    if (currentPage == 2) {
      $('#survive').slideUp('slow');
      $('#simulation').slideDown('slow');
      $('#pagetext').text('CHAT ASSISTANT');
      $('#currentPage').text('1');
      $('#currentPage').attr("data-page", "1");
      $('#scrollUp').hide();
      $('#scrollDown').show();
    } else if (currentPage == 3) {
      $('#library').slideUp('slow');
      $('#survive').slideDown('slow');
      $('#pagetext').text('TRADE DASHBOARD');
      $('#currentPage').text('2');
      $('#currentPage').attr("data-page", "2");
      $('#scrollUp').show();
      $('#scrollDown').show();
      $('.nav-spacer').hide();
    } /* else if (currentPage == 4) {
      $('#treatment').slideUp('slow');
      $('#library').slideDown('slow');
      $('#pagetext').text('SEARCH COMPANION');
      $('#currentPage').text('3');
      $('#currentPage').attr("data-page", "3");
      $('#scrollUp').show();
      $('#scrollDown').show();
      $('.nav-spacer').hide();
    } */
  });

  $(".selected-option").click(function(event) {
    event.stopPropagation();
    const options = $(".options");
    const arrowIcon = $(".arrow-icon");
    if (options.is(":visible")) {
      options.slideUp();
      arrowIcon.attr("src", "icons/chevron-down-64px-03.svg");
    } else {
      options.slideDown();
      arrowIcon.attr("src", "icons/chevron-up-64px-03.svg");
    }
  });

  $(".option").click(function() {
    const selectedOption = $(".selected-option");
    const optionValue = $(this).data("value");
    const optionText = $(this).text();
    const arrowIcon = $(".arrow-icon");
    selectedOption.html(optionText + arrowIcon[0].outerHTML);
    selectedOption.attr("data-value", optionValue);
    $(".options").slideUp();
    arrowIcon.attr("src", "icons/chevron-down-64px-03.svg");
  });

  $(document).click(function() {
    $(".options").slideUp();
    $(".arrow-icon").attr("src", "icons/chevron-down-64px-03.svg");
  });




  $('#protocol').click(function() {
    $('#twinwrapper, #geneticprofile, #pharmaceutical').slideUp('slow');
    $('#protocolwrapper').slideDown('slow');
    $('#protocol').addClass('dash-active');
    $('#twin, #geneticprofile, #pharmaceutical').removeClass('dash-active');
  });

  $('#twin').click(function(){
    $('#protocolwrapper, #geneticprofile, #pharmaceutical').slideUp('slow');
    $('#twinwrapper').slideDown('slow');
    $('#twin').addClass('dash-active');
    $('#protocol, #geneticprofile, #pharmaceutical').removeClass('dash-active');
  });

  $('#pharma').click(function() {
    $('#protocolwrapper, #twinwrapper, #geneticprofile').slideUp('slow');
    $('#pharmaceutical').slideDown('slow');
    $('#pharmaceutical').addClass('dash-active');
    $('#protocol, #twin, #geneticprofile').removeClass('dash-active');
  });

  $('#genetic').click(function() {
    $('#protocolwrapper, #twinwrapper, #pharmaceutical').slideUp('slow');
    $('#geneticprofile').slideDown('slow');
    $('#geneticprofile').addClass('dash-active');
    $('#protocol, #twin, #pharmaceutical').removeClass('dash-active');
  });
});


