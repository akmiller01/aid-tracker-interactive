function set_selections(selector_configs, config_index){
    var selector_element = selector_configs[config_index].element;
    var selector_type = selector_configs[config_index].selector_type;
    if(selector_type == "dropdown"){
        var new_selection = [selector_element.property("value")];
    }else if(selector_type == "radio" || selector_type == "checkbox"){
        var new_selection = selector_element.selectAll("input:checked").nodes().map(function(d){return d.value});
    }
    selector_configs[config_index].current_selection = new_selection;
}

function add_selectors(chart_id, data, selector_configs){
    // Select chart node by ID
    var chartNode = d3.select("#" + chart_id);
    // Iterate over config objects
    selector_configs.forEach(function(selector_config, config_index){
        // Grab expected configurations from object
        var column_name = selector_config.column_name;
        var selector_type = selector_config.selector_type;
        var config_order = selector_config.order;
        var config_defaults = selector_config.defaults;
        // Find unique column values from data
        var column_values = d3.map(data, function(d){return(d[column_name])}).keys();
        // Reorder column values if "order" is specified, otherwise set "order"
        if(config_order){
            column_values = config_order.filter(function(item){return column_values.includes(item)});
        }else{
            selector_configs[config_index].order = column_values;
        }
        if(selector_type == "dropdown"){
            // Draw dropdown
            var dropdown = chartNode
            .append("select");
            dropdown
            .selectAll("option")
            .data(column_values)
            .enter()
            .append("option")
            .text(function (d) { return d; })
            .attr("value", function (d) { return d; })
            .attr("selected", function (d) {
                if(config_defaults !== undefined && config_defaults.includes(d)){return true}
            });
            // Set "element" in parent object for later reference
            selector_configs[config_index].element = dropdown;
            // Set "defaults" as first column value if not set
            if(!config_defaults){
                selector_configs[config_index].defaults = [column_values[0]];
            }
        }else if(selector_type == "radio" || selector_type == "checkbox"){
            // Draw radio/checkbox inputs and labels
            var radio = chartNode
            .append("div");
            for(var i = 0; i < column_values.length; i++){
                column_value = column_values[i]
                radio
                .append("input")
                .attr("value", column_value)
                .attr("id", column_value+"_"+chart_id+"_"+column_name+"_radio")
                .attr("type", selector_type)
                .attr("name", chart_id+"_"+column_name+"_radio")
                .attr("checked", 
                    (config_defaults !== undefined && config_defaults.includes(column_value)) ? true : undefined
                );
                radio
                .append('label')
                .attr("for", column_value+"_"+chart_id+"_"+column_name+"_radio")
                .text(column_value);
            };
            // Set "element" in parent object for later reference
            selector_configs[config_index].element = radio;
            // Set "defaults" as all column values if not set
            if(!config_defaults){
                selector_configs[config_index].defaults = column_values;
            }
        }
        // Set "current_seletion"
        selector_configs[config_index].current_selection = selector_configs[config_index].defaults;
        // Setup on change events. TODO: Set this up in a draw_chart function instead, so it can subset data, redraw charts
        selector_configs[config_index].element.on("change", function(d){
            set_selections(selector_configs, config_index);
            console.log(selector_configs[config_index].current_selection);
        })
    })
}

function subset_data(data, selector_configs){
    var filtered_data = data;
    // Filter data for each current selection in selector_configs
    selector_configs.forEach(function(selector_config){
        filtered_data = filtered_data.filter(function(d){
            return(selector_config.current_selection.includes(d[selector_config.column_name]))
        })
    });
    return(filtered_data);
}