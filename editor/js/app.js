/**
 * VescHub Editor - Main Application Module
 * Coordinates all modules and handles application state
 */

const App = {
    dashboard: null,
    currentScreen: null,
    currentScreenIndex: 0,
    isDirty: false,
    previewMode: false,
    autoSaveInterval: null,
    mockDataInterval: null,
    mockData: {},

    /**
     * Initialize application
     */
    init: () => {
        console.log('Initializing VescHub Editor...');

        // Initialize canvas
        const canvasElement = document.getElementById('editor-canvas');
        if (canvasElement) {
            Canvas.init(canvasElement);
        } else {
            console.error('Canvas element not found');
            return;
        }

        // Initialize dashboard
        App.createNewDashboard();

        // Setup event handlers
        App.setupEventHandlers();

        // Start auto-save
        App.startAutoSave();

        // Check for auto-saved data
        App.checkAutoSave();

        // Setup keyboard shortcuts
        App.setupKeyboardShortcuts();

        console.log('VescHub Editor initialized successfully');
        Utils.notify('VescHub Editor ready', 'success');
    },

    /**
     * Setup event handlers for toolbar buttons
     */
    setupEventHandlers: () => {
        // File menu
        const newBtn = document.getElementById('btn-new');
        if (newBtn) newBtn.addEventListener('click', () => App.newDashboard());

        const saveBtn = document.getElementById('btn-save');
        if (saveBtn) saveBtn.addEventListener('click', () => App.saveDashboard());

        const exportBtn = document.getElementById('btn-export');
        if (exportBtn) exportBtn.addEventListener('click', () => App.exportDashboard());

        const importBtn = document.getElementById('btn-import');
        if (importBtn) importBtn.addEventListener('click', () => Export.loadFile());

        // Edit menu
        const undoBtn = document.getElementById('btn-undo');
        if (undoBtn) undoBtn.addEventListener('click', () => Canvas.undo());

        const redoBtn = document.getElementById('btn-redo');
        if (redoBtn) redoBtn.addEventListener('click', () => Canvas.redo());

        const copyBtn = document.getElementById('btn-copy');
        if (copyBtn) copyBtn.addEventListener('click', () => Canvas.copy());

        const pasteBtn = document.getElementById('btn-paste');
        if (pasteBtn) pasteBtn.addEventListener('click', () => Canvas.paste());

        const deleteBtn = document.getElementById('btn-delete');
        if (deleteBtn) deleteBtn.addEventListener('click', () => Canvas.removeSelected());

        // View menu
        const zoomInBtn = document.getElementById('btn-zoom-in');
        if (zoomInBtn) zoomInBtn.addEventListener('click', () => Canvas.zoomIn());

        const zoomOutBtn = document.getElementById('btn-zoom-out');
        if (zoomOutBtn) zoomOutBtn.addEventListener('click', () => Canvas.zoomOut());

        const zoomFitBtn = document.getElementById('btn-zoom-fit');
        if (zoomFitBtn) zoomFitBtn.addEventListener('click', () => Canvas.zoomToFit());

        const gridBtn = document.getElementById('btn-grid');
        if (gridBtn) gridBtn.addEventListener('click', () => Canvas.toggleGrid());

        const previewBtn = document.getElementById('btn-preview');
        if (previewBtn) previewBtn.addEventListener('click', () => App.togglePreview());

        // Screen management
        const addScreenBtn = document.getElementById('btn-add-screen');
        if (addScreenBtn) addScreenBtn.addEventListener('click', () => App.addScreen());

        const deleteScreenBtn = document.getElementById('btn-delete-screen');
        if (deleteScreenBtn) deleteScreenBtn.addEventListener('click', () => App.deleteScreen());

        const screenSelect = document.getElementById('screen-select');
        if (screenSelect) {
            screenSelect.addEventListener('change', (e) => {
                App.switchScreen(parseInt(e.target.value));
            });
        }

        // Help
        const helpBtn = document.getElementById('btn-help');
        if (helpBtn) helpBtn.addEventListener('click', () => App.showHelp());

        // Examples menu
        const examplesBtn = document.getElementById('btn-examples');
        if (examplesBtn) {
            examplesBtn.addEventListener('click', (e) => {
                App.showExamplesMenu(e);
            });
        }

        // Widget palette - drag to canvas
        App.setupWidgetPalette();

        // Dashboard settings
        const settingsBtn = document.getElementById('btn-settings');
        if (settingsBtn) settingsBtn.addEventListener('click', () => App.showDashboardSettings());
    },

    /**
     * Setup widget palette with drag and drop
     */
    setupWidgetPalette: () => {
        const widgetButtons = document.querySelectorAll('.widget-item');
        widgetButtons.forEach(btn => {
            btn.addEventListener('click', () => {
                const widgetType = btn.getAttribute('data-widget-type');
                if (widgetType) {
                    // Add to center of canvas
                    const centerX = Canvas.canvas.width / 2;
                    const centerY = Canvas.canvas.height / 2;
                    Canvas.addWidget(widgetType, centerX, centerY);
                }
            });

            // Optional: Implement drag from palette (future enhancement)
            btn.setAttribute('draggable', 'true');
            btn.addEventListener('dragstart', (e) => {
                e.dataTransfer.setData('widgetType', btn.getAttribute('data-widget-type'));
            });
        });

        // Canvas drop target
        const canvasWrapper = document.querySelector('.canvas-wrapper');
        if (canvasWrapper) {
            canvasWrapper.addEventListener('dragover', (e) => {
                e.preventDefault();
            });

            canvasWrapper.addEventListener('drop', (e) => {
                e.preventDefault();
                const widgetType = e.dataTransfer.getData('widgetType');
                if (widgetType) {
                    const rect = Canvas.canvas.upperCanvasEl.getBoundingClientRect();
                    const x = e.clientX - rect.left;
                    const y = e.clientY - rect.top;
                    Canvas.addWidget(widgetType, x, y);
                }
            });
        }
    },

    /**
     * Setup keyboard shortcuts
     */
    setupKeyboardShortcuts: () => {
        document.addEventListener('keydown', (e) => {
            // Don't handle shortcuts if typing in input
            if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
                return;
            }

            const ctrl = e.ctrlKey || e.metaKey;

            if (ctrl && e.key === 'n') {
                e.preventDefault();
                App.newDashboard();
            } else if (ctrl && e.key === 's') {
                e.preventDefault();
                App.saveDashboard();
            } else if (ctrl && e.key === 'e') {
                e.preventDefault();
                App.exportDashboard();
            } else if (ctrl && e.key === 'o') {
                e.preventDefault();
                Export.loadFile();
            } else if (ctrl && e.key === 'p') {
                e.preventDefault();
                App.togglePreview();
            } else if (e.key === 'F1') {
                e.preventDefault();
                App.showHelp();
            }
        });
    },

    /**
     * Create new dashboard
     */
    createNewDashboard: () => {
        App.dashboard = {
            version: "1.0",
            name: "New Dashboard",
            description: "",
            author: "",
            defaultScreen: "screen_1",
            theme: {
                defaultFontFamily: "Roboto",
                defaultFontSize: 16,
                defaultColor: "#FFFFFF",
                defaultBackgroundColor: "#000000"
            },
            navigation: {
                swipeEnabled: true,
                swipeDirection: "horizontal",
                buttonNavigation: true
            },
            screens: [
                {
                    id: "screen_1",
                    name: "Screen 1",
                    backgroundColor: "#000000",
                    widgets: []
                }
            ]
        };

        App.currentScreenIndex = 0;
        App.currentScreen = App.dashboard.screens[0];
        App.isDirty = false;

        App.updateUI();
        Canvas.clear();
    },

    /**
     * New dashboard with confirmation
     */
    newDashboard: () => {
        if (App.isDirty) {
            if (Utils.confirm('You have unsaved changes. Create new dashboard anyway?')) {
                App.createNewDashboard();
                Utils.notify('New dashboard created', 'success');
            }
        } else {
            App.createNewDashboard();
            Utils.notify('New dashboard created', 'success');
        }
    },

    /**
     * Save dashboard
     */
    saveDashboard: () => {
        // Update current screen widgets from canvas
        App.updateCurrentScreenFromCanvas();

        // Save to localStorage
        const success = Storage.saveCurrentProject(App.dashboard);
        if (success) {
            App.isDirty = false;
            App.updateTitle();
        }
    },

    /**
     * Export dashboard
     */
    exportDashboard: () => {
        // Update current screen widgets from canvas
        App.updateCurrentScreenFromCanvas();

        // Export to JSON file
        Export.exportDashboard(App.dashboard, true);
    },

    /**
     * Load dashboard
     */
    loadDashboard: (dashboard) => {
        App.dashboard = dashboard;
        App.currentScreenIndex = 0;
        App.currentScreen = App.dashboard.screens[0];
        App.isDirty = false;

        App.updateUI();
        App.loadCurrentScreen();

        Utils.notify(`Loaded "${dashboard.name}"`, 'success');
    },

    /**
     * Update UI elements
     */
    updateUI: () => {
        App.updateTitle();
        App.updateScreenSelect();
        App.updateCanvasBackground();
    },

    /**
     * Update document title
     */
    updateTitle: () => {
        const title = `${App.dashboard.name}${App.isDirty ? ' *' : ''} - VescHub Editor`;
        document.title = title;

        const titleElement = document.getElementById('dashboard-title');
        if (titleElement) {
            titleElement.textContent = App.dashboard.name;
        }
    },

    /**
     * Update screen selector dropdown
     */
    updateScreenSelect: () => {
        const screenList = document.getElementById('screen-list');
        if (!screenList) return;

        // Clear existing screen items
        screenList.innerHTML = '';

        // Create screen items
        App.dashboard.screens.forEach((screen, index) => {
            const screenItem = document.createElement('div');
            screenItem.className = 'screen-item';
            screenItem.setAttribute('data-screen-index', index);
            if (index === App.currentScreenIndex) {
                screenItem.classList.add('active');
            }

            screenItem.innerHTML = `
                <div class="screen-thumbnail">
                    <canvas class="screen-preview" width="80" height="60"></canvas>
                </div>
                <div class="screen-name">${screen.name}</div>
                <div class="screen-actions">
                    <button class="btn-icon-small btn-rename-screen" data-screen-index="${index}" title="Rename">✏️</button>
                    <button class="btn-icon-small btn-duplicate-screen" data-screen-index="${index}" title="Duplicate">📄</button>
                    <button class="btn-icon-small btn-delete-screen" data-screen-index="${index}" title="Delete">🗑️</button>
                </div>
            `;

            // Click on screen item to switch
            screenItem.addEventListener('click', (e) => {
                // Don't switch if clicking on action buttons
                if (!e.target.closest('.screen-actions')) {
                    App.switchScreen(index);
                }
            });

            screenList.appendChild(screenItem);
        });

        // Setup event listeners for action buttons
        document.querySelectorAll('.btn-rename-screen').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const index = parseInt(btn.getAttribute('data-screen-index'));
                App.renameScreen(index);
            });
        });

        document.querySelectorAll('.btn-duplicate-screen').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const index = parseInt(btn.getAttribute('data-screen-index'));
                App.duplicateScreen(index);
            });
        });

        document.querySelectorAll('.btn-delete-screen').forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.stopPropagation();
                const index = parseInt(btn.getAttribute('data-screen-index'));
                App.deleteScreenByIndex(index);
            });
        });
    },

    /**
     * Update canvas background color
     */
    updateCanvasBackground: () => {
        if (App.currentScreen) {
            Canvas.setBackgroundColor(App.currentScreen.backgroundColor || '#000000');
        }
    },

    /**
     * Add new screen
     */
    addScreen: () => {
        const screenName = Utils.prompt('Enter screen name:', `Screen ${App.dashboard.screens.length + 1}`);
        if (!screenName) return;

        const newScreen = {
            id: Utils.generateId('screen'),
            name: screenName,
            backgroundColor: "#000000",
            widgets: []
        };

        App.dashboard.screens.push(newScreen);
        App.markDirty();
        App.updateScreenSelect();

        Utils.notify(`Screen "${screenName}" added`, 'success');
    },

    /**
     * Rename screen
     */
    renameScreen: (index) => {
        if (index < 0 || index >= App.dashboard.screens.length) return;

        const screen = App.dashboard.screens[index];
        const newName = Utils.prompt('Enter new screen name:', screen.name);
        
        if (newName && newName !== screen.name) {
            screen.name = newName;
            App.markDirty();
            App.updateScreenSelect();
            Utils.notify(`Screen renamed to "${newName}"`, 'success');
        }
    },

    /**
     * Duplicate screen
     */
    duplicateScreen: (index) => {
        if (index < 0 || index >= App.dashboard.screens.length) return;

        const screen = App.dashboard.screens[index];
        const newScreen = {
            id: Utils.generateId('screen'),
            name: `${screen.name} (Copy)`,
            backgroundColor: screen.backgroundColor,
            widgets: Utils.deepClone(screen.widgets || [])
        };

        // Update widget IDs in the duplicated screen
        newScreen.widgets.forEach(widget => {
            widget.id = Utils.generateId('widget');
        });

        App.dashboard.screens.push(newScreen);
        App.markDirty();
        App.updateScreenSelect();

        Utils.notify(`Screen "${newScreen.name}" created`, 'success');
    },

    /**
     * Delete screen by index
     */
    deleteScreenByIndex: (index) => {
        if (index < 0 || index >= App.dashboard.screens.length) return;

        if (App.dashboard.screens.length <= 1) {
            Utils.notify('Cannot delete the last screen', 'error');
            return;
        }

        const screen = App.dashboard.screens[index];
        const hasWidgets = screen.widgets && screen.widgets.length > 0;
        const confirmMessage = hasWidgets 
            ? `Delete screen "${screen.name}" and its ${screen.widgets.length} widget(s)?`
            : `Delete screen "${screen.name}"?`;

        if (Utils.confirm(confirmMessage)) {
            App.dashboard.screens.splice(index, 1);
            
            // Adjust current screen index if needed
            if (App.currentScreenIndex >= App.dashboard.screens.length) {
                App.currentScreenIndex = App.dashboard.screens.length - 1;
            }
            if (App.currentScreenIndex === index) {
                App.currentScreenIndex = Math.max(0, index - 1);
            } else if (App.currentScreenIndex > index) {
                App.currentScreenIndex--;
            }
            
            App.currentScreen = App.dashboard.screens[App.currentScreenIndex];
            
            App.markDirty();
            App.updateScreenSelect();
            App.loadCurrentScreen();

            Utils.notify('Screen deleted', 'success');
        }
    },

    /**
     * Delete current screen
     */
    deleteScreen: () => {
        App.deleteScreenByIndex(App.currentScreenIndex);
    },

    /**
     * Switch to different screen
     */
    switchScreen: (index) => {
        if (index < 0 || index >= App.dashboard.screens.length) return;
        if (index === App.currentScreenIndex) return; // Already on this screen

        // Save current screen state
        App.updateCurrentScreenFromCanvas();

        // Switch to new screen
        App.currentScreenIndex = index;
        App.currentScreen = App.dashboard.screens[index];

        // Load new screen
        App.loadCurrentScreen();

        // Update UI to show active screen
        App.updateScreenSelect();

        Utils.notify(`Switched to "${App.currentScreen.name}"`, 'info');
    },

    /**
     * Load current screen onto canvas
     */
    loadCurrentScreen: () => {
        Canvas.loadWidgets(App.currentScreen.widgets || []);
        App.updateCanvasBackground();
    },

    /**
     * Update current screen from canvas
     */
    updateCurrentScreenFromCanvas: () => {
        if (App.currentScreen) {
            App.currentScreen.widgets = Canvas.getAllWidgets();
        }
    },

    /**
     * Mark dashboard as dirty (unsaved changes)
     */
    markDirty: () => {
        App.isDirty = true;
        App.updateTitle();
    },

    /**
     * Toggle preview mode
     */
    togglePreview: () => {
        App.previewMode = !App.previewMode;

        const previewBtn = document.getElementById('btn-preview');
        const leftSidebar = document.getElementById('left-sidebar');
        const rightSidebar = document.getElementById('right-sidebar');
        const bottomPanel = document.getElementById('bottom-panel');
        const toolbar = document.getElementById('toolbar');

        if (App.previewMode) {
            // Enter preview mode
            Canvas.canvas.selection = false;
            Canvas.canvas.forEachObject(obj => {
                obj.selectable = false;
                obj.evented = false;
                
                // Enable button interactivity
                if (obj.widgetData && obj.widgetData.type === 'button') {
                    obj.evented = true;
                    obj.hoverCursor = 'pointer';
                    
                    // Add click handler for buttons
                    obj.on('mousedown', (e) => {
                        App.handleButtonClick(obj.widgetData);
                    });
                }
            });
            Canvas.canvas.requestRenderAll();

            if (previewBtn) previewBtn.classList.add('active');
            if (leftSidebar) leftSidebar.style.display = 'none';
            if (rightSidebar) rightSidebar.style.display = 'none';
            if (bottomPanel) bottomPanel.style.display = 'none';
            
            // Make toolbar translucent for minimal UI
            if (toolbar) {
                toolbar.style.opacity = '0.8';
                toolbar.style.pointerEvents = 'auto';
            }

            App.startMockData();
            Utils.notify('Preview mode enabled - Press P to exit', 'info');
        } else {
            // Exit preview mode
            Canvas.canvas.selection = true;
            Canvas.canvas.forEachObject(obj => {
                if (!obj.isGrid) {
                    obj.selectable = true;
                    obj.evented = true;
                    obj.hoverCursor = 'move';
                    
                    // Remove button click handlers
                    if (obj.widgetData && obj.widgetData.type === 'button') {
                        obj.off('mousedown');
                    }
                }
            });
            Canvas.canvas.requestRenderAll();

            if (previewBtn) previewBtn.classList.remove('active');
            if (leftSidebar) leftSidebar.style.display = '';
            if (rightSidebar) rightSidebar.style.display = '';
            if (bottomPanel) bottomPanel.style.display = '';
            if (toolbar) {
                toolbar.style.opacity = '';
                toolbar.style.pointerEvents = '';
            }

            App.stopMockData();
            Utils.notify('Preview mode disabled', 'info');
        }
    },

    /**
     * Handle button click in preview mode
     */
    handleButtonClick: (buttonWidget) => {
        if (!buttonWidget.action) return;

        const action = buttonWidget.action;
        
        switch (action.type) {
            case 'switchScreen':
                // Find screen by ID or name
                const targetScreenIndex = App.dashboard.screens.findIndex(
                    screen => screen.id === action.target || screen.name === action.target
                );
                
                if (targetScreenIndex >= 0) {
                    App.switchScreen(targetScreenIndex);
                    Utils.notify(`Switched to screen: ${App.dashboard.screens[targetScreenIndex].name}`, 'success');
                } else {
                    Utils.notify(`Screen not found: ${action.target}`, 'error');
                }
                break;
                
            case 'toggleValue':
                // Toggle a boolean value (placeholder implementation)
                Utils.notify(`Toggle action: ${action.target}`, 'info');
                break;
                
            case 'sendCommand':
                // Send command (placeholder implementation)
                Utils.notify(`Command: ${action.target}`, 'info');
                break;
                
            default:
                console.warn('Unknown button action:', action.type);
        }
        
        // Visual feedback for button press (optional enhancement)
        // Could add a brief highlight or animation here
    },

    /**
     * Start mock data simulator for preview
     */
    startMockData: () => {
        // Initialize mock data with realistic starting values
        const startTime = Date.now();
        
        App.mockData = {
            speed: 0,
            battery_percent: 100,
            battery_voltage: 54.0, // Fully charged 13S battery
            battery_current: 0,
            motor_current: 0,
            motor_temp: 25,
            controller_temp: 30,
            duty_cycle: 0,
            rpm: 0,
            amp_hours_used: 0,
            amp_hours_charged: 0,
            watt_hours_used: 0,
            watt_hours_charged: 0,
            odometer: 1234.5,
            trip_distance: 0,
            fault_code: '',
            // Internal state for animation
            _time: 0,
            _speedTarget: 30,
            _speedPhase: 0,
            _tripStartTime: startTime
        };

        // Update mock data at 100ms intervals for smooth animation
        App.mockDataInterval = setInterval(() => {
            const deltaTime = 0.1; // 100ms in seconds
            App.mockData._time += deltaTime;

            // Speed: varies between 0-60 km/h with smooth transitions
            App.mockData._speedPhase += deltaTime * 0.5;
            const speedBase = 30 + Math.sin(App.mockData._speedPhase) * 20;
            const speedNoise = Math.sin(App.mockData._time * 3) * 3;
            App.mockData.speed = Math.max(0, Math.min(60, speedBase + speedNoise));

            // RPM: proportional to speed (roughly 70 rpm per km/h for typical e-board)
            App.mockData.rpm = App.mockData.speed * 70;

            // Duty cycle: 0-100% proportional to speed
            App.mockData.duty_cycle = (App.mockData.speed / 60) * 100;

            // Battery percent: slowly decreases (loses ~0.1% per second of riding)
            if (App.mockData.speed > 5) {
                App.mockData.battery_percent -= 0.01 * deltaTime;
                App.mockData.battery_percent = Math.max(0, App.mockData.battery_percent);
            }

            // Battery voltage: 48V-54V based on battery percent (13S LiPo/Li-ion)
            App.mockData.battery_voltage = 48.0 + (App.mockData.battery_percent / 100) * 6.0;

            // Battery current: 0-30A varying with speed and acceleration
            const currentTarget = (App.mockData.speed / 60) * 25 + Math.sin(App.mockData._time * 2) * 5;
            App.mockData.battery_current = Math.max(0, Math.min(30, currentTarget));

            // Motor current: 0-50A with variation
            App.mockData.motor_current = App.mockData.battery_current * 1.5 + Math.sin(App.mockData._time * 1.5) * 10;
            App.mockData.motor_current = Math.max(0, Math.min(50, App.mockData.motor_current));

            // Motor temperature: 25-60°C, slowly increases with use
            if (App.mockData.speed > 10) {
                App.mockData.motor_temp += 0.02 * deltaTime;
            } else {
                App.mockData.motor_temp -= 0.01 * deltaTime; // Cooling down
            }
            App.mockData.motor_temp = Math.max(25, Math.min(60, App.mockData.motor_temp));

            // Controller temperature: 30-55°C
            if (App.mockData.speed > 10) {
                App.mockData.controller_temp += 0.015 * deltaTime;
            } else {
                App.mockData.controller_temp -= 0.01 * deltaTime;
            }
            App.mockData.controller_temp = Math.max(30, Math.min(55, App.mockData.controller_temp));

            // Odometer and trip distance: increment based on speed
            const distanceIncrement = (App.mockData.speed / 3600) * deltaTime; // km
            App.mockData.trip_distance += distanceIncrement;
            App.mockData.odometer += distanceIncrement;

            // Energy consumption
            const powerUsed = App.mockData.battery_voltage * App.mockData.battery_current; // Watts
            App.mockData.watt_hours_used += (powerUsed / 3600) * deltaTime;
            
            // Consumption in Wh/km: calculate from energy used and distance traveled
            if (App.mockData.trip_distance > 0.1) {
                App.mockData.consumption_wh_per_km = App.mockData.watt_hours_used / App.mockData.trip_distance;
            } else {
                App.mockData.consumption_wh_per_km = 20; // Default
            }

            // Update widgets with new mock data
            App.updateWidgetsWithMockData();
        }, 100);
    },

    /**
     * Update widgets with mock data values
     */
    updateWidgetsWithMockData: () => {
        if (!Canvas.canvas) return;

        let updatedCount = 0;
        Canvas.canvas.getObjects().forEach(obj => {
            if (obj.isGrid || !obj.widgetData) return;

            const widget = obj.widgetData;
            const dataSource = widget.dataSource;

            if (!dataSource || !App.mockData.hasOwnProperty(dataSource)) return;

            const value = App.mockData[dataSource];

            // Update widget based on type using Widgets module
            switch (widget.type) {
                case 'text':
                    if (Widgets.updateText) {
                        Widgets.updateText(obj, widget, value);
                        updatedCount++;
                    }
                    break;
                case 'gauge':
                case 'speedometer':
                    if (Widgets.updateGauge) {
                        Widgets.updateGauge(obj, widget, value);
                        updatedCount++;
                    }
                    break;
                case 'progressbar':
                    if (Widgets.updateProgressBar) {
                        Widgets.updateProgressBar(obj, widget, value);
                        updatedCount++;
                    }
                    break;
                case 'indicator':
                    if (Widgets.updateIndicator) {
                        Widgets.updateIndicator(obj, widget, value);
                        updatedCount++;
                    }
                    break;
            }
        });

        if (updatedCount > 0) {
            Canvas.canvas.requestRenderAll();
        }
    },

    /**
     * Update text widget with data value
     */
    updateTextWidget: (fabricObject, value, widget) => {
        if (fabricObject.type !== 'text') return;

        // Format value
        let formattedValue = value;
        
        if (typeof value === 'number') {
            const decimals = widget.decimals || 0;
            formattedValue = value.toFixed(decimals);
        }

        // Apply prefix and suffix
        const prefix = widget.prefix || '';
        const suffix = widget.suffix || '';
        const displayText = `${prefix}${formattedValue}${suffix}`;

        fabricObject.set({ text: displayText });
    },

    /**
     * Update gauge widget with data value
     */
    updateGaugeWidget: (fabricObject, value, widget) => {
        // For now, we'll just update the widget data
        // Full gauge animation will be implemented in the gauge rendering enhancement
        widget.currentValue = value;
    },

    /**
     * Update progress bar widget with data value
     */
    updateProgressBarWidget: (fabricObject, value, widget) => {
        // Calculate percentage based on min/max
        const min = widget.minValue || 0;
        const max = widget.maxValue || 100;
        const percentage = Math.max(0, Math.min(1, (value - min) / (max - min)));

        // Update progress bar fill
        // This is a simplified update - full implementation would redraw the progress bar
        widget.currentValue = value;
        widget.currentPercentage = percentage;
    },

    /**
     * Update indicator widget with data value
     */
    updateIndicatorWidget: (fabricObject, value, widget) => {
        const threshold = widget.threshold || 0.5;
        const isOn = value > threshold;
        
        // Update color based on on/off state
        const color = isOn ? (widget.onColor || '#00FF00') : (widget.offColor || '#2A2A2A');
        
        if (fabricObject.type === 'circle') {
            fabricObject.set({ fill: color });
        }
    },

    /**
     * Update consumption widget with data value
     */
    updateConsumptionWidget: (fabricObject, value, widget) => {
        if (widget.displayMode === 'text') {
            // Update text widget
            App.updateTextWidget(fabricObject, value, widget);
            
            // Update color based on efficiency
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
            
            if (fabricObject.type === 'text') {
                fabricObject.set({ fill: color });
            }
        } else {
            // Update gauge widget
            App.updateGaugeWidget(fabricObject, value, widget);
        }
    },

    /**
     * Stop mock data simulator
     */
    stopMockData: () => {
        if (App.mockDataInterval) {
            clearInterval(App.mockDataInterval);
            App.mockDataInterval = null;
        }
    },

    /**
     * Start auto-save timer
     */
    startAutoSave: () => {
        App.autoSaveInterval = setInterval(() => {
            if (App.isDirty) {
                App.updateCurrentScreenFromCanvas();
                Storage.autoSave(App.dashboard);
            }
        }, 30000); // 30 seconds
    },

    /**
     * Check for auto-saved data on startup
     */
    checkAutoSave: () => {
        const autoSave = Storage.getAutoSave();
        if (autoSave && autoSave.dashboard) {
            const message = `Found auto-saved dashboard from ${Utils.formatDate(autoSave.timestamp)}. Restore it?`;
            if (Utils.confirm(message)) {
                App.loadDashboard(autoSave.dashboard);
                Storage.clearAutoSave();
            }
        }
    },

    /**
     * Show help modal
     */
    showHelp: () => {
        const helpContent = `
            <h2>VescHub Editor - Help</h2>
            
            <h3>Keyboard Shortcuts</h3>
            <ul>
                <li><kbd>Ctrl+N</kbd> - New dashboard</li>
                <li><kbd>Ctrl+S</kbd> - Save dashboard</li>
                <li><kbd>Ctrl+E</kbd> - Export dashboard</li>
                <li><kbd>Ctrl+O</kbd> - Import dashboard</li>
                <li><kbd>Ctrl+Z</kbd> - Undo</li>
                <li><kbd>Ctrl+Y</kbd> - Redo</li>
                <li><kbd>Ctrl+C</kbd> - Copy</li>
                <li><kbd>Ctrl+V</kbd> - Paste</li>
                <li><kbd>Ctrl+D</kbd> - Duplicate</li>
                <li><kbd>Delete</kbd> - Delete selected</li>
                <li><kbd>Ctrl+P</kbd> - Toggle preview</li>
                <li><kbd>F1</kbd> - Show help</li>
                <li><kbd>Esc</kbd> - Clear selection</li>
            </ul>

            <h3>Mouse Controls</h3>
            <ul>
                <li><strong>Left Click</strong> - Select widget</li>
                <li><strong>Shift+Click</strong> - Multi-select</li>
                <li><strong>Right Click</strong> - Context menu</li>
                <li><strong>Middle Mouse / Ctrl+Drag</strong> - Pan canvas</li>
                <li><strong>Mouse Wheel</strong> - Zoom in/out</li>
                <li><strong>Drag</strong> - Move widget</li>
                <li><strong>Drag Corners</strong> - Resize widget</li>
            </ul>

            <h3>Widget Types</h3>
            <ul>
                <li><strong>Text</strong> - Display text or data values</li>
                <li><strong>Button</strong> - Interactive button for actions</li>
                <li><strong>Gauge</strong> - Circular or semicircular gauge</li>
                <li><strong>Speedometer</strong> - Speed display with dial</li>
                <li><strong>Graph</strong> - Line or bar chart</li>
                <li><strong>Progress Bar</strong> - Horizontal or vertical bar</li>
                <li><strong>Indicator</strong> - LED-style indicator</li>
                <li><strong>Image</strong> - Display image</li>
                <li><strong>Shape</strong> - Basic shapes (rectangle, circle, line)</li>
            </ul>

            <h3>Tips</h3>
            <ul>
                <li>Use the widget palette to add widgets to the canvas</li>
                <li>Select a widget to edit its properties in the right panel</li>
                <li>Use alignment tools for precise positioning</li>
                <li>Test your dashboard in preview mode</li>
                <li>Export dashboards to share or backup</li>
                <li>Load example dashboards to get started quickly</li>
            </ul>

            <button onclick="App.closeHelp()" class="btn-primary">Close</button>
        `;

        App.showModal('Help', helpContent);
    },

    /**
     * Show examples menu
     */
    showExamplesMenu: (event) => {
        const examples = Export.getExampleDashboards();
        const menu = document.createElement('div');
        menu.className = 'examples-menu';
        menu.style.cssText = `
            position: absolute;
            background: #2A2A2A;
            border: 1px solid #3A3A3A;
            border-radius: 4px;
            padding: 8px 0;
            box-shadow: 0 4px 8px rgba(0,0,0,0.4);
            z-index: 1000;
        `;

        examples.forEach((example, index) => {
            const item = document.createElement('div');
            item.className = 'menu-item';
            item.textContent = example.name;
            item.style.cssText = `
                padding: 8px 16px;
                cursor: pointer;
                white-space: nowrap;
            `;
            item.addEventListener('mouseover', () => {
                item.style.backgroundColor = '#3A3A3A';
            });
            item.addEventListener('mouseout', () => {
                item.style.backgroundColor = 'transparent';
            });
            item.addEventListener('click', () => {
                Export.loadExample(index);
                document.body.removeChild(menu);
            });
            menu.appendChild(item);
        });

        const rect = event.target.getBoundingClientRect();
        menu.style.left = rect.left + 'px';
        menu.style.top = (rect.bottom + 5) + 'px';

        document.body.appendChild(menu);

        // Close on click outside
        setTimeout(() => {
            const closeMenu = (e) => {
                if (!menu.contains(e.target)) {
                    document.body.removeChild(menu);
                    document.removeEventListener('click', closeMenu);
                }
            };
            document.addEventListener('click', closeMenu);
        }, 100);
    },

    /**
     * Show dashboard settings
     */
    showDashboardSettings: () => {
        const settingsContent = `
            <h2>Dashboard Settings</h2>
            <div class="settings-form">
                <div class="form-group">
                    <label>Dashboard Name</label>
                    <input type="text" id="setting-name" value="${App.dashboard.name}" />
                </div>
                <div class="form-group">
                    <label>Description</label>
                    <textarea id="setting-description" rows="3">${App.dashboard.description || ''}</textarea>
                </div>
                <div class="form-group">
                    <label>Author</label>
                    <input type="text" id="setting-author" value="${App.dashboard.author || ''}" />
                </div>
                <div class="form-group">
                    <label>Canvas Width</label>
                    <input type="number" id="setting-width" value="${Canvas.canvas.width}" min="400" max="2000" />
                </div>
                <div class="form-group">
                    <label>Canvas Height</label>
                    <input type="number" id="setting-height" value="${Canvas.canvas.height}" min="300" max="1200" />
                </div>
                <button onclick="App.applyDashboardSettings()" class="btn-primary">Apply</button>
                <button onclick="App.closeModal()" class="btn-secondary">Cancel</button>
            </div>
        `;

        App.showModal('Settings', settingsContent);
    },

    /**
     * Apply dashboard settings
     */
    applyDashboardSettings: () => {
        const name = document.getElementById('setting-name').value;
        const description = document.getElementById('setting-description').value;
        const author = document.getElementById('setting-author').value;
        const width = parseInt(document.getElementById('setting-width').value);
        const height = parseInt(document.getElementById('setting-height').value);

        if (name) App.dashboard.name = name;
        if (description !== undefined) App.dashboard.description = description;
        if (author !== undefined) App.dashboard.author = author;

        if (width && height) {
            Canvas.resize(width, height);
        }

        App.markDirty();
        App.updateUI();
        App.closeModal();

        Utils.notify('Settings applied', 'success');
    },

    /**
     * Show modal dialog
     */
    showModal: (title, content) => {
        let modal = document.getElementById('app-modal');
        if (!modal) {
            modal = document.createElement('div');
            modal.id = 'app-modal';
            modal.style.cssText = `
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.8);
                display: flex;
                align-items: center;
                justify-content: center;
                z-index: 10000;
            `;
            document.body.appendChild(modal);
        }

        modal.innerHTML = `
            <div style="
                background: #1A1A1A;
                border: 1px solid #3A3A3A;
                border-radius: 8px;
                padding: 24px;
                max-width: 600px;
                max-height: 80vh;
                overflow-y: auto;
                box-shadow: 0 8px 16px rgba(0,0,0,0.6);
            ">
                ${content}
            </div>
        `;

        modal.style.display = 'flex';
    },

    /**
     * Close modal dialog
     */
    closeModal: () => {
        const modal = document.getElementById('app-modal');
        if (modal) {
            modal.style.display = 'none';
        }
    },

    closeHelp: () => {
        App.closeModal();
    },

    /**
     * Handle window beforeunload
     */
    handleBeforeUnload: (e) => {
        if (App.isDirty) {
            e.preventDefault();
            e.returnValue = 'You have unsaved changes. Are you sure you want to leave?';
            return e.returnValue;
        }
    }
};

// Initialize app when DOM is ready
document.addEventListener('DOMContentLoaded', App.init);

// Handle page unload
window.addEventListener('beforeunload', App.handleBeforeUnload);
