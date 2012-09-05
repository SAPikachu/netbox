$(function() {
    var table = $("#connection-list");
    var tbody = table.find("tbody");
    var cell_headers = table.find(".header-main th");

    var sorter = new Tablesort(table[0]);

    function refresh() {
        server_invoke("connections", "get_connections", {}, function(data) {

            tbody.children().remove();
            $.each(data, function() {
                var conn = this;
                var row = $("<tr/>");
                cell_headers.each(function() {
                    var key = $(this).data("key");
                    var value = conn;
                    var key_parts = key.split(".");
                    for (var i = 0; i < key_parts.length; i++) {
                        if (value) {
                            value = value[key_parts[i]] || "";
                        }
                    }
                    $("<td/>").text(value).appendTo(row);
                });
                row.appendTo(tbody);
            });
            var sorted_header = table.find(".sort-up, .sort-down");
            if (sorted_header.size()) {
                var is_up = sorted_header.hasClass("sort-up");
                sorted_header.removeClass("sort-up sort-down");
                sorted_header.addClass(is_up ? "sort-down" : "sort-up");
                sorted_header.click();
            }

            setTimeout(refresh, 1000);
        }, null, true);
    };

    refresh();
});
