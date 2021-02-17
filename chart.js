var pal = {
    "blue1": "#0089CC",
    "blue2": "#88BAE5",
    "blue3": "#0C457B",
    "blue4": "#A9A6AA"
  };

function set_selections(selector_configs, config_index){
    var selector_element = selector_configs[config_index].element;
    var selector_type = selector_configs[config_index].selector_type;
    if(selector_type == "dropdown"){
        var new_selection = [selector_element.property("value")];
    }else if(selector_type == "radio" || selector_type == "checkbox"){
        var new_selection = selector_element.selectAll("input:checked").nodes().map(function(d){return d.value});
    }
    if (new_selection == "Proportion" & selector_configs[config_index].current_selection == "Volume"){
        selector_configs.forEach(function(d){
            if(d.selector_type == "checkbox" || d.selector_type == "radio"){
                d.element.selectAll("input")._groups[0].forEach( function(d2) {
                    if (d.defaults.includes(d2.value)){d2.checked=true} else{d2.checked=false}})
                var defaults = d.defaults;
                d.current_selection=defaults}});
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
            .append("select").attr("class","spacing");
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
            .append("div").attr("class","spacing");
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
                )
                .attr("dy","0.5em")
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
        filtered_data = filtered_data.slice().sort((a, b) => d3.ascending(a.org_type, b.org_type))
    });
    return(filtered_data);
}

function draw_bar_chart(data, chart_id, margin, width, height,chart_config,selector_configs){

    data.forEach(function(d, d_index){
        data[d_index]["year_org"] = d["org_type"] + "_" + d["year"]
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
                for (const property in selector_configs[3].current_selection) {
                    empty_array[selector_configs[3].current_selection[property]] = "";
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
        var year = split_arr[1];
        if(year=="2019"){
            return(year+"_"+org_type)
        }else{
            return(year)
        }
    }).tickSize(0)
    var z = chart_config.colour_axis_scale;
    var keys = selector_configs[3]["current_selection"];
    x.domain(data_wide.map(function(d) { return d.year_org; }));
    y.domain([0, d3.max(data_total, function(d) { return d.total; })]).nice();

    var y_formatter = chart_config.y_axis_scale.variable[selector_configs[1]["current_selection"]];
    var yAxis = d3.axisLeft().ticks(6).scale(y).tickSize(0).tickSizeInner(-width).tickFormat( function(d) { return y_formatter(d) } );

    svg.append("g")
    .attr("class", "xaxis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis)
    .selectAll("text")
          .call(function(t){                
              t.each(function(d){ // for each one
              var self = d3.select(this);
              var s = self.text().split('_');  // get the text and split it
              self.text(''); // clear it out
              self.append("tspan") // insert two tspans
                  .attr("x", 0)
                  .attr("dy","1em")
                  .text(s[0]);
              self.append("tspan")
                  .attr("x", 0)
                  .attr("dy","2em")
                  .text(s[1]);
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

    var tooltip_formatter = chart_config.tooltip_type.variable[selector_configs[1]["current_selection"]];
    svg.append("g")
      .selectAll("g")
      .data(data_wide)
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
        var xPosition = d3.mouse(this)[0]+20;
        var yPosition = d3.mouse(this)[1]+10;
        tooltip.attr("transform", "translate(" + xPosition + "," + yPosition + ")");
        tooltip.select("text").text(d.key + ", " + tooltip_formatter(d))        
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
        .attr("text-anchor", "end")
        .selectAll("g")
        .data(keys.slice().reverse())
        .enter().append("g")
        .attr("transform", function(d, i) { return "translate(100," + i * 20 + ")"; });
  
    legend.append("rect")
        .attr("x", width - 19)
        .attr("width", 19)
        .attr("height", 19)
        .attr("fill", z)
  
    legend.append("text")
        .attr("x", width - 24)
        .attr("y", 9.5)
        .attr("dy", "0.32em")
        .text(function(d) { return d; });
    
    var tooltip = svg.append("g")
        .attr("class", "tooltip")
        .style("display", "none");
          
    tooltip.append("rect")
        .attr("width", 100)
        .attr("height", 20)
        .attr("fill", "white")
        .style("opacity", 0);
    
    tooltip.append("text")
        .attr("x", 2)
        .attr("dy", "1.2em")
        .style("text-anchor", "left")
        .attr("font-size", "12px")
        .attr("font-weight", "bold");
}

function erase_chart(chart_id){
    var svg = d3.select("#" + chart_id).select("svg");
    svg.remove();
}
