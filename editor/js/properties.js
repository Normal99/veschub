/**
 * VescHub Editor - Properties Panel Module
 * Dynamic property editor for selected widgets
 */

const Properties = {
    currentWidget: null,
    multipleSelection: false,

    /**
     * Update properties panel based on selection
     */
    updatePanel: (activeObjects) => {
        const panel = document.getElementById('properties-panel');
        if (!panel) return;

        if (activeObjects.length === 0) {
            Properties.showEmptyState(panel);
        } else if (activeObjects.length === 1) {
            Properties.multipleSelection = false;
            Properties.currentWidget = activeObjects[0].widgetData;
            Properties.showSingleWidget(panel, activeObjects[0]);
        } else {
            Properties.multipleSelection = true;
            Properties.showMultipleWidgets(panel, activeObjects);
        }
    },

    /**
     * Show empty state
     */
    showEmptyState: (panel) => {
        panel.innerHTML = `
            <div class="empty-state">
                <p>Select a widget to edit its properties</p>
            </div>
        `;
    },

    /**
     * Show properties for single widget
     */
    showSingleWidget: (panel, fabricObject) => {
        const widget = fabricObject.widgetData;
        
        let html = `
            <div class="properties-header">
                <h3>${Utils.getWidgetIcon(widget.type)} ${widget.type.toUpperCase()}</h3>
                <span class="widget-id">${widget.id}</span>
            </div>
            <div class="properties-content">
        `;

        // Common properties
        html += Properties.renderSection('Position & Size', [
            Properties.renderNumberInput('x', 'X', widget.x, 0, 10000),
            Properties.renderNumberInput('y', 'Y', widget.y, 0, 10000),
            Properties.renderNumberInput('width', 'Width', widget.width, 1, 10000),
            Properties.renderNumberInput('height', 'Height', widget.height, 1, 10000),
            Properties.renderNumberInput('rotation', 'Rotation', widget.rotation, 0, 360),
            Properties.renderSlider('opacity', 'Opacity', widget.opacity, 0, 1, 0.1)
        ]);

        // Widget-specific properties
        switch (widget.type) {
            case 'text':
                html += Properties.renderTextProperties(widget);
                break;
            case 'button':
                html += Properties.renderButtonProperties(widget);
                break;
            case 'gauge':
                html += Properties.renderGaugeProperties(widget);
                break;
            case 'graph':
                html += Properties.renderGraphProperties(widget);
                break;
            case 'progressbar':
                html += Properties.renderProgressBarProperties(widget);
                break;
            case 'image':
                html += Properties.renderImageProperties(widget);
                break;
            case 'shape':
                html += Properties.renderShapeProperties(widget);
                break;
            case 'indicator':
                html += Properties.renderIndicatorProperties(widget);
                break;
            case 'speedometer':
                html += Properties.renderSpeedometerProperties(widget);
                break;
        }

        // Data source
        if (['text', 'gauge', 'progressbar', 'indicator', 'speedometer', 'graph'].includes(widget.type)) {
            html += Properties.renderDataSourceSection(widget);
        }

        // Advanced properties
        html += Properties.renderAdvancedSection(widget);

        html += '</div>';
        panel.innerHTML = html;

        // Setup event listeners
        Properties.setupEventListeners(fabricObject);
    },

    /**
     * Show properties for multiple widgets
     */
    showMultipleWidgets: (panel, activeObjects) => {
        panel.innerHTML = `
            <div class="properties-header">
                <h3>Multiple Selection (${activeObjects.length})</h3>
            </div>
            <div class="properties-content">
                ${Properties.renderSection('Common Properties', [
                    '<p>Common properties for multiple widgets</p>',
                    Properties.renderButton('Align Left', 'Canvas.align("left")'),
                    Properties.renderButton('Align Center', 'Canvas.align("center")'),
                    Properties.renderButton('Align Right', 'Canvas.align("right")'),
                    Properties.renderButton('Align Top', 'Canvas.align("top")'),
                    Properties.renderButton('Align Middle', 'Canvas.align("middle")'),
                    Properties.renderButton('Align Bottom', 'Canvas.align("bottom")'),
                    Properties.renderButton('Distribute Horizontally', 'Canvas.distribute("horizontal")'),
                    Properties.renderButton('Distribute Vertically', 'Canvas.distribute("vertical")')
                ])}
            </div>
        `;
    },

    /**
     * Render text widget properties
     */
    renderTextProperties: (widget) => {
        return Properties.renderSection('Text Properties', [
            Properties.renderTextArea('text', 'Text', widget.text || ''),
            Properties.renderNumberInput('fontSize', 'Font Size', widget.fontSize, 8, 200),
            Properties.renderSelect('fontFamily', 'Font Family', widget.fontFamily, [
                { value: 'Roboto', label: 'Roboto' },
                { value: 'Arial', label: 'Arial' },
                { value: 'Helvetica', label: 'Helvetica' },
                { value: 'monospace', label: 'Monospace' },
                { value: 'sans-serif', label: 'Sans Serif' }
            ]),
            Properties.renderSelect('fontWeight', 'Font Weight', widget.fontWeight, [
                { value: 'normal', label: 'Normal' },
                { value: 'bold', label: 'Bold' },
                { value: '300', label: 'Light' },
                { value: '600', label: 'Semi Bold' }
            ]),
            Properties.renderSelect('textAlign', 'Text Align', widget.textAlign, [
                { value: 'left', label: 'Left' },
                { value: 'center', label: 'Center' },
                { value: 'right', label: 'Right' }
            ]),
            Properties.renderColorPicker('color', 'Text Color', widget.color),
            Properties.renderColorPicker('backgroundColor', 'Background', widget.backgroundColor || 'transparent'),
            Properties.renderTextInput('prefix', 'Prefix', widget.prefix || ''),
            Properties.renderTextInput('suffix', 'Suffix', widget.suffix || ''),
            Properties.renderNumberInput('decimals', 'Decimals', widget.decimals || 0, 0, 10)
        ]);
    },

    /**
     * Render button widget properties
     */
    renderButtonProperties: (widget) => {
        return Properties.renderSection('Button Properties', [
            Properties.renderTextInput('imageUnpressed', 'Image (Unpressed)', widget.imageUnpressed || ''),
            Properties.renderTextInput('imagePressed', 'Image (Pressed)', widget.imagePressed || ''),
            Properties.renderCheckbox('hapticFeedback', 'Haptic Feedback', widget.hapticFeedback !== false),
            Properties.renderSelect('action.type', 'Action Type', widget.action?.type, [
                { value: 'switchScreen', label: 'Switch Screen' },
                { value: 'toggleValue', label: 'Toggle Value' },
                { value: 'sendCommand', label: 'Send Command' }
            ]),
            Properties.renderTextInput('action.target', 'Action Target', widget.action?.target || '')
        ]);
    },

    /**
     * Render gauge widget properties
     */
    renderGaugeProperties: (widget) => {
        return Properties.renderSection('Gauge Properties', [
            Properties.renderSelect('gaugeType', 'Gauge Type', widget.gaugeType, [
                { value: 'circular', label: 'Circular' },
                { value: 'semicircular', label: 'Semi-circular' }
            ]),
            Properties.renderNumberInput('minValue', 'Min Value', widget.minValue, -999999, 999999),
            Properties.renderNumberInput('maxValue', 'Max Value', widget.maxValue, -999999, 999999),
            Properties.renderTextInput('units', 'Units', widget.units || ''),
            Properties.renderColorPicker('needleColor', 'Needle Color', widget.needleColor),
            Properties.renderColorPicker('backgroundColor', 'Background', widget.backgroundColor || 'transparent'),
            Properties.renderCheckbox('showTicks', 'Show Ticks', widget.showTicks !== false),
            Properties.renderNumberInput('tickCount', 'Tick Count', widget.tickCount || 10, 2, 50)
        ]);
    },

    /**
     * Render speedometer widget properties
     */
    renderSpeedometerProperties: (widget) => {
        return Properties.renderSection('Speedometer Properties', [
            Properties.renderNumberInput('minValue', 'Min Value', widget.minValue, 0, 1000),
            Properties.renderNumberInput('maxValue', 'Max Value', widget.maxValue, 0, 1000),
            Properties.renderTextInput('units', 'Units', widget.units || 'km/h'),
            Properties.renderColorPicker('needleColor', 'Needle Color', widget.needleColor),
            Properties.renderNumberInput('redZoneStart', 'Red Zone Start', widget.redZoneStart || 0, 0, 1000),
            Properties.renderCheckbox('showDigitalDisplay', 'Show Digital Display', widget.showDigitalDisplay !== false),
            Properties.renderNumberInput('digitalFontSize', 'Digital Font Size', widget.digitalFontSize || 48, 8, 200)
        ]);
    },

    /**
     * Render progress bar widget properties
     */
    renderProgressBarProperties: (widget) => {
        return Properties.renderSection('Progress Bar Properties', [
            Properties.renderSelect('orientation', 'Orientation', widget.orientation, [
                { value: 'horizontal', label: 'Horizontal' },
                { value: 'vertical', label: 'Vertical' }
            ]),
            Properties.renderNumberInput('minValue', 'Min Value', widget.minValue, -999999, 999999),
            Properties.renderNumberInput('maxValue', 'Max Value', widget.maxValue, -999999, 999999),
            Properties.renderColorPicker('fillColor', 'Fill Color', widget.fillColor),
            Properties.renderColorPicker('backgroundColor', 'Background', widget.backgroundColor),
            Properties.renderNumberInput('borderRadius', 'Border Radius', widget.borderRadius || 0, 0, 100),
            Properties.renderCheckbox('showValue', 'Show Value', widget.showValue || false)
        ]);
    },

    /**
     * Render graph widget properties
     */
    renderGraphProperties: (widget) => {
        return Properties.renderSection('Graph Properties', [
            Properties.renderSelect('graphType', 'Graph Type', widget.graphType, [
                { value: 'line', label: 'Line' },
                { value: 'bar', label: 'Bar' }
            ]),
            Properties.renderNumberInput('timeWindow', 'Time Window (s)', widget.timeWindow || 30, 1, 3600),
            Properties.renderColorPicker('backgroundColor', 'Background', widget.backgroundColor),
            Properties.renderColorPicker('gridColor', 'Grid Color', widget.gridColor),
            Properties.renderCheckbox('showGrid', 'Show Grid', widget.showGrid !== false),
            Properties.renderCheckbox('autoScale', 'Auto Scale', widget.autoScale !== false)
        ]);
    },

    /**
     * Render image widget properties
     */
    renderImageProperties: (widget) => {
        return Properties.renderSection('Image Properties', [
            Properties.renderTextInput('imagePath', 'Image Path', widget.imagePath || ''),
            Properties.renderSelect('fitMode', 'Fit Mode', widget.fitMode, [
                { value: 'fill', label: 'Fill' },
                { value: 'contain', label: 'Contain' },
                { value: 'cover', label: 'Cover' },
                { value: 'stretch', label: 'Stretch' },
                { value: 'none', label: 'None' }
            ])
        ]);
    },

    /**
     * Render shape widget properties
     */
    renderShapeProperties: (widget) => {
        return Properties.renderSection('Shape Properties', [
            Properties.renderSelect('shapeType', 'Shape Type', widget.shapeType, [
                { value: 'rectangle', label: 'Rectangle' },
                { value: 'circle', label: 'Circle' },
                { value: 'line', label: 'Line' }
            ]),
            Properties.renderColorPicker('fillColor', 'Fill Color', widget.fillColor),
            Properties.renderColorPicker('strokeColor', 'Stroke Color', widget.strokeColor),
            Properties.renderNumberInput('strokeWidth', 'Stroke Width', widget.strokeWidth || 1, 0, 50),
            Properties.renderNumberInput('borderRadius', 'Border Radius', widget.borderRadius || 0, 0, 100)
        ]);
    },

    /**
     * Render indicator widget properties
     */
    renderIndicatorProperties: (widget) => {
        return Properties.renderSection('Indicator Properties', [
            Properties.renderColorPicker('onColor', 'ON Color', widget.onColor),
            Properties.renderColorPicker('offColor', 'OFF Color', widget.offColor),
            Properties.renderNumberInput('threshold', 'Threshold', widget.threshold || 0.5, 0, 1, 0.1),
            Properties.renderCheckbox('blinkWhenOn', 'Blink When ON', widget.blinkWhenOn || false),
            Properties.renderNumberInput('blinkRate', 'Blink Rate (ms)', widget.blinkRate || 500, 100, 5000)
        ]);
    },

    /**
     * Render data source section
     */
    renderDataSourceSection: (widget) => {
        const dataSources = Utils.getVESCDataSources();
        const options = [
            { value: '', label: 'None' },
            ...dataSources.map(ds => ({ value: ds.value, label: ds.label }))
        ];

        return Properties.renderSection('Data Source', [
            Properties.renderSelect('dataSource', 'Data Source', widget.dataSource || '', options)
        ]);
    },

    /**
     * Render advanced section
     */
    renderAdvancedSection: (widget) => {
        return Properties.renderSection('Advanced', [
            Properties.renderNumberInput('zIndex', 'Z-Index', widget.zIndex || 0, -100, 100),
            Properties.renderCheckbox('visible', 'Visible', widget.visible !== false),
            `<button class="btn-secondary" onclick="Properties.openConditionalFormatting()">Conditional Formatting</button>`,
            `<button class="btn-secondary" onclick="Properties.openAnimationSettings()">Animation Settings</button>`
        ]);
    },

    /**
     * Render section
     */
    renderSection: (title, items) => {
        return `
            <div class="property-section">
                <h4 class="section-title">${title}</h4>
                ${items.join('')}
            </div>
        `;
    },

    /**
     * Render text input
     */
    renderTextInput: (name, label, value) => {
        return `
            <div class="property-field">
                <label>${label}</label>
                <input type="text" data-property="${name}" value="${value || ''}" />
            </div>
        `;
    },

    /**
     * Render text area
     */
    renderTextArea: (name, label, value) => {
        return `
            <div class="property-field">
                <label>${label}</label>
                <textarea data-property="${name}" rows="3">${value || ''}</textarea>
            </div>
        `;
    },

    /**
     * Render number input
     */
    renderNumberInput: (name, label, value, min, max, step = 1) => {
        return `
            <div class="property-field">
                <label>${label}</label>
                <input type="number" data-property="${name}" value="${value || 0}" 
                       min="${min}" max="${max}" step="${step}" />
            </div>
        `;
    },

    /**
     * Render slider
     */
    renderSlider: (name, label, value, min, max, step = 0.1) => {
        return `
            <div class="property-field">
                <label>${label} <span class="slider-value">${value}</span></label>
                <input type="range" data-property="${name}" value="${value}" 
                       min="${min}" max="${max}" step="${step}" 
                       oninput="this.previousElementSibling.querySelector('.slider-value').textContent = this.value" />
            </div>
        `;
    },

    /**
     * Render select dropdown
     */
    renderSelect: (name, label, value, options) => {
        const optionsHtml = options.map(opt => 
            `<option value="${opt.value}" ${opt.value === value ? 'selected' : ''}>${opt.label}</option>`
        ).join('');

        return `
            <div class="property-field">
                <label>${label}</label>
                <select data-property="${name}">
                    ${optionsHtml}
                </select>
            </div>
        `;
    },

    /**
     * Render checkbox
     */
    renderCheckbox: (name, label, checked) => {
        return `
            <div class="property-field property-checkbox">
                <label>
                    <input type="checkbox" data-property="${name}" ${checked ? 'checked' : ''} />
                    ${label}
                </label>
            </div>
        `;
    },

    /**
     * Render color picker
     */
    renderColorPicker: (name, label, value) => {
        const colorValue = value === 'transparent' ? '#000000' : (value || '#FFFFFF');
        return `
            <div class="property-field">
                <label>${label}</label>
                <div class="color-picker-wrapper">
                    <input type="color" data-property="${name}" value="${colorValue}" />
                    <input type="text" data-property="${name}-text" value="${value || '#FFFFFF'}" 
                           placeholder="#FFFFFF" />
                </div>
            </div>
        `;
    },

    /**
     * Render button
     */
    renderButton: (label, onclick) => {
        return `<button class="btn-secondary" onclick="${onclick}">${label}</button>`;
    },

    /**
     * Setup event listeners for property inputs
     */
    setupEventListeners: (fabricObject) => {
        const inputs = document.querySelectorAll('#properties-panel input, #properties-panel select, #properties-panel textarea');
        
        inputs.forEach(input => {
            const property = input.getAttribute('data-property');
            if (!property) return;

            const handler = () => {
                Properties.updateWidgetProperty(fabricObject, property, input);
            };

            if (input.type === 'range') {
                input.addEventListener('input', handler);
            } else {
                input.addEventListener('change', handler);
            }

            // Real-time updates for text inputs
            if (input.type === 'text' || input.tagName === 'TEXTAREA') {
                input.addEventListener('input', Utils.debounce(handler, 300));
            }
        });
    },

    /**
     * Update widget property
     */
    updateWidgetProperty: (fabricObject, property, input) => {
        const widget = fabricObject.widgetData;
        
        let value;
        if (input.type === 'checkbox') {
            value = input.checked;
        } else if (input.type === 'number' || input.type === 'range') {
            value = parseFloat(input.value);
        } else {
            value = input.value;
        }

        // Handle nested properties (e.g., action.type)
        if (property.includes('.')) {
            const parts = property.split('.');
            let obj = widget;
            for (let i = 0; i < parts.length - 1; i++) {
                if (!obj[parts[i]]) obj[parts[i]] = {};
                obj = obj[parts[i]];
            }
            obj[parts[parts.length - 1]] = value;
        } else {
            widget[property] = value;
        }

        // Update fabric object
        Properties.applyPropertyToFabricObject(fabricObject, property, value);

        // Trigger canvas update
        Canvas.canvas.requestRenderAll();
        
        if (window.App) {
            App.markDirty();
        }
    },

    /**
     * Apply property to fabric object
     */
    applyPropertyToFabricObject: (fabricObject, property, value) => {
        switch (property) {
            case 'x':
                fabricObject.set({ left: value });
                break;
            case 'y':
                fabricObject.set({ top: value });
                break;
            case 'width':
                fabricObject.set({ width: value, scaleX: 1 });
                break;
            case 'height':
                fabricObject.set({ height: value, scaleY: 1 });
                break;
            case 'rotation':
                fabricObject.set({ angle: value });
                break;
            case 'opacity':
                fabricObject.set({ opacity: value });
                break;
            case 'text':
                if (fabricObject.text !== undefined) {
                    fabricObject.set({ text: value });
                }
                break;
            case 'fontSize':
                if (fabricObject.fontSize !== undefined) {
                    fabricObject.set({ fontSize: value });
                }
                break;
            case 'color':
                if (fabricObject.fill !== undefined) {
                    fabricObject.set({ fill: value });
                }
                break;
            // Add more property mappings as needed
        }
        
        fabricObject.setCoords();
    },

    /**
     * Open conditional formatting dialog
     */
    openConditionalFormatting: () => {
        Utils.notify('Conditional formatting editor coming soon', 'info');
        // TODO: Implement conditional formatting UI
    },

    /**
     * Open animation settings dialog
     */
    openAnimationSettings: () => {
        Utils.notify('Animation settings coming soon', 'info');
        // TODO: Implement animation settings UI
    }
};
