function convertToCSV(data){
    if (!data || data.length === 0){
        return("data:text/csv;charset=utf-8,");
    }
    var csv = [Object.keys(data[0]).slice(0).join(", ")];
    data.forEach(
        function(item){
            csv.push(
                Object.values(item).map(
                    function(val){
                        return(isNaN(val) ? '"' + val + '"' : val)
                    }
                ).join(", ")
            )
        }
    )
    csv = csv.join("\n");
    return("data:text/csv;charset=utf-8," + escape(csv));
}

// CONFIG X AXIS SPACING HERE
var middle_timeframes = [
    "2019",
    "Q12020",
    "Aug 2019"
];
var starting_quarters = ["Q1"];

var pal = {
    "blue1": "#893f90",
    "blue2": "#c189bb",
    "blue3": "#a45ea1",
    "blue4": "#a9a6aa",
    "blue5": "#7b3b89",
    "blue6": "#551f65"
  };

function draw_table(this_data,table_number,selector_configs){
    var this_data_table = []
    this_data.filter(function(d){return  (d['value'] != 0)}).forEach(
        function(x){
            var newObj = {}
            for (var k in x){newObj[k]=x[k]};
            console.log(x);
            newObj['value'] = (x['value'] / 1000).toFixed(2);
            this_data_table.push(newObj);
        }
    )
    var dict = {
        country: "Country",
        org_type: "Organisation type",
        flow_type: "Flow type",
        transaction_type: "Transaction type",
        year: "Year",
        quarter: "Quarter",
        month: "Month",
        aggregate_type: "Aggregate type",
        variable: "Variable",
        value: "Value",
        timeframe: "Timeframe",
        rollingyear : "Rolling year"
      };
    var wanted_variables = ["flow_type", "transaction_type","variable","value","timeframe"];
    var additional_variables = []    
    if (selector_configs[1]['current_selection']=="Yearly"){additional_variables = additional_variables.concat("year")};
    if (selector_configs[1]['current_selection']=="Quarterly"){additional_variables = additional_variables.concat("quarter")};
    if (selector_configs[1]['current_selection']=="Year to date"){additional_variables = additional_variables.concat("rollingyear")};
    console.log(additional_variables);
    var preceding_variables = []    
    if (selector_configs[3]['current_selection']=="Organisation type"){preceding_variables = preceding_variables.concat("org_type")};
    if (selector_configs[3]['current_selection']=="Specific donor"){preceding_variables = preceding_variables.concat("country")};
    var header = Object.keys(this_data_table[0])
    header = wanted_variables.concat(additional_variables)
    header = preceding_variables.concat(header)
    var tabledata = this_data_table.map( Object.values)
    var check_var = Object.keys(this_data_table[0])
    var indexing = header.map(function(word) { return check_var.indexOf(word); })
    tabledata.forEach(function(array,i) {tabledata[i] = indexing.map(x => array[x]); })
    header = header.map(el => dict[el]);
    var table = d3.select("#table"+table_number)
        .append("table")
    table
        .append("thead")
        .append("tr")
        .selectAll("th")
              .data(header).enter()
              .append("th")
              .text(function(d) { return d; });
    table
    .append("tbody")
    .selectAll("tr")
        .data(tabledata).enter()
        .append("tr")
      
    .selectAll("td")
        .data(function(d) { return d; }).enter()
        .append("td")
        .text(function(d) { return d; });
}


function draw_dependent_selectors(chart_id, parent_name, parent_selection, selector_configs,margin2, width2, height2,chart_config,data){
    selector_configs.forEach(function(child, config_index){
        if (Object.keys(child).includes("selector_type_dependency")){
            var dependent_name = Object.keys(child.selector_type_dependency)[0];
            if(parent_name == dependent_name){ var selector_type = child.selector_type_dependency[dependent_name][parent_selection[0]];
                selector_configs[config_index].selector_type = selector_type;
                var child_element = child.element._groups[0][0];
                if(selector_type == "dropdown"){
                    var newItem = document.createElement('select');
                }else if(selector_type == "radio" || selector_type == "checkbox"){
                    var newItem = document.createElement('div');
                }
                child_element.parentNode.replaceChild(newItem,child_element);
                selector_configs[config_index].element = d3.select(newItem);
                child.element = d3.select(newItem);
                selector_configs[config_index].element.on("change", function(d){
                    set_selections(chart_id,selector_configs, config_index,margin2, width2, height2,chart_config,data);
                    var filtered_data = subset_data(data, selector_configs);
                    d3.select("#"+chart_id+"-dl").attr("href", convertToCSV(filtered_data));
                    erase_chart(chart_id);
                    draw_bar_chart(filtered_data, chart_id, margin2, width2, height2, chart_config,selector_configs);
                })
            }
        }
        if(!Array.isArray(child.order)){
            var child_column_name = child.column_name;
            var child_element = child.element;
            var dependent_name = Object.keys(child.order)[0];
            if(!(child.selector_type == "dropdown" || child.selector_type == "checkbox")){
                var selector_type = child.selector_type[dependent_name][parent_selection[0]];
            } else {var selector_type = child.selector_type;}
            if(parent_name == dependent_name){ // Something is dependent on me
                var new_config_order = child.order[dependent_name][parent_selection[0]];
                var new_config_defaults = child.defaults[dependent_name][parent_selection[0]];
                child_element.selectAll("*").remove()
                if(selector_type == "dropdown"){
                    // Draw dropdown
                    child_element.attr("class", "data-selector data-selector--active").attr("name", chart_id+"_"+child_column_name+"_dropdown");
                    child_element
                    .selectAll("option")
                    .data(new_config_order)
                    .enter()
                    .append("option")
                    .text(function (d) { return d; })
                    .attr("value", function (d) { return d; })
                    .attr("selected", function (d) {
                        if(new_config_defaults !== undefined && new_config_defaults.includes(d)){return true}
                    });
                }else if(selector_type == "radio" || selector_type == "checkbox"){
                    // Draw radio/checkbox inputs and labels
                    for(var i = 0; i < new_config_order.length; i++){
                        column_value = new_config_order[i]
                        child_element
                        .append("input")
                        .attr("value", column_value)
                        .attr("id", column_value+"_"+chart_id+"_"+child_column_name+"_radio")
                        .attr("type", selector_type)
                        .attr("name", chart_id+"_"+child_column_name+"_radio")
                        .attr("checked", 
                            (new_config_defaults !== undefined && new_config_defaults.includes(column_value)) ? true : undefined
                        )
                        .attr("dy","0.5em")
                        child_element
                        .append('label')
                        .attr("for", column_value+"_"+chart_id+"_"+child_column_name+"_radio")
                        .text(column_value);
                    };           
                }
                selector_configs[config_index].current_selection = new_config_defaults;
            }
        }
    });
}

function set_selections(chart_id, selector_configs, config_index,margin2, width2, height2,chart_config,data){
    var selector_element = selector_configs[config_index].element;
    var selector_type = selector_configs[config_index].selector_type;
    var column_name = selector_configs[config_index].column_name;
    if(selector_type == "dropdown"){
        var new_selection = [selector_element.property("value")];
    }else if(selector_type == "radio" || selector_type == "checkbox"){
        var new_selection = selector_element.selectAll("input:checked").nodes().map(function(d){return d.value});
    }
    if (new_selection == "Proportion" & selector_configs[config_index].current_selection == "Volume"){
        selector_configs.forEach(function(d){
            if(d.selector_type == "checkbox" || d.selector_type == "radio"){
                if (!Array.isArray(d.order)){
                    var dependent_name = Object.keys(d.order)[0];
                    var result = selector_configs.filter(function(x) { return x.column_name == dependent_name })[0];
                    d.element.selectAll("input")._groups[0].forEach( function(d2) {
                        if (d.defaults[dependent_name][result.current_selection[0]].includes(d2.value)){d2.checked=true} else{d2.checked=false}
                    })
                    var defaults = d.defaults;
                } else {
                    d.element.selectAll("input")._groups[0].forEach( function(d2) {
                        if (d.defaults.includes(d2.value)){d2.checked=true} else{d2.checked=false}
                    })
                    var defaults = d.defaults;
                }
                d.current_selection=defaults
            }
        });
    }
    draw_dependent_selectors(chart_id, column_name, new_selection, selector_configs,margin2, width2, height2,chart_config,data);
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
        if (!Array.isArray(selector_config.order)){
            var dependent_name = Object.keys(selector_config.order)[0];
            var result = selector_configs.filter(function(x) { return x.column_name == dependent_name })[0];
            var config_order = selector_config.order[dependent_name][result.current_selection[0]];
            var config_defaults = selector_config.defaults[dependent_name][result.current_selection[0]];
            if(!(selector_type == "dropdown" || selector_type == "checkbox")){
                var selector_type = selector_type[dependent_name][result.current_selection[0]];
            }
        } else {
            var config_order = selector_config.order;
            var config_defaults = selector_config.defaults
        }

        // Find unique column values from data
        var column_values = d3.map(data, function(d){return(d[column_name])}).keys();
        // Reorder column values if "order" is specified, otherwise set "order"
        if(config_order){
            column_values = config_order.filter(function(item){return column_values.includes(item)});
        }else{
            selector_configs[config_index].order = column_values;
        }
        var controlWrapper = chartNode
            .append("div")
        if(Object.keys(selector_config).includes("control_class")){
            var control_class = selector_config.control_class;
        }else{
            var control_class = "spacing";
        }
        controlWrapper.attr("class", control_class)
        if(Object.keys(selector_config).includes("control_title")){
            controlWrapper.append("h3").attr("class","control-title").text(selector_config.control_title)
        }
        if(Object.keys(selector_config).includes("control_info")){
            controlWrapper.append("span").attr("class","ui-icon ui-icon-info").attr("title",selector_config.control_info)
        }
        if(selector_type == "dropdown"){
            // Draw dropdown
            var dropdown = controlWrapper.append("select").attr("class", "data-selector data-selector--active");
            dropdown.attr("name", chart_id+"_"+column_name+"_dropdown");
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
            var radio = controlWrapper.append("div");
            for(var i = 0; i < column_values.length; i++){
                column_value = column_values[i]
                var radio_pair = radio.append("nobr");
                radio_pair
                .append("input")
                .attr("value", column_value)
                .attr("id", column_value+"_"+chart_id+"_"+column_name+"_radio")
                .attr("type", selector_type)
                .attr("name", chart_id+"_"+column_name+"_radio")
                .attr("checked", 
                    (config_defaults !== undefined && config_defaults.includes(column_value)) ? true : undefined
                )
                .attr("dy","0.5em")
                radio_pair
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
    })
}

function subset_data(data, selector_configs){
    var filtered_data = data;
    // Filter data for each current selection in selector_configs
    selector_configs.forEach(function(selector_config){
        if (!Array.isArray(selector_config.current_selection)){
            var dependent_name = Object.keys(selector_config.order)[0];
            var result = selector_configs.filter(function(x) { return x.column_name == dependent_name })[0];
            filtered_data = filtered_data.filter(function(d){
                return(selector_config.current_selection[dependent_name][result.current_selection[0]].includes(d[selector_config.column_name]))
            })
            filtered_data = filtered_data.slice().sort((a, b) => d3.ascending(a.org_type, b.org_type))
        } else {
            filtered_data = filtered_data.filter(function(d){
                return(selector_config.current_selection.includes(d[selector_config.column_name]))
            })
            filtered_data = filtered_data.slice().sort((a, b) => d3.ascending(a.org_type, b.org_type))
        }
    });
    return(filtered_data);
}

function draw_bar_chart(data, chart_id, margin, width, height, chart_config, selector_configs){
    var month_abbv = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    data.forEach(function(d, d_index){
        if(d["timeframe"] == "Yearly"){
            data[d_index]["year_org"] = [d["org_type"], d["year"], "", d["timeframe"]].join("_")
        }else if(d["timeframe"] == "Quarterly"){
            data[d_index]["year_org"] = [d["org_type"], "Q" + d["quarter"], d["year"], d["timeframe"]].join("_")
        }else if(d["timeframe"] == "Year to date"){
            var tf_split = d["rollingyear"].split("-")
            var year_1 = parseInt(tf_split[0])-1;
            var year_2 = year_1 + 1;
            var month_idx_1 = parseInt(tf_split[1]);
            var month_1 = month_abbv[month_idx_1];
            var month_idx_2 = month_idx_1 - 1;
            if(month_idx_2 < 0){
                month_idx_2 = 11;
                year_2 -= 1;
            }
            var month_2 = month_abbv[month_idx_2]
            var tf_str_1 = month_1 + " " + year_1;
            var tf_str_2 = "to " + month_2 + " " + year_2;
            data[d_index]["year_org"] = [d["org_type"], tf_str_1, tf_str_2, d["timeframe"]].join("_")
        }
     });

     var data_total = d3.nest().key(function(d){
        return d.year_org; })
    .rollup(function(leaves){
        return d3.sum(leaves, function(d){
            return d.value;
        });
    }).entries(data)
    .map(function(d){
        return { year_org: d.key, total: d.value};
    });
    var result0 = selector_configs.filter(function(x) { return x.column_name == "flow_type" })[0];
    var result1 = selector_configs.filter(function(x) { return x.column_name == "measure" })[0];
    if (typeof result0.current_selection.length == 'undefined'){
        var result0 = result0.current_selection.measure[result1.current_selection[0]]
    } else {
        var result0 = result0.current_selection 
    }
    var result2 = selector_configs.filter(function(x) { return x.column_name == "variable" })[0];
    var data_wide = d3.nest()
     .key(function(d) { return d["year_org"] })
     .rollup(function(d) { 
       return d.reduce(function(prev, curr) {
         prev["year_org"] = curr["year_org"];
         prev[curr["flow_type"]] = curr["value"];
         return prev;
       }, {});
     }).entries(data)
     .map(function(d) { 
        return d.value;
      });
      var index;
      for(index=1;index<data_wide.length;index++){
          if (data_wide[index].year_org.split("_")[0]!=data_wide[index-1].year_org.split("_")[0]){
              const empty_array = Object.assign({}, data_wide[index]);
                for (const property in result0) {
                    empty_array[result0[property]] = "";
                };
              empty_array.year_org=data_wide[index-1].year_org.split("_")[0];
              data_wide.splice(index,0,empty_array); index = index +1}
       };

    var chartNode = d3.select("#" + chart_id);
    var svg = chartNode
        .append("svg")
            .attr('preserveAspectRatio', 'xMinYMin meet')
            .attr("viewBox", "0 0 " + (width + margin.left + margin.right) + " " + (height + margin.top + margin.bottom))
            .attr("style","background-color: white;")
        .append("g")
            .attr("transform","translate(" + margin.left + "," + margin.top + ")");
    var y = d3.scaleLinear()
            .rangeRound([height, 0]);
    var x = d3.scaleBand()
            .rangeRound([0, width])
            .padding(0.1)
            .align(0.4);
    var xAxis = d3.axisBottom(x)
    .tickFormat(function(d){ 
        var split_arr = d.split("_");
        var org_type = split_arr[0];
        var timestr_1 = split_arr[1];
        var timestr_2 = split_arr[2];
        var time_type = split_arr[3];
        console.log(split_arr);

        if(time_type == "Quarterly"){
            if(middle_timeframes.includes(timestr_1 + timestr_2)){
                if(starting_quarters.includes(timestr_1)){
                    return([timestr_1, timestr_2, org_type].join("_"))
                }else{
                    return([timestr_1, "", org_type].join("_"))
                }
            }else{
                if(starting_quarters.includes(timestr_1)){
                    return([timestr_1, timestr_2].join("_"))
                }else{
                    return([timestr_1, ""].join("_"))
                }
            }
        }else{
            if(middle_timeframes.includes(timestr_1)){
                return([timestr_1, timestr_2, org_type].join("_"))
            }else{
                return([timestr_1, timestr_2].join("_"))
            }
        }
    }).tickSize(0)
    var z = chart_config.colour_axis_scale;
    var keys = result0;
    x.domain(data_wide.map(function(d) { return d.year_org; }));
    y.domain([0, d3.max(data_total, function(d) { return d.total; })]).nice();

    var y_formatter = chart_config.y_axis_scale.variable[result2["current_selection"]];
    var yAxis = d3.axisLeft().ticks(6).scale(y).tickSize(0).tickSizeInner(-width).tickFormat( function(d) { return y_formatter(d) } );

    svg.append("g")
    .attr("class", "xaxis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis)
    .selectAll("g")
          .call(function(t){                
              t.each(function(d){ // for each one
              var self = d3.select(this);
              var s = self.text().split('_');  // get the text and split it
              self.text(''); // clear it out
              self.append("text") // insert two tspans
                .attr("x", 0)
                .attr("dy", "1.1em")
                .style("text-anchor", "middle")
                .text(s[0]);
              self.append("text")
                  .attr("x", 0)
                  .attr("dy","2.2em")
                  .style("text-anchor", "middle")
                  .text(s[1]);
              self.append("text")
                  .attr("class", "bold-text")
                  .attr("x", 0)
                  .attr("dy","3.3em")
                  .style("text-anchor", "middle")
                  .text(s[2]);
              })
          });

  svg.append("g")
    .attr("class", "yaxis")
    .call(yAxis);

    var data_wide = d3.stack().keys(keys)(data_wide)
    data_wide.forEach(function(d, d_index){
        d.forEach(function(i){
        i["key"] = data_wide[d_index]["key"]
        })
     });

    var tooltip_formatter = chart_config.tooltip_type.variable[result2["current_selection"]];
    svg.append("g")
      .selectAll("g")
      .data(data_wide)
      .enter().append("g")
        .attr("fill", function(d) { return z(d.key); })
      .selectAll("rect")
      .data(function(d) {return d; })
      .enter().append("rect")
        .attr("x", function(d) {  return x(d.data.year_org); })
        .attr("y", function(d) {   return y(d[1]); })
        .attr("height", function(d) { return y(d[0]) - y(d[1]); })
        .attr("width", x.bandwidth())
      .on("mouseover", function() { tooltip.style("display", null); tooltipBackground.style("display", null); })
      .on("mouseout", function() { tooltip.style("display", "none"); tooltipBackground.style("display", "none"); })
      .on("mousemove", function(d) {
        var xPosition = d3.mouse(this)[0]+5;
        var yPosition = d3.mouse(this)[1];
        tooltip.attr("x", xPosition).attr("y", yPosition);
        tooltip_line0.attr("x", xPosition);
        tooltip_line1.attr("x", xPosition);
        tooltip_line2.attr("x", xPosition);
        tooltip_line0.text(d.key);
        var y_org_split = d.data.year_org.split("_");
        tooltip_line1.text([y_org_split[0], y_org_split[1], y_org_split[2]].join(" "));
        tooltip_line2.text(tooltip_formatter(d))
        var tooltip_bbox = tooltip.node().getBBox();
          tooltipBackground
          .attr("x",tooltip_bbox.x - 2)
          .attr("y",tooltip_bbox.y - 2)
          .attr("height", tooltip_bbox.height + 4)
          .attr("width", tooltip_bbox.width + 4)
          .style("opacity","0.8"); 
      });
    svg.append("text")
      .attr("transform", "rotate(-90)")
      .attr("y", 0-margin.left)
      .attr("x",0 - (height / 1.8))
      .attr("dy", "1em")
      .attr('class','yaxistitle')
      .style("text-anchor", "middle")
      .text(chart_config.y_axis_label["variable"][selector_configs[1]["current_selection"]]);
    var legend = svg.append("g")
        .attr("class", "axis")
        .attr("text-anchor", "start")
        .attr("transform", "translate(" + (5 - margin.left) + ", " + (5 - margin.top) + ")")

    var previous_offset_x = 50;
    var previous_offset_y = 0;
    var element_ruler = d3.select(".element_ruler");
    element_ruler
        .attr('preserveAspectRatio', 'xMinYMin meet')
        .attr("viewBox", "0 0 " + (width + margin.left + margin.right) + " " + (height + margin.top + margin.bottom))
    var element_ruler_text = element_ruler.select("text");
    for(var i=0; i < keys.length; i++){
        var d = keys[i];
        
        var legend_item = legend.append("g")
            .attr("transform", "translate(" + previous_offset_x + ", " + previous_offset_y + ")");

        legend_item.append("rect")
            .attr("x", 0)
            .attr("width", 12)
            .attr("height", 12)
            .attr("fill", z(d))
      
        legend_item.append("text")
            .attr("x", 19)
            .attr("y", 7)
            .attr("dy", "0.32em")
            .text(d);
        element_ruler_text.text(d);
        element_ruler_text.attr("style",
            "font-size:10px;font-weight:100;font-family:'Averta',sans-serif;"
        )
        var text_ruler_bbox = element_ruler_text.node().getBBox();
        previous_offset_x += text_ruler_bbox.width + 29;
        if(previous_offset_x >= (width - (margin.left + margin.right))){
            previous_offset_x = 0;
            previous_offset_y += 25;
        }
    }
    // Readjust if necessary
    var legend_height = (25 + previous_offset_y);
    chartNode.select("svg").attr("viewBox", "0 0 " + (width + margin.left + margin.right) + " " + (height + margin.top + margin.bottom + legend_height))
    svg.attr("transform","translate(" + margin.left + "," + (margin.top + legend_height) + ")");
    legend.attr("transform", "translate(" + (5 - margin.left) + ", " + (5 - margin.top - legend_height) + ")")
    
    var tooltipBackground = svg.append("rect")
        .attr("class","tooltip-bg")
        .attr("fill","white");

    var tooltip = svg.append("text")
        .attr("class", "tooltip")
        .attr("x", 0)
        .attr("y", 0)
        .attr("dy", "1.2em")
        .style("text-anchor", "left")
        .attr("font-size", "12px")
        .attr("font-weight", "normal")
        .style("fill", "#443e42")
        .style("display", "none");

    var tooltip_line0 = tooltip.append("tspan")
        .attr("x", 0)
        .attr("dy", "1.2em");
    var tooltip_line1 = tooltip.append("tspan")
        .attr("x", 0)
        .attr("dy", "1.2em");
    var tooltip_line2 = tooltip.append("tspan")
        .attr("x", 0)
        .attr("dy", "1.2em");

    var no_data = data.filter(function(d){return(d.value != 0)}).length == 0;
    var neg_data = data.filter(function(d){return(d.value < 0)}).length > 0;
    if(no_data){
        svg
        .append("text")
        .attr("x", width / 2)
        .attr("y", height / 2)
        .attr("text-anchor", "middle")
        .text("No data available in selection.")
    }else{
        if (neg_data){
            d3.select("#" + chart_id + "-note")
            .text("Note: Some of the data selected contains negative values. For more detail, download the data and read our methodology.");
        }else{
            d3.select("#" + chart_id + "-note")
            .text("");
        }
    }
}

function erase_chart(chart_id){
    var svg = d3.select("#" + chart_id).select("svg");
    svg.remove();
}

function erase_table(table_id){
    var svg = d3.select("#" + table_id).select("table");
    svg.remove();
}
