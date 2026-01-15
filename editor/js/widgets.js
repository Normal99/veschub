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
        const group = new fabric.Group([], {
            left: widget.x,
            top: widget.y,
            width: widget.width,
            height: widget.height,
            angle: widget.rotation || 0,
            opacity: widget.opacity || 1.0
        });

        // Background circle
        const bg = new fabric.Circle({
            radius: Math.min(widget.width, widget.height) / 2,
            fill: widget.backgroundColor || 'transparent',
            stroke: '#3A3A3A',
            strokeWidth: 2
        });
        group.addWithUpdate(bg);

        // Add tick marks
        if (widget.showTicks) {
            const tickCount = widget.tickCount || 10;
            const radius = Math.min(widget.width, widget.height) / 2;
            
            for (let i = 0; i <= tickCount; i++) {
                const angle = (i / tickCount) * Math.PI * 2;
                const tickLength = 10;
                const x1 = Math.cos(angle) * (radius - tickLength);
                const y1 = Math.sin(angle) * (radius - tickLength);
                const x2 = Math.cos(angle) * radius;
                const y2 = Math.sin(angle) * radius;
                
                const tick = new fabric.Line([x1, y1, x2, y2], {
                    stroke: widget.tickColor || '#FFFFFF',
                    strokeWidth: 2
                });
                group.addWithUpdate(tick);
            }
        }

        // Needle (pointing up as placeholder)
        const needleLength = Math.min(widget.width, widget.height) / 2 - 20;
        const needle = new fabric.Line([0, 0, 0, -needleLength], {
            stroke: widget.needleColor || '#00FF00',
            strokeWidth: 3
        });
        group.addWithUpdate(needle);

        // Center dot
        const center = new fabric.Circle({
            radius: 5,
            fill: widget.needleColor || '#00FF00'
        });
        group.addWithUpdate(center);

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
    }
};
