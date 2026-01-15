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

        const gridBtn = document.getElementById('btn-toggle-grid');
        if (gridBtn) gridBtn.addEventListener('click', () => Canvas.toggleSnapToGrid());

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
        const screenSelect = document.getElementById('screen-select');
        if (!screenSelect) return;

        screenSelect.innerHTML = '';
        App.dashboard.screens.forEach((screen, index) => {
            const option = document.createElement('option');
            option.value = index;
            option.textContent = screen.name;
            option.selected = index === App.currentScreenIndex;
            screenSelect.appendChild(option);
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
     * Delete current screen
     */
    deleteScreen: () => {
        if (App.dashboard.screens.length <= 1) {
            Utils.notify('Cannot delete the last screen', 'error');
            return;
        }

        if (Utils.confirm(`Delete screen "${App.currentScreen.name}"?`)) {
            App.dashboard.screens.splice(App.currentScreenIndex, 1);
            App.currentScreenIndex = Math.max(0, App.currentScreenIndex - 1);
            App.currentScreen = App.dashboard.screens[App.currentScreenIndex];
            
            App.markDirty();
            App.updateScreenSelect();
            App.loadCurrentScreen();

            Utils.notify('Screen deleted', 'success');
        }
    },

    /**
     * Switch to different screen
     */
    switchScreen: (index) => {
        if (index < 0 || index >= App.dashboard.screens.length) return;

        // Save current screen state
        App.updateCurrentScreenFromCanvas();

        // Switch to new screen
        App.currentScreenIndex = index;
        App.currentScreen = App.dashboard.screens[index];

        // Load new screen
        App.loadCurrentScreen();

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
        const editorPanel = document.querySelector('.editor-container');

        if (App.previewMode) {
            // Enter preview mode
            Canvas.canvas.selection = false;
            Canvas.canvas.forEachObject(obj => {
                obj.selectable = false;
                obj.evented = false;
            });
            Canvas.canvas.requestRenderAll();

            if (previewBtn) previewBtn.classList.add('active');
            if (editorPanel) editorPanel.classList.add('preview-mode');

            App.startMockData();
            Utils.notify('Preview mode enabled', 'info');
        } else {
            // Exit preview mode
            Canvas.canvas.selection = true;
            Canvas.canvas.forEachObject(obj => {
                if (!obj.isGrid) {
                    obj.selectable = true;
                    obj.evented = true;
                }
            });
            Canvas.canvas.requestRenderAll();

            if (previewBtn) previewBtn.classList.remove('active');
            if (editorPanel) editorPanel.classList.remove('preview-mode');

            App.stopMockData();
            Utils.notify('Preview mode disabled', 'info');
        }
    },

    /**
     * Start mock data simulator for preview
     */
    startMockData: () => {
        App.mockData = {
            speed: 0,
            battery_percent: 100,
            battery_voltage: 42.0,
            battery_current: 0,
            motor_current: 0,
            motor_temp: 25,
            controller_temp: 25,
            duty_cycle: 0,
            rpm: 0,
            trip_distance: 0,
            odometer: 1234.5
        };

        App.mockDataInterval = setInterval(() => {
            // Simulate changing data
            App.mockData.speed = 20 + Math.sin(Date.now() / 1000) * 15;
            App.mockData.battery_percent = 100 - (Date.now() % 100000) / 1000;
            App.mockData.battery_current = 5 + Math.sin(Date.now() / 1000) * 5;
            App.mockData.motor_current = 10 + Math.sin(Date.now() / 500) * 8;
            App.mockData.motor_temp = 30 + Math.random() * 10;
            App.mockData.rpm = App.mockData.speed * 100;
            App.mockData.duty_cycle = App.mockData.speed / 80 * 100;

            // Update widgets with mock data (simplified)
            // In a real implementation, this would update the visual representation
            console.log('Mock data update:', App.mockData);
        }, 100);
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
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', App.init);
} else {
    App.init();
}

// Handle page unload
window.addEventListener('beforeunload', App.handleBeforeUnload);
