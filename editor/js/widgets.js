/**
 * VescHub Editor - Widgets Module
 * Widget rendering and management
 */

const Widgets = {
    /**
     * Render widget on fabric canvas
     */
    renderWidget: (widget, canvas) => {
        let fabricObject = null;

        switch (widget.type) {
            case 'text':
                fabricObject = Widgets.renderText(widget);
                break;
            case 'gauge':
                fabricObject = Widgets.renderGauge(widget);
                break;
            case 'speedometer':
                fabricObject = Widgets.renderSpeedometer(widget);
                break;
            case 'progressbar':
                fabricObject = Widgets.renderProgressBar(widget);
                break;
            case 'graph':
                fabricObject = Widgets.renderGraph(widget);
                break;
            case 'button':
                fabricObject = Widgets.renderButton(widget);
                break;
            case 'indicator':
                fabricObject = Widgets.renderIndicator(widget);
                break;
            case 'image':
                fabricObject = Widgets.renderImage(widget);
                break;
            case 'shape':
                fabricObject = Widgets.renderShape(widget);
                break;
            case 'consumption':
                fabricObject = Widgets.renderConsumption(widget);
                break;
            default:
                console.warn('Unknown widget type:', widget.type);
                fabricObject = Widgets.renderPlaceholder(widget);
        }

        if (fabricObject) {
            fabricObject.widgetData = widget;
            fabricObject.selectable = true;
            fabricObject.hasControls = true;
            fabricObject.hasBorders = true;
            fabricObject.lockRotation = false;
            
            canvas.add(fabricObject);
        }

        return fabricObject;
    },

    /**
     * Render text widget
     */
    renderText: (widget) => {
        const text = new fabric.Text(widget.text || 'Text', {
            left: widget.x,
            top: widget.y,
            width: widget.width,
            fontSize: widget.fontSize || 24,
            fontFamily: widget.fontFamily || 'Roboto',
            fontWeight: widget.fontWeight || 'normal',
            fontStyle: widget.fontStyle || 'normal',
            textAlign: widget.textAlign || 'left',
            fill: widget.color || '#FFFFFF',
            backgroundColor: widget.backgroundColor || 'transparent',
            angle: widget.rotation || 0,
            opacity: widget.opacity || 1.0
        });
        
        return text;
    },

    /**
     * Render gauge widget (circular/semicircular)
     */
    renderGauge: (widget) => {
        const centerX = widget.width / 2;
        const centerY = widget.height / 2;
        const radius = Math.min(widget.width, widget.height) / 2 - 30;
        
        const gaugeType = widget.gaugeType || 'circular';
        const startAngle = gaugeType === 'semicircular' ? -Math.PI : -Math.PI * 0.75;
        const endAngle = gaugeType === 'semicircular' ? 0 : Math.PI * 0.75;
        const angleRange = endAngle - startAngle;

        const group = new fabric.Group([], {
            left: widget.x,
            top: widget.y,
            width: widget.width,
            height: widget.height,
            angle: widget.rotation || 0,
            opacity: widget.opacity || 1.0
        });

        // Background arc
        const bgArc = new fabric.Circle({
            radius: radius,
            fill: widget.backgroundColor || 'transparent',
            stroke: '#3A3A3A',
            strokeWidth: 3,
            startAngle: startAngle * 180 / Math.PI,
            endAngle: endAngle * 180 / Math.PI,
            originX: 'center',
            originY: 'center'
        });
        group.addWithUpdate(bgArc);

        // Draw color zones if defined
        if (widget.zones && widget.zones.length > 0) {
            widget.zones.forEach(zone => {
                const minValue = widget.minValue || 0;
                const maxValue = widget.maxValue || 100;
                const zoneStartAngle = startAngle + (zone.min - minValue) / (maxValue - minValue) * angleRange;
                const zoneEndAngle = startAngle + (zone.max - minValue) / (maxValue - minValue) * angleRange;
                
                // Draw zone arc (simplified - in full implementation would use proper arc)
                const zonePath = new fabric.Path(`M 0 0 L ${Math.cos(zoneStartAngle) * radius} ${Math.sin(zoneStartAngle) * radius}`, {
                    stroke: zone.color || '#FFAA00',
                    strokeWidth: 6,
                    fill: '',
                    originX: 'center',
                    originY: 'center'
                });
                group.addWithUpdate(zonePath);
            });
        }

        // Draw tick marks
        if (widget.showTicks !== false) {
            const minValue = widget.minValue || 0;
            const maxValue = widget.maxValue || 100;
            const tickCount = widget.tickCount || 10;
            const majorTickInterval = (maxValue - minValue) / tickCount;
            const minorTickInterval = majorTickInterval / 2;
            
            // Draw major and minor ticks
            for (let value = minValue; value <= maxValue; value += minorTickInterval) {
                const isMajorTick = Math.abs((value - minValue) % majorTickInterval) < 0.001;
                const angle = startAngle + ((value - minValue) / (maxValue - minValue)) * angleRange;
                
                const tickLength = isMajorTick ? 12 : 6;
                const tickWidth = isMajorTick ? 2 : 1;
                
                const x1 = Math.cos(angle) * (radius - tickLength);
                const y1 = Math.sin(angle) * (radius - tickLength);
                const x2 = Math.cos(angle) * radius;
                const y2 = Math.sin(angle) * radius;
                
                const tick = new fabric.Line([x1, y1, x2, y2], {
                    stroke: widget.tickColor || '#AAAAAA',
                    strokeWidth: tickWidth,
                    originX: 'center',
                    originY: 'center'
                });
                group.addWithUpdate(tick);
                
                // Draw labels for major ticks
                if (isMajorTick && widget.showLabels !== false) {
                    const labelRadius = radius - tickLength - 15;
                    const labelX = Math.cos(angle) * labelRadius;
                    const labelY = Math.sin(angle) * labelRadius;
                    
                    const label = new fabric.Text(value.toString(), {
                        left: labelX,
                        top: labelY,
                        fontSize: 10,
                        fill: widget.tickColor || '#AAAAAA',
                        originX: 'center',
                        originY: 'center'
                    });
                    group.addWithUpdate(label);
                }
            }
        }

        // Needle (pointing up as placeholder)
        const currentValue = widget.currentValue || widget.minValue || 0;
        const minValue = widget.minValue || 0;
        const maxValue = widget.maxValue || 100;
        const needleAngle = startAngle + ((currentValue - minValue) / (maxValue - minValue)) * angleRange;
        
        const needleLength = radius - 10;
        const needleX = Math.cos(needleAngle) * needleLength;
        const needleY = Math.sin(needleAngle) * needleLength;
        
        const needle = new fabric.Line([0, 0, needleX, needleY], {
            stroke: widget.needleColor || '#00FF00',
            strokeWidth: 3,
            originX: 'center',
            originY: 'center'
        });
        group.addWithUpdate(needle);

        // Center dot
        const center = new fabric.Circle({
            radius: 6,
            fill: widget.needleColor || '#00FF00',
            originX: 'center',
            originY: 'center'
        });
        group.addWithUpdate(center);

        // Value display text
        if (widget.showValue !== false) {
            const valueText = new fabric.Text(
                `${currentValue.toFixed(widget.decimals || 0)}${widget.units || ''}`,
                {
                    top: gaugeType === 'semicircular' ? -20 : 20,
                    fontSize: 16,
                    fill: '#FFFFFF',
                    originX: 'center',
                    originY: 'center',
                    fontWeight: 'bold'
                }
            );
            group.addWithUpdate(valueText);
        }

        return group;
    },

    /**
     * Render speedometer widget
     */
    renderSpeedometer: (widget) => {
        // Similar to gauge but with specific styling
        return Widgets.renderGauge({
            ...widget,
            gaugeType: 'semicircular',
            showDigitalDisplay: widget.showDigitalDisplay !== false
        });
    },

    /**
     * Render progress bar widget
     */
    renderProgressBar: (widget) => {
        const group = new fabric.Group([], {
            left: widget.x,
            top: widget.y,
            width: widget.width,
            height: widget.height,
            angle: widget.rotation || 0,
            opacity: widget.opacity || 1.0
        });

        // Background
        const bg = new fabric.Rect({
            width: widget.width,
            height: widget.height,
            fill: widget.backgroundColor || '#2A2A2A',
            rx: widget.borderRadius || 0,
            ry: widget.borderRadius || 0
        });
        group.addWithUpdate(bg);

        // Fill (50% as placeholder)
        const fillWidth = widget.orientation === 'vertical' ? widget.width : widget.width * 0.5;
        const fillHeight = widget.orientation === 'vertical' ? widget.height * 0.5 : widget.height;
        
        const fill = new fabric.Rect({
            width: fillWidth,
            height: fillHeight,
            fill: widget.fillColor || '#00FF00',
            rx: widget.borderRadius || 0,
            ry: widget.borderRadius || 0
        });
        group.addWithUpdate(fill);

        return group;
    },

    /**
     * Render graph widget
     */
    renderGraph: (widget) => {
        const group = new fabric.Group([], {
            left: widget.x,
            top: widget.y,
            width: widget.width,
            height: widget.height,
            angle: widget.rotation || 0,
            opacity: widget.opacity || 1.0
        });

        // Background
        const bg = new fabric.Rect({
            width: widget.width,
            height: widget.height,
            fill: widget.backgroundColor || '#1A1A1A'
        });
        group.addWithUpdate(bg);

        // Grid lines
        if (widget.showGrid) {
            const gridColor = widget.gridColor || '#2A2A2A';
            const gridSpacing = 20;
            
            // Vertical lines
            for (let x = gridSpacing; x < widget.width; x += gridSpacing) {
                const line = new fabric.Line([x, 0, x, widget.height], {
                    stroke: gridColor,
                    strokeWidth: 1
                });
                group.addWithUpdate(line);
            }
            
            // Horizontal lines
            for (let y = gridSpacing; y < widget.height; y += gridSpacing) {
                const line = new fabric.Line([0, y, widget.width, y], {
                    stroke: gridColor,
                    strokeWidth: 1
                });
                group.addWithUpdate(line);
            }
        }

        // Placeholder wave line
        const points = [];
        for (let x = 0; x < widget.width; x += 10) {
            const y = widget.height / 2 + Math.sin(x / 20) * (widget.height / 4);
            points.push(new fabric.Point(x, y));
        }
        
        const line = new fabric.Polyline(points, {
            fill: '',
            stroke: '#00FFFF',
            strokeWidth: 2
        });
        group.addWithUpdate(line);

        return group;
    },

    /**
     * Render button widget
     */
    renderButton: (widget) => {
        const rect = new fabric.Rect({
            left: widget.x,
            top: widget.y,
            width: widget.width,
            height: widget.height,
            fill: '#4A4A4A',
            stroke: '#666666',
            strokeWidth: 2,
            rx: 10,
            ry: 10,
            angle: widget.rotation || 0,
            opacity: widget.opacity || 1.0
        });

        // Add button icon/text
        const text = new fabric.Text('BUTTON', {
            left: widget.x + widget.width / 2,
            top: widget.y + widget.height / 2,
            fontSize: 16,
            fill: '#FFFFFF',
            originX: 'center',
            originY: 'center'
        });

        const group = new fabric.Group([rect, text], {
            left: widget.x,
            top: widget.y
        });

        return group;
    },

    /**
     * Render indicator widget (LED)
     */
    renderIndicator: (widget) => {
        const circle = new fabric.Circle({
            left: widget.x,
            top: widget.y,
            radius: Math.min(widget.width, widget.height) / 2,
            fill: widget.onColor || '#00FF00',
            stroke: '#666666',
            strokeWidth: 2,
            angle: widget.rotation || 0,
            opacity: widget.opacity || 1.0
        });

        return circle;
    },

    /**
     * Render image widget
     */
    renderImage: (widget) => {
        // Placeholder rectangle for image
        const rect = new fabric.Rect({
            left: widget.x,
            top: widget.y,
            width: widget.width,
            height: widget.height,
            fill: '#2A2A2A',
            stroke: '#4A4A4A',
            strokeWidth: 1,
            angle: widget.rotation || 0,
            opacity: widget.opacity || 1.0
        });

        const text = new fabric.Text('IMAGE', {
            left: widget.x + widget.width / 2,
            top: widget.y + widget.height / 2,
            fontSize: 14,
            fill: '#666666',
            originX: 'center',
            originY: 'center'
        });

        const group = new fabric.Group([rect, text], {
            left: widget.x,
            top: widget.y
        });

        return group;
    },

    /**
     * Render shape widget
     */
    renderShape: (widget) => {
        let shape = null;

        switch (widget.shapeType) {
            case 'circle':
                shape = new fabric.Circle({
                    left: widget.x,
                    top: widget.y,
                    radius: Math.min(widget.width, widget.height) / 2,
                    fill: widget.fillColor || '#FFFFFF',
                    stroke: widget.strokeColor || '#FFFFFF',
                    strokeWidth: widget.strokeWidth || 1
                });
                break;
            
            case 'line':
                shape = new fabric.Line([
                    widget.x, 
                    widget.y, 
                    widget.x + widget.width, 
                    widget.y + widget.height
                ], {
                    stroke: widget.strokeColor || '#FFFFFF',
                    strokeWidth: widget.strokeWidth || 1
                });
                break;
            
            case 'rectangle':
            default:
                shape = new fabric.Rect({
                    left: widget.x,
                    top: widget.y,
                    width: widget.width,
                    height: widget.height,
                    fill: widget.fillColor || 'transparent',
                    stroke: widget.strokeColor || '#FFFFFF',
                    strokeWidth: widget.strokeWidth || 1,
                    rx: widget.borderRadius || 0,
                    ry: widget.borderRadius || 0
                });
        }

        if (shape) {
            shape.angle = widget.rotation || 0;
            shape.opacity = widget.opacity || 1.0;
        }

        return shape;
    },

    /**
     * Render placeholder for unknown widget types
     */
    renderPlaceholder: (widget) => {
        const rect = new fabric.Rect({
            left: widget.x,
            top: widget.y,
            width: widget.width,
            height: widget.height,
            fill: '#3A3A3A',
            stroke: '#FF3333',
            strokeWidth: 2,
            strokeDashArray: [5, 5]
        });

        const text = new fabric.Text('?', {
            left: widget.x + widget.width / 2,
            top: widget.y + widget.height / 2,
            fontSize: 48,
            fill: '#FF3333',
            originX: 'center',
            originY: 'center'
        });

        const group = new fabric.Group([rect, text], {
            left: widget.x,
            top: widget.y
        });

        return group;
    },

    /**
     * Render consumption meter widget
     */
    renderConsumption: (widget) => {
        const displayMode = widget.displayMode || 'gauge';
        
        if (displayMode === 'text') {
            // Simple text display
            const value = widget.currentValue || 20; // Default value
            const decimals = widget.decimals || 1;
            const unit = widget.units || 'Wh/km';
            
            // Determine color based on efficiency thresholds
            let color = widget.color || '#FFFFFF';
            if (widget.efficientThreshold && widget.moderateThreshold) {
                if (value < widget.efficientThreshold) {
                    color = widget.efficientColor || '#00FF00';
                } else if (value < widget.moderateThreshold) {
                    color = widget.moderateColor || '#FFAA00';
                } else {
                    color = widget.inefficientColor || '#FF3333';
                }
            }
            
            const displayText = widget.showUnit !== false 
                ? `${value.toFixed(decimals)} ${unit}` 
                : value.toFixed(decimals);
            
            const text = new fabric.Text(displayText, {
                left: widget.x,
                top: widget.y,
                fontSize: widget.fontSize || 32,
                fontFamily: widget.fontFamily || 'Roboto',
                fontWeight: 'bold',
                fill: color,
                backgroundColor: widget.backgroundColor || 'transparent',
                angle: widget.rotation || 0,
                opacity: widget.opacity || 1.0
            });
            
            return text;
        } else {
            // Gauge-style display
            return Widgets.renderGauge({
                ...widget,
                gaugeType: 'semicircular',
                showTicks: true,
                showLabels: true,
                tickCount: 5,
                showValue: true,
                zones: [
                    { min: widget.minValue || 0, max: widget.efficientThreshold || 15, color: widget.efficientColor || '#00FF00' },
                    { min: widget.efficientThreshold || 15, max: widget.moderateThreshold || 25, color: widget.moderateColor || '#FFAA00' },
                    { min: widget.moderateThreshold || 25, max: widget.maxValue || 50, color: widget.inefficientColor || '#FF3333' }
                ]
            });
        }
    },

    /**
     * Update widget from fabric object
     */
    updateWidgetFromFabric: (fabricObject) => {
        if (!fabricObject.widgetData) return null;

        const widget = fabricObject.widgetData;
        widget.x = Math.round(fabricObject.left);
        widget.y = Math.round(fabricObject.top);
        widget.width = Math.round(fabricObject.width * fabricObject.scaleX);
        widget.height = Math.round(fabricObject.height * fabricObject.scaleY);
        widget.rotation = Math.round(fabricObject.angle);
        widget.opacity = fabricObject.opacity;

        return widget;
    },

    /**
     * Update gauge widget with live data
     */
    updateGauge: (fabricObject, widget, value) => {
        const minValue = widget.minValue || 0;
        const maxValue = widget.maxValue || 100;
        const clampedValue = Math.max(minValue, Math.min(maxValue, value));
        
        // Calculate needle angle (-45° to 225° = 270° range)
        const startAngle = -Math.PI / 4;
        const endAngle = Math.PI * 5 / 4;
        const angleRange = endAngle - startAngle;
        const valuePercent = (clampedValue - minValue) / (maxValue - minValue);
        const needleAngle = startAngle + valuePercent * angleRange;
        
        // Find needle in group (it's typically the second-to-last element)
        const items = fabricObject.getObjects();
        const needleIndex = items.length - 2; // Before center dot
        
        if (items[needleIndex] && items[needleIndex].type === 'line') {
            const radius = Math.min(widget.width, widget.height) / 2 - 25;
            const needleX = Math.cos(needleAngle) * radius;
            const needleY = Math.sin(needleAngle) * radius;
            
            items[needleIndex].set({
                x2: needleX,
                y2: needleY
            });
        }
    },

    /**
     * Update progress bar widget with live data
     */
    updateProgressBar: (fabricObject, widget, value) => {
        const minValue = widget.minValue || 0;
        const maxValue = widget.maxValue || 100;
        const clampedValue = Math.max(minValue, Math.min(maxValue, value));
        const valuePercent = (clampedValue - minValue) / (maxValue - minValue);
        
        // Find fill rect in group (second element)
        const items = fabricObject.getObjects();
        if (items[1] && items[1].type === 'rect') {
            const halfWidth = -widget.width / 2;
            const halfHeight = -widget.height / 2;
            
            if (widget.orientation === 'vertical') {
                const fillHeight = widget.height * valuePercent;
                items[1].set({
                    height: fillHeight,
                    top: halfHeight + widget.height - fillHeight
                });
            } else {
                items[1].set({
                    width: widget.width * valuePercent
                });
            }
        }
    },

    /**
     * Update text widget with live data
     */
    updateText: (fabricObject, widget, value) => {
        const decimals = widget.decimals || 0;
        const formattedValue = typeof value === 'number' ? value.toFixed(decimals) : value;
        const prefix = widget.prefix || '';
        const suffix = widget.suffix || widget.units || '';
        const newText = `${prefix}${formattedValue}${suffix}`;
        
        if (fabricObject.type === 'text' || fabricObject.type === 'i-text') {
            fabricObject.set({ text: newText });
        }
    },

    /**
     * Update indicator widget with live data
     */
    updateIndicator: (fabricObject, widget, value) => {
        const threshold = widget.threshold || 0.5;
        const isOn = value > threshold;
        const color = isOn ? (widget.onColor || '#00FF00') : (widget.offColor || '#2A2A2A');
        
        if (fabricObject.type === 'circle') {
            fabricObject.set({ fill: color });
            
            // Blink effect if enabled
            if (isOn && widget.blinkWhenOn) {
                const blinkState = Math.floor(Date.now() / 500) % 2;
                fabricObject.set({ opacity: blinkState ? 1.0 : 0.3 });
            } else {
                fabricObject.set({ opacity: widget.opacity || 1.0 });
            }
        }
    }
};
