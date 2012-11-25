$(function() {
    server_invoke("openvpn", "get_configuration", {}, function(data) {
        var server_list_control = $("#openvpn-select-server");
        var port_control = $("#openvpn-port");
        $.each(data.servers, function(i, value) {
            $("<option/>").
                text(value).
                attr("value", value).
                appendTo(server_list_control);
        });
        server_list_control.val(data.selected_server);
        if (data.selected_port) {
            port_control.val(data.selected_port);
        }
        $("#openvpn-save").click(function(e) {
            e.preventDefault();
            server_invoke(
                "openvpn", 
                "select_server", 
                {
                    server_name: server_list_control.val(),
                    port: port_control.val()
                }
            );
        });
        var state_control = $("#openvpn-state");
        var status_snapshot = {};
        function calculate_status(raw_data) {
            status = {
                time: new Date(),
                download_actual: parseInt(raw_data["TUN/TAP write bytes"]),
                download_all: parseInt(raw_data["TCP/UDP read bytes"]),
                upload_actual: parseInt(raw_data["TUN/TAP read bytes"]),
                upload_all: parseInt(raw_data["TCP/UDP write bytes"]),
            };
            time_delta = (status.time - status_snapshot.time) / 1000.0;
            status.download_speed_actual = 
                (status.download_actual - 
                 status_snapshot.download_actual) /
                time_delta;
            status.download_speed_all = 
                (status.download_all - 
                 status_snapshot.download_all) /
                time_delta;
            status.upload_speed_actual = 
                (status.upload_actual - 
                 status_snapshot.upload_actual) /
                time_delta;
            status.upload_speed_all = 
                (status.upload_all - 
                 status_snapshot.upload_all) /
                time_delta;
                
            status_snapshot = status;
            return status;
        }
        function add_field(name, value) {
            $("<dt/>").text(name).appendTo(state_control);
            $("<dd/>").text(value).appendTo(state_control);
        }
        function is_all_number(vars) {
            var ret = true;
            $.each(vars, function(i, value) {
                if ((typeof value != "number") || !isFinite(value)) {
                    ret = false;
                }
            });
            return ret;
        }
        function number_to_display(num) {
            suffixes = [" B", " KB", " MB", "GB", " TB"];
            suffix_index = 0;
            while (num > 1024 && suffix_index < suffixes.length - 1) {
                num /= 1024;
                suffix_index++;
            }
            num = Math.round(num * 100) / 100;
            return num + suffixes[suffix_index];
        }
        function add_status_field(status, display_prefix) {
            prefix = display_prefix.toLowerCase();
            amount_all = status[prefix + "_all"];
            amount_actual = status[prefix + "_actual"];
            speed_all = status[prefix + "_speed_all"];
            speed_actual = status[prefix + "_speed_actual"];
            if (!is_all_number(
                [amount_all, amount_actual, speed_all, speed_actual]
            )) {
                return;
            }
            add_field(
                display_prefix + "ed", 
                number_to_display(amount_all) + " (" + 
                    number_to_display(amount_actual) + " actual data)"
            );
            add_field(
                display_prefix + " speed", 
                number_to_display(speed_all) + "/s (" + 
                    number_to_display(speed_actual) + "/s actual)"
            );
        }
        function set_state_display(state_data) {
            state_control.children().remove();
            add_field("State", state_data.state);
            if (state_data["status_data"]) {
                status = calculate_status(state_data.status_data);
                add_status_field(status, "Download");
                add_status_field(status, "Upload");
            }
        };
        function refresh_state() {
            server_invoke(
                "openvpn", "get_status", null, 
                function (data) {
                    set_state_display(data);
                }, 
                function () {
                    set_state_display({state: "ERROR"});
                }, 
                true
            ).complete(function() { setTimeout(refresh_state, 5000) });
        };
        refresh_state()
    });  
});
