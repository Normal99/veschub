/**
 * VescHub Editor - Export/Import Module
 * Dashboard export/import with JSON schema validation
 */

const Export = {
    /**
     * Export dashboard to JSON
     */
    exportDashboard: (dashboard, download = true) => {
        try {
            // Build dashboard JSON according to schema
            const exportData = {
                version: "1.0",
                name: dashboard.name || "Untitled Dashboard",
                description: dashboard.description || "",
                author: dashboard.author || "",
                defaultScreen: dashboard.defaultScreen || (dashboard.screens[0]?.id),
                theme: dashboard.theme || {
                    defaultFontFamily: "Roboto",
                    defaultFontSize: 16,
                    defaultColor: "#FFFFFF",
                    defaultBackgroundColor: "#000000"
                },
                navigation: dashboard.navigation || {
                    swipeEnabled: true,
                    swipeDirection: "horizontal",
                    buttonNavigation: true
                },
                screens: dashboard.screens || []
            };

            // Validate export data
            const validation = Export.validateDashboard(exportData);
            if (!validation.valid) {
                console.error('Validation errors:', validation.errors);
                Utils.notify('Dashboard has validation errors. Check console.', 'error');
                // Still allow export despite validation errors
            }

            const json = JSON.stringify(exportData, null, 2);

            if (download) {
                const filename = `${exportData.name.toLowerCase().replace(/\s+/g, '_')}_dashboard.json`;
                Utils.downloadFile(filename, json);
                Utils.notify('Dashboard exported successfully', 'success');
            }

            return json;
        } catch (error) {
            console.error('Export error:', error);
            Utils.notify('Error exporting dashboard: ' + error.message, 'error');
            return null;
        }
    },

    /**
     * Import dashboard from JSON
     */
    importDashboard: (jsonString) => {
        try {
            const dashboard = JSON.parse(jsonString);

            // Validate dashboard
            const validation = Export.validateDashboard(dashboard);
            if (!validation.valid) {
                console.error('Validation errors:', validation.errors);
                Utils.notify('Invalid dashboard format. See console for details.', 'error');
                return null;
            }

            // Additional checks
            if (!dashboard.screens || dashboard.screens.length === 0) {
                Utils.notify('Dashboard must have at least one screen', 'error');
                return null;
            }

            Utils.notify('Dashboard imported successfully', 'success');
            return dashboard;
        } catch (error) {
            console.error('Import error:', error);
            Utils.notify('Error importing dashboard: ' + error.message, 'error');
            return null;
        }
    },

    /**
     * Validate dashboard against schema
     */
    validateDashboard: (dashboard) => {
        const errors = [];

        // Required fields
        if (!dashboard.version) {
            errors.push('Missing required field: version');
        }
        if (!dashboard.name) {
            errors.push('Missing required field: name');
        }
        if (!dashboard.screens) {
            errors.push('Missing required field: screens');
        }

        // Version format
        if (dashboard.version && !/^\d+\.\d+$/.test(dashboard.version)) {
            errors.push('Invalid version format (expected: major.minor)');
        }

        // Screens validation
        if (dashboard.screens) {
            if (!Array.isArray(dashboard.screens)) {
                errors.push('screens must be an array');
            } else if (dashboard.screens.length === 0) {
                errors.push('Dashboard must have at least one screen');
            } else {
                dashboard.screens.forEach((screen, index) => {
                    const screenErrors = Export.validateScreen(screen, index);
                    errors.push(...screenErrors);
                });
            }
        }

        // Theme validation
        if (dashboard.theme) {
            const themeErrors = Export.validateTheme(dashboard.theme);
            errors.push(...themeErrors);
        }

        return {
            valid: errors.length === 0,
            errors: errors
        };
    },

    /**
     * Validate screen
     */
    validateScreen: (screen, index) => {
        const errors = [];
        const prefix = `Screen ${index}:`;

        if (!screen.id) {
            errors.push(`${prefix} Missing required field: id`);
        }
        if (!screen.name) {
            errors.push(`${prefix} Missing required field: name`);
        }
        if (!screen.widgets) {
            errors.push(`${prefix} Missing required field: widgets`);
        }

        if (screen.widgets) {
            if (!Array.isArray(screen.widgets)) {
                errors.push(`${prefix} widgets must be an array`);
            } else {
                screen.widgets.forEach((widget, widgetIndex) => {
                    const widgetErrors = Export.validateWidget(widget, widgetIndex);
                    errors.push(...widgetErrors.map(e => `${prefix} ${e}`));
                });
            }
        }

        // Validate colors
        if (screen.backgroundColor && !Utils.isValidColor(screen.backgroundColor)) {
            errors.push(`${prefix} Invalid backgroundColor format`);
        }

        return errors;
    },

    /**
     * Validate widget
     */
    validateWidget: (widget, index) => {
        const errors = [];
        const prefix = `Widget ${index}:`;

        const requiredFields = ['id', 'type', 'x', 'y', 'width', 'height'];
        requiredFields.forEach(field => {
            if (widget[field] === undefined) {
                errors.push(`${prefix} Missing required field: ${field}`);
            }
        });

        // Validate widget type
        const validTypes = ['text', 'button', 'gauge', 'graph', 'progressbar', 'image', 'shape', 'indicator', 'speedometer'];
        if (widget.type && !validTypes.includes(widget.type)) {
            errors.push(`${prefix} Invalid widget type: ${widget.type}`);
        }

        // Validate numeric fields
        if (typeof widget.x !== 'number') {
            errors.push(`${prefix} x must be a number`);
        }
        if (typeof widget.y !== 'number') {
            errors.push(`${prefix} y must be a number`);
        }
        if (typeof widget.width !== 'number' || widget.width < 0) {
            errors.push(`${prefix} width must be a positive number`);
        }
        if (typeof widget.height !== 'number' || widget.height < 0) {
            errors.push(`${prefix} height must be a positive number`);
        }

        // Validate colors
        const colorFields = ['color', 'backgroundColor', 'fillColor', 'strokeColor', 'needleColor', 'onColor', 'offColor'];
        colorFields.forEach(field => {
            if (widget[field] && widget[field] !== 'transparent' && !Utils.isValidColor(widget[field])) {
                errors.push(`${prefix} Invalid ${field} format`);
            }
        });

        // Type-specific validation
        if (widget.type === 'button' && !widget.imageUnpressed) {
            errors.push(`${prefix} Button widget requires imageUnpressed`);
        }
        if (widget.type === 'button' && !widget.action) {
            errors.push(`${prefix} Button widget requires action`);
        }
        if (widget.type === 'image' && !widget.imagePath) {
            errors.push(`${prefix} Image widget requires imagePath`);
        }

        return errors;
    },

    /**
     * Validate theme
     */
    validateTheme: (theme) => {
        const errors = [];

        // Validate colors
        const colorFields = ['defaultColor', 'defaultBackgroundColor', 'accentColor', 'warningColor', 'dangerColor'];
        colorFields.forEach(field => {
            if (theme[field] && !Utils.isValidColor(theme[field])) {
                errors.push(`Invalid theme ${field} format`);
            }
        });

        // Validate font size
        if (theme.defaultFontSize !== undefined) {
            if (typeof theme.defaultFontSize !== 'number' || theme.defaultFontSize < 8 || theme.defaultFontSize > 200) {
                errors.push('defaultFontSize must be between 8 and 200');
            }
        }

        return errors;
    },

    /**
     * Load JSON file from user
     */
    loadFile: () => {
        Utils.loadFile((content, filename) => {
            const dashboard = Export.importDashboard(content);
            if (dashboard) {
                if (window.App) {
                    App.loadDashboard(dashboard);
                }
            }
        }, '.json');
    },

    /**
     * Create example dashboards
     */
    getExampleDashboards: () => {
        return [
            Export.createMinimalExample(),
            Export.createSpeedExample(),
            Export.createBatteryExample(),
            Export.createComprehensiveExample()
        ];
    },

    /**
     * Create minimal example
     */
    createMinimalExample: () => {
        return {
            version: "1.0",
            name: "Minimal Dashboard",
            description: "A minimal dashboard with basic widgets",
            screens: [
                {
                    id: "screen1",
                    name: "Main Screen",
                    backgroundColor: "#000000",
                    widgets: [
                        {
                            id: "text1",
                            type: "text",
                            x: 50,
                            y: 50,
                            width: 300,
                            height: 60,
                            text: "Speed",
                            fontSize: 24,
                            fontFamily: "Roboto",
                            color: "#FFFFFF",
                            textAlign: "center",
                            dataSource: "speed",
                            suffix: " km/h",
                            decimals: 1
                        },
                        {
                            id: "text2",
                            type: "text",
                            x: 50,
                            y: 130,
                            width: 300,
                            height: 60,
                            text: "Battery",
                            fontSize: 24,
                            fontFamily: "Roboto",
                            color: "#00FF00",
                            textAlign: "center",
                            dataSource: "battery_percent",
                            suffix: "%",
                            decimals: 0
                        }
                    ]
                }
            ]
        };
    },

    /**
     * Create speed-focused example
     */
    createSpeedExample: () => {
        return {
            version: "1.0",
            name: "Speed Dashboard",
            description: "Dashboard focused on speed and performance",
            theme: {
                defaultFontFamily: "Roboto",
                defaultColor: "#00FFFF",
                defaultBackgroundColor: "#000000"
            },
            screens: [
                {
                    id: "main",
                    name: "Speed",
                    backgroundColor: "#000000",
                    widgets: [
                        {
                            id: "speedometer",
                            type: "speedometer",
                            x: 275,
                            y: 115,
                            width: 250,
                            height: 250,
                            minValue: 0,
                            maxValue: 80,
                            units: "km/h",
                            dataSource: "speed",
                            needleColor: "#00FFFF",
                            redZoneStart: 70,
                            showDigitalDisplay: true,
                            digitalFontSize: 48
                        },
                        {
                            id: "rpm_gauge",
                            type: "gauge",
                            x: 50,
                            y: 300,
                            width: 120,
                            height: 120,
                            gaugeType: "circular",
                            minValue: 0,
                            maxValue: 10000,
                            dataSource: "rpm",
                            units: "RPM",
                            needleColor: "#FF9900",
                            showTicks: true
                        },
                        {
                            id: "power_text",
                            type: "text",
                            x: 600,
                            y: 350,
                            width: 150,
                            height: 50,
                            text: "Power",
                            fontSize: 32,
                            color: "#FFFF00",
                            textAlign: "right",
                            dataSource: "motor_current",
                            suffix: " A",
                            decimals: 1
                        }
                    ]
                }
            ]
        };
    },

    /**
     * Create battery-focused example
     */
    createBatteryExample: () => {
        return {
            version: "1.0",
            name: "Battery Monitor",
            description: "Dashboard for battery monitoring",
            screens: [
                {
                    id: "battery",
                    name: "Battery",
                    backgroundColor: "#001100",
                    widgets: [
                        {
                            id: "battery_bar",
                            type: "progressbar",
                            x: 150,
                            y: 100,
                            width: 500,
                            height: 80,
                            orientation: "horizontal",
                            minValue: 0,
                            maxValue: 100,
                            fillColor: "#00FF00",
                            backgroundColor: "#2A2A2A",
                            borderRadius: 10,
                            dataSource: "battery_percent",
                            showValue: true,
                            conditionalFormatting: [
                                {
                                    condition: "battery_percent < 20",
                                    properties: { fillColor: "#FF0000" }
                                },
                                {
                                    condition: "battery_percent < 50",
                                    properties: { fillColor: "#FFAA00" }
                                }
                            ]
                        },
                        {
                            id: "voltage_text",
                            type: "text",
                            x: 150,
                            y: 200,
                            width: 250,
                            height: 50,
                            text: "Voltage",
                            fontSize: 28,
                            color: "#FFFFFF",
                            dataSource: "battery_voltage",
                            suffix: " V",
                            decimals: 2
                        },
                        {
                            id: "current_text",
                            type: "text",
                            x: 400,
                            y: 200,
                            width: 250,
                            height: 50,
                            text: "Current",
                            fontSize: 28,
                            color: "#FFFFFF",
                            dataSource: "battery_current",
                            suffix: " A",
                            decimals: 2
                        },
                        {
                            id: "temp_indicator",
                            type: "indicator",
                            x: 350,
                            y: 300,
                            width: 100,
                            height: 100,
                            onColor: "#FF0000",
                            offColor: "#2A2A2A",
                            dataSource: "controller_temp",
                            threshold: 60,
                            blinkWhenOn: true,
                            blinkRate: 500
                        }
                    ]
                }
            ]
        };
    },

    /**
     * Create comprehensive example
     */
    createComprehensiveExample: () => {
        return {
            version: "1.0",
            name: "Complete Dashboard",
            description: "Comprehensive dashboard with multiple screens",
            author: "VescHub",
            defaultScreen: "main",
            theme: {
                defaultFontFamily: "Roboto",
                defaultFontSize: 16,
                defaultColor: "#FFFFFF",
                defaultBackgroundColor: "#000000",
                accentColor: "#00FFFF",
                warningColor: "#FFAA00",
                dangerColor: "#FF0000"
            },
            navigation: {
                swipeEnabled: true,
                swipeDirection: "horizontal",
                buttonNavigation: true
            },
            screens: [
                {
                    id: "main",
                    name: "Main",
                    backgroundColor: "#000000",
                    widgets: [
                        {
                            id: "speed_display",
                            type: "text",
                            x: 250,
                            y: 50,
                            width: 300,
                            height: 100,
                            text: "Speed",
                            fontSize: 72,
                            fontWeight: "bold",
                            color: "#00FFFF",
                            textAlign: "center",
                            dataSource: "speed",
                            suffix: " km/h",
                            decimals: 1
                        },
                        {
                            id: "battery_bar",
                            type: "progressbar",
                            x: 50,
                            y: 200,
                            width: 700,
                            height: 50,
                            orientation: "horizontal",
                            minValue: 0,
                            maxValue: 100,
                            fillColor: "#00FF00",
                            backgroundColor: "#2A2A2A",
                            dataSource: "battery_percent",
                            showValue: true
                        },
                        {
                            id: "trip_distance",
                            type: "text",
                            x: 50,
                            y: 300,
                            width: 200,
                            height: 50,
                            text: "Trip",
                            fontSize: 24,
                            color: "#FFFFFF",
                            dataSource: "trip_distance",
                            suffix: " km",
                            decimals: 2
                        },
                        {
                            id: "motor_temp",
                            type: "text",
                            x: 550,
                            y: 300,
                            width: 200,
                            height: 50,
                            text: "Motor Temp",
                            fontSize: 24,
                            color: "#FFFFFF",
                            dataSource: "motor_temp",
                            suffix: " °C",
                            decimals: 1
                        },
                        {
                            id: "nav_button",
                            type: "button",
                            x: 350,
                            y: 380,
                            width: 100,
                            height: 80,
                            imageUnpressed: "assets/icons/next.png",
                            action: {
                                type: "switchScreen",
                                target: "details"
                            }
                        }
                    ]
                },
                {
                    id: "details",
                    name: "Details",
                    backgroundColor: "#000000",
                    widgets: [
                        {
                            id: "power_graph",
                            type: "graph",
                            x: 50,
                            y: 50,
                            width: 700,
                            height: 200,
                            graphType: "line",
                            timeWindow: 60,
                            backgroundColor: "#1A1A1A",
                            gridColor: "#2A2A2A",
                            showGrid: true,
                            autoScale: true,
                            dataSeries: [
                                {
                                    dataSource: "battery_current",
                                    label: "Current",
                                    color: "#00FFFF",
                                    lineWidth: 2
                                }
                            ]
                        },
                        {
                            id: "voltage_text",
                            type: "text",
                            x: 50,
                            y: 280,
                            width: 200,
                            height: 50,
                            fontSize: 20,
                            color: "#FFFFFF",
                            dataSource: "battery_voltage",
                            prefix: "V: ",
                            decimals: 2
                        },
                        {
                            id: "back_button",
                            type: "button",
                            x: 350,
                            y: 380,
                            width: 100,
                            height: 80,
                            imageUnpressed: "assets/icons/back.png",
                            action: {
                                type: "switchScreen",
                                target: "main"
                            }
                        }
                    ]
                }
            ]
        };
    },

    /**
     * Export example to file
     */
    exportExample: (index) => {
        const examples = Export.getExampleDashboards();
        if (index >= 0 && index < examples.length) {
            const example = examples[index];
            const json = JSON.stringify(example, null, 2);
            const filename = `${example.name.toLowerCase().replace(/\s+/g, '_')}_example.json`;
            Utils.downloadFile(filename, json);
            Utils.notify(`Example "${example.name}" exported`, 'success');
        }
    },

    /**
     * Load example into editor
     */
    loadExample: (index) => {
        const examples = Export.getExampleDashboards();
        if (index >= 0 && index < examples.length) {
            const example = examples[index];
            if (window.App) {
                if (App.isDirty) {
                    if (Utils.confirm('You have unsaved changes. Load example anyway?')) {
                        App.loadDashboard(example);
                    }
                } else {
                    App.loadDashboard(example);
                }
            }
        }
    }
};
