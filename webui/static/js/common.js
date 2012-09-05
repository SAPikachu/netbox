function nop() {}

function show_modal(header_text, body, actions, show_close_button) {
    var modal = $("#modal");
    modal.find(".modal-header h3").text(header_text);
    var body_elem = modal.find(".modal-body");
    if (typeof body === "string") {
        body_elem.html(body);
    } else {
        body_elem.children().remove();
        body_elem.append(body);
    }
    var footer = modal.find(".modal-footer");
    footer.children().remove();
    $.each(actions || {}, function(i, action) {
        $("<a/>").
            attr("href", "#").
            addClass("btn").
            text(action.text).
            click(action.callback).
            appendTo(footer);
    });
    modal.find(".close").toggle(!!show_close_button);
    modal.modal({
        backdrop: "static",
        keyboard: false
    });
}

function hide_modal() {
    $("#modal").modal("hide");
}

function server_invoke(module_name, function_name, data, on_success, on_error, silent) {
    on_success = on_success || nop;
    on_error = on_error || nop;

    var _show_modal = silent ? nop : show_modal;
    var _hide_modal = silent ? nop : hide_modal;

    _show_modal(
        "Calling " + module_name + "." + function_name,
        '<div class="progress progress-striped active"><div class="bar" style="width: 100%;"></div></div>'
    );

    return $.ajax({
        type: "POST",
        url: "/modules/" + module_name + "/" + function_name,
        data: data,
        dataType: "json",
        success: function() {
            _hide_modal();
            on_success.apply(this, arguments);
        },
        error: function(xhr, status, message) {
            _show_modal(
                "Failed to call " + module_name + "." + function_name,
                $("<div/>").text(status + ": " + message)
            );
            on_error.apply(this, arguments);
        }
    });
};

