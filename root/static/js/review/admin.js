function set_paid(url) {

  var form_div = $('#div_form');
  form_div.load(url, function() {

    $('#div_form form').ajaxForm({
      url: url,
      beforeSubmit: validate_form,
      success: function() {
        $('#div_form').dialog('close');
        window.reload();
      }

    });

    //Display dialog
    $('#div_form').dialog('open');

  });
}

function validate_form() {
  myform = $("#div_form form");
  myform.validate();

  if (myform.valid()) {
    return true;
  }
  else {
    return false;
  }
}



function confirm_score(score,formid) {
    
        $( "#dialog-confirm" ).html('Deseja dar a nota '+ score +' ao resumo? Lembre-se que a nota não pode ser mudada posteriormente!');
        $( "#dialog-confirm" ).dialog({
            
            resizable: false,
            height:140,
            modal: true,
            buttons: {
                "Confirmar": function() {
                    $('#'+formid).submit();
                    $( this ).dialog( "close" );
                },
                Cancelar: function() {
                    
                    $('#'+formid+' select').val('');
                    $( this ).dialog( "close" );
                }
            }
        });
}

function info(url) {
    
        $( "#dialog-info" ).load(url);
        $( "#dialog-info" ).dialog({
            
            resizable: true,
            height: 400,
            width: 800,
            modal: true,
            buttons: {
                "Fechar": function() {
                    $( this ).dialog( "close" );
                }
            }
        });
}


function approve_poster(url) {
    
        $( "#dialog-approve-poster" ).dialog({
            resizable: false,
            height:140,
            modal: true,
            buttons: {
                "Approve": function() {
                    window.location.replace(url);
                    $( this ).dialog( "close" );
                },
                Cancel: function() {
                    $( this ).dialog( "close" );
                }
            }
        });
}
