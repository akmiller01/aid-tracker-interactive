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

function draw_bar_chart(data, chart_id, margin, width, height,chart_config){
    data.forEach(function(d, d_index){
        data[d_index]["year_org"] = d["org_type"] + d["year"]
     })
    var data_wide = d3.nest()
     .key(function(d) { return d["year_org"] }) // sort by key
     .rollup(function(d) { // do this to each grouping
       // reduce takes a list and returns one value
       // in this case, the list is all the grouped elements
       // and the final value is an object with keys
       return d.reduce(function(prev, curr) {
         prev["year_org"] = curr["year_org"];
         prev[curr["flow_type"]] = curr["value"];
         return prev;
       }, {});
     }).entries(data)
     .map(function(d) { // pull out only the values
        return d.value;
      }); // tell it what data to process

    var chartNode = d3.select("#" + chart_id);
    var svg = chartNode
    .append("svg")
      .attr('preserveAspectRatio', 'xMinYMin meet')
      .attr("viewBox", "0 0 " + (width + margin.left + margin.right) + " " + (height + margin.top + margin.bottom))
      .attr("style","background-color: white;")
    .append("g")
      .attr("transform",
            "translate(" + margin.left + "," + margin.top + ")");
    var y = d3.scaleLinear()
            .rangeRound([height, 0]);
    
    // var yAxis = d3.axisLeft().ticks(5).scale(y).tickSize(0).tickSizeOuter(0).tickSizeInner(-width).tickFormat( function(d) { return d } );
    //       svg.append("g")
    //         .attr('class', 'yaxis')
    //         .call(yAxis);
    var x = d3.scaleBand()
            .rangeRound([0, width])
            .paddingInner(0.05)
            .align(0.1);
    // var xAxis = d3.axisBottom(x).tickValues(data.map(function(d){ return d.year_org })).tickFormat(d3.format("d"));
    var z = d3.scaleOrdinal()
    .range(["#0c457b", "#88bae5", "#5da3d9", "#443e42"]);
    var keys = ["ODA", "OOF", "Other flows", "Not specified"];
    x.domain(data.map(function(d) { return d.year_org; }));
    y.domain([0, d3.max(data, function(d) { return d.value; })]);
    z.domain(keys);

    console.log(d3.max(data, function(d) { return d.value; })) ;
    console.log(data)
    console.log(d3.stack().keys(keys)(data_wide))
    svg.append("g")
      .selectAll("g")
      .data(d3.stack().keys(keys)(data_wide))
      .enter().append("g")
        .attr("fill", function(d) { return z(d.key); })
      .selectAll("rect")
      .data(function(d) {return d; })
      .enter().append("rect")
        .attr("x", function(d) {  return x(d.data.year_org); })
        .attr("y", function(d) { return y(d[1]); })
        .attr("height", function(d) { return y(d[0]) - y(d[1]); })
        .attr("width", x.bandwidth())
      .on("mouseover", function() { tooltip.style("display", null); })
      .on("mouseout", function() { tooltip.style("display", "none"); })
      .on("mousemove", function(d) {
        console.log(d);
        var xPosition = d3.mouse(this)[0] - 5;
        var yPosition = d3.mouse(this)[1] - 5;
        tooltip.attr("transform", "translate(" + xPosition + "," + yPosition + ")");
        tooltip.select("text").text(d[1]-d[0]);
      });
      
    svg.append("g")
        .attr("class", "axis")
        .attr("transform", "translate(0," + height + ")")
        .call(d3.axisBottom(x));
  
    svg.append("g")
        .attr("class", "axis")
        .call(d3.axisLeft(y).ticks(null, "s"))
      .append("text")
        .attr("x", 2)
        .attr("y", y(y.ticks().pop()) + 0.5)
        .attr("dy", "0.32em")
        .attr("fill", "#000")
        .attr("font-weight", "bold")
        .attr("text-anchor", "start");

    var legend = svg.append("g")
        .attr("font-family", "sans-serif")
        .attr("font-size", 10)
        .attr("text-anchor", "end")
      .selectAll("g")
      .data(keys.slice().reverse())
      .enter().append("g")
        .attr("transform", function(d, i) { return "translate(0," + i * 20 + ")"; });
  
    legend.append("rect")
        .attr("x", width - 19)
        .attr("width", 19)
        .attr("height", 19)
        .attr("fill", z);
  
    legend.append("text")
        .attr("x", width - 24)
        .attr("y", 9.5)
        .attr("dy", "0.32em")
        .text(function(d) { return d; });

    // var tooltip = svg.append("text")
    //   .attr("class","tooltip")
    //   .attr("font-size",12)
    //   .style("fill", "#475C6D");
    // var tooltipBackground = svg.append("rect")
    //   .attr("class","tooltip-bg")
    //   .attr("fill","black")
    //   .attr("rx",5);
}

function erase_chart(chart_id){
    var svg = d3.select("#" + chart_id).select("svg");
    svg.selectAll("*").remove();
}