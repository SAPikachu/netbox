function server_invoke(module_name, function_name, data, on_success, on_error) {
    on_success = on_success || function() {};
    on_error = on_error || function() {};
    $.post(
        "/modules/" + module_name + "/" + function_name,
        data,
        on_success,
        "json"
    ).error(on_error);
};

$(function() {
    server_invoke("openvpn", "get_configuration", function(data) {
        server_list_control = $("#openvpn-select-server");
        $.each(data.servers, function(i, value) {
            $("<option/>").
                text(value).
                attr("value", value).
                appendTo(server_list_control);
        });
        server_list_control.val(data.selected_server);
        $("#openvpn-save").click(function(e) {
            e.preventDefault();
            server_invoke(
                "openvpn", 
                "select_server", 
                {server_name: server_list_control.val()}
            );
        });
    });  
});
