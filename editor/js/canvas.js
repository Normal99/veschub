/**
 * VescHub Editor - Canvas Module
 * Canvas management with fabric.js for widget manipulation
 */

const Canvas = {
    canvas: null,
    gridSize: 10,
    snapToGrid: true,
    showGrid: false,
    zoom: 1.0,
    minZoom: 0.1,
    maxZoom: 5.0,
    history: [],
    historyIndex: -1,
    maxHistory: 50,
    clipboardData: null,
    isPanning: false,
    panStartPoint: null,

    /**
     * Initialize fabric canvas
     */
    init: (canvasElement) => {
        // Fix fabric.js textBaseline warnings
        if (fabric.Text) {
            fabric.Text.prototype.textBaseline = 'alphabetic';
        }
        
        Canvas.canvas = new fabric.Canvas(canvasElement, {
            width: 800,
            height: 480,
            backgroundColor: '#000000',
            selection: true,
            preserveObjectStacking: true
        });

        // Setup event listeners
        Canvas.setupEventListeners();

        // Setup grid
        Canvas.drawGrid();

        // Initialize history
        Canvas.saveState();

        console.log('Canvas initialized');
        return Canvas.canvas;
    },

    /**
     * Setup canvas event listeners
     */
    setupEventListeners: () => {
        // Object modification events
        Canvas.canvas.on('object:modified', (e) => {
            Canvas.saveState();
            if (window.App) {
                App.markDirty();
            }
        });

        Canvas.canvas.on('object:added', (e) => {
            if (!Canvas._loadingState) {
                Canvas.saveState();
                if (window.App) {
                    App.markDirty();
                }
            }
        });

        Canvas.canvas.on('object:removed', (e) => {
            if (!Canvas._loadingState) {
                Canvas.saveState();
                if (window.App) {
                    App.markDirty();
                }
            }
        });

        // Selection events
        Canvas.canvas.on('selection:created', (e) => {
            const selected = Array.isArray(e.selected) ? e.selected : [];
            console.log('selection:created event', selected, selected.map(o => ({
                type: o.type,
                isGrid: o.isGrid,
                hasWidgetData: !!o.widgetData
            })));
            Canvas.updatePropertiesPanel();
        });

        Canvas.canvas.on('selection:updated', (e) => {
            console.log('selection:updated event', e.selected);
            Canvas.updatePropertiesPanel();
        });

        Canvas.canvas.on('selection:cleared', (e) => {
            console.log('selection:cleared event');
            Canvas.updatePropertiesPanel();
        });

        // Mouse events for panning
        Canvas.canvas.on('mouse:down', (e) => {
            if (e.e.button === 1 || (e.e.button === 0 && e.e.ctrlKey)) { // Middle mouse or Ctrl+Left
                Canvas.isPanning = true;
                Canvas.panStartPoint = { x: e.e.clientX, y: e.e.clientY };
                Canvas.canvas.selection = false;
                e.e.preventDefault();
            }
        });

        Canvas.canvas.on('mouse:move', (e) => {
            if (Canvas.isPanning && Canvas.panStartPoint) {
                const deltaX = e.e.clientX - Canvas.panStartPoint.x;
                const deltaY = e.e.clientY - Canvas.panStartPoint.y;
                
                const vpt = Canvas.canvas.viewportTransform;
                vpt[4] += deltaX;
                vpt[5] += deltaY;
                
                Canvas.canvas.requestRenderAll();
                Canvas.panStartPoint = { x: e.e.clientX, y: e.e.clientY };
            }
        });

        Canvas.canvas.on('mouse:up', (e) => {
            if (Canvas.isPanning) {
                Canvas.isPanning = false;
                Canvas.panStartPoint = null;
                Canvas.canvas.selection = true;
            }
        });

        // Mouse wheel for zoom
        Canvas.canvas.on('mouse:wheel', (opt) => {
            const delta = opt.e.deltaY;
            let zoom = Canvas.canvas.getZoom();
            zoom *= 0.999 ** delta;
            zoom = Utils.clamp(zoom, Canvas.minZoom, Canvas.maxZoom);
            
            Canvas.canvas.zoomToPoint({ x: opt.e.offsetX, y: opt.e.offsetY }, zoom);
            Canvas.zoom = zoom;
            
            opt.e.preventDefault();
            opt.e.stopPropagation();
            
            Canvas.updateZoomDisplay();
        });

        // Context menu
        Canvas.canvas.wrapperEl.addEventListener('contextmenu', (e) => {
            e.preventDefault();
            Canvas.showContextMenu(e.clientX, e.clientY);
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            Canvas.handleKeyDown(e);
        });
    },

    /**
     * Draw grid on canvas
     */
    drawGrid: () => {
        if (!Canvas.canvas) return;

        // Remove old grid first
        Canvas.canvas.getObjects().forEach(obj => {
            if (obj.isGrid) {
                Canvas.canvas.remove(obj);
            }
        });

        // Only draw if grid is enabled
        if (!Canvas.showGrid) {
            Canvas.canvas.requestRenderAll();
            return;
        }

        const grid = Canvas.gridSize;
        const width = Canvas.canvas.width;
        const height = Canvas.canvas.height;

        // Draw vertical grid lines
        for (let i = 0; i <= width / grid; i++) {
            const line = new fabric.Line(
                [i * grid, 0, i * grid, height],
                {
                    stroke: '#1a1a1a',
                    strokeWidth: 1,
                    selectable: false,
                    evented: false,
                    isGrid: true
                }
            );
            Canvas.canvas.add(line);
            Canvas.canvas.sendToBack(line);
        }

        // Draw horizontal grid lines
        for (let i = 0; i <= height / grid; i++) {
            const line = new fabric.Line(
                [0, i * grid, width, i * grid],
                {
                    stroke: '#1a1a1a',
                    strokeWidth: 1,
                    selectable: false,
                    evented: false,
                    isGrid: true
                }
            );
            Canvas.canvas.add(line);
            Canvas.canvas.sendToBack(line);
        }

        Canvas.canvas.requestRenderAll();
    },

    /**
     * Toggle grid visibility
     */
    toggleGrid: () => {
        Canvas.showGrid = !Canvas.showGrid;
        Canvas.drawGrid();
        
        // Update button state
        const gridBtn = document.getElementById('btn-grid');
        if (gridBtn) {
            if (Canvas.showGrid) {
                gridBtn.classList.add('active');
            } else {
                gridBtn.classList.remove('active');
            }
        }
        
        Utils.notify(`Grid ${Canvas.showGrid ? 'enabled' : 'disabled'}`, 'info');
    },

    /**
     * Add widget to canvas
     */
    addWidget: (widgetType, x = null, y = null) => {
        const widget = Utils.getDefaultWidgetProperties(widgetType);
        
        if (x !== null && y !== null) {
            widget.x = Canvas.snapToGrid ? Utils.snapToGrid(x, Canvas.gridSize) : x;
            widget.y = Canvas.snapToGrid ? Utils.snapToGrid(y, Canvas.gridSize) : y;
        }

        const fabricObject = Widgets.renderWidget(widget, Canvas.canvas);
        
        if (fabricObject) {
            Canvas.canvas.setActiveObject(fabricObject);
            Canvas.canvas.requestRenderAll();
            Utils.notify(`${widgetType} widget added`, 'success');
        }

        return widget;
    },

    /**
     * Remove selected widgets
     */
    removeSelected: () => {
        const activeObjects = Canvas.canvas.getActiveObjects();
        if (activeObjects.length === 0) {
            Utils.notify('No widgets selected', 'info');
            return;
        }

        if (Utils.confirm(`Delete ${activeObjects.length} widget(s)?`)) {
            activeObjects.forEach(obj => {
                Canvas.canvas.remove(obj);
            });
            Canvas.canvas.discardActiveObject();
            Canvas.canvas.requestRenderAll();
            Utils.notify(`${activeObjects.length} widget(s) deleted`, 'success');
        }
    },

    /**
     * Copy selected widgets
     */
    copy: () => {
        const activeObjects = Canvas.canvas.getActiveObjects();
        if (activeObjects.length === 0) {
            Utils.notify('No widgets selected', 'info');
            return;
        }

        Canvas.clipboardData = activeObjects.map(obj => {
            return Utils.deepClone(obj.widgetData);
        });

        Utils.notify(`${Canvas.clipboardData.length} widget(s) copied`, 'success');
    },

    /**
     * Paste widgets from clipboard
     */
    paste: () => {
        if (!Canvas.clipboardData || Canvas.clipboardData.length === 0) {
            Utils.notify('Nothing to paste', 'info');
            return;
        }

        Canvas.canvas.discardActiveObject();
        const newObjects = [];

        Canvas.clipboardData.forEach(widget => {
            const newWidget = Utils.deepClone(widget);
            newWidget.id = Utils.generateId('widget');
            newWidget.x += 20;
            newWidget.y += 20;

            const fabricObject = Widgets.renderWidget(newWidget, Canvas.canvas);
            if (fabricObject) {
                newObjects.push(fabricObject);
            }
        });

        if (newObjects.length > 0) {
            const selection = new fabric.ActiveSelection(newObjects, {
                canvas: Canvas.canvas
            });
            Canvas.canvas.setActiveObject(selection);
            Canvas.canvas.requestRenderAll();
            Utils.notify(`${newObjects.length} widget(s) pasted`, 'success');
        }
    },

    /**
     * Duplicate selected widgets
     */
    duplicate: () => {
        Canvas.copy();
        Canvas.paste();
    },

    /**
     * Align selected widgets
     */
    align: (alignment) => {
        const activeObjects = Canvas.canvas.getActiveObjects();
        if (activeObjects.length < 2) {
            Utils.notify('Select at least 2 widgets to align', 'info');
            return;
        }

        const bounds = {
            left: Math.min(...activeObjects.map(obj => obj.left)),
            top: Math.min(...activeObjects.map(obj => obj.top)),
            right: Math.max(...activeObjects.map(obj => obj.left + obj.width * obj.scaleX)),
            bottom: Math.max(...activeObjects.map(obj => obj.top + obj.height * obj.scaleY))
        };

        activeObjects.forEach(obj => {
            switch (alignment) {
                case 'left':
                    obj.set({ left: bounds.left });
                    break;
                case 'center':
                    obj.set({ left: bounds.left + (bounds.right - bounds.left) / 2 - (obj.width * obj.scaleX) / 2 });
                    break;
                case 'right':
                    obj.set({ left: bounds.right - obj.width * obj.scaleX });
                    break;
                case 'top':
                    obj.set({ top: bounds.top });
                    break;
                case 'middle':
                    obj.set({ top: bounds.top + (bounds.bottom - bounds.top) / 2 - (obj.height * obj.scaleY) / 2 });
                    break;
                case 'bottom':
                    obj.set({ top: bounds.bottom - obj.height * obj.scaleY });
                    break;
            }
            obj.setCoords();
        });

        Canvas.canvas.requestRenderAll();
        Utils.notify(`Widgets aligned to ${alignment}`, 'success');
    },

    /**
     * Distribute selected widgets
     */
    distribute: (direction) => {
        const activeObjects = Canvas.canvas.getActiveObjects();
        if (activeObjects.length < 3) {
            Utils.notify('Select at least 3 widgets to distribute', 'info');
            return;
        }

        if (direction === 'horizontal') {
            activeObjects.sort((a, b) => a.left - b.left);
            const first = activeObjects[0];
            const last = activeObjects[activeObjects.length - 1];
            const totalWidth = last.left - first.left;
            const spacing = totalWidth / (activeObjects.length - 1);

            activeObjects.forEach((obj, i) => {
                obj.set({ left: first.left + spacing * i });
                obj.setCoords();
            });
        } else {
            activeObjects.sort((a, b) => a.top - b.top);
            const first = activeObjects[0];
            const last = activeObjects[activeObjects.length - 1];
            const totalHeight = last.top - first.top;
            const spacing = totalHeight / (activeObjects.length - 1);

            activeObjects.forEach((obj, i) => {
                obj.set({ top: first.top + spacing * i });
                obj.setCoords();
            });
        }

        Canvas.canvas.requestRenderAll();
        Utils.notify(`Widgets distributed ${direction}ly`, 'success');
    },

    /**
     * Z-order operations
     */
    bringToFront: () => {
        const activeObjects = Canvas.canvas.getActiveObjects();
        activeObjects.forEach(obj => {
            Canvas.canvas.bringToFront(obj);
        });
        Canvas.canvas.requestRenderAll();
    },

    sendToBack: () => {
        const activeObjects = Canvas.canvas.getActiveObjects();
        activeObjects.forEach(obj => {
            Canvas.canvas.sendToBack(obj);
        });
        Canvas.canvas.requestRenderAll();
    },

    bringForward: () => {
        const activeObjects = Canvas.canvas.getActiveObjects();
        activeObjects.forEach(obj => {
            Canvas.canvas.bringForward(obj);
        });
        Canvas.canvas.requestRenderAll();
    },

    sendBackward: () => {
        const activeObjects = Canvas.canvas.getActiveObjects();
        activeObjects.forEach(obj => {
            Canvas.canvas.sendBackward(obj);
        });
        Canvas.canvas.requestRenderAll();
    },

    /**
     * Zoom controls
     */
    setZoom: (zoom) => {
        zoom = Utils.clamp(zoom, Canvas.minZoom, Canvas.maxZoom);
        Canvas.canvas.setZoom(zoom);
        Canvas.zoom = zoom;
        Canvas.canvas.requestRenderAll();
        Canvas.updateZoomDisplay();
    },

    zoomIn: () => {
        Canvas.setZoom(Canvas.zoom * 1.2);
    },

    zoomOut: () => {
        Canvas.setZoom(Canvas.zoom / 1.2);
    },

    zoomToFit: () => {
        Canvas.setZoom(1.0);
        Canvas.canvas.viewportTransform = [1, 0, 0, 1, 0, 0];
        Canvas.canvas.requestRenderAll();
    },

    updateZoomDisplay: () => {
        const zoomPercent = Math.round(Canvas.zoom * 100);
        const zoomDisplay = document.getElementById('zoom-display');
        if (zoomDisplay) {
            zoomDisplay.textContent = `${zoomPercent}%`;
        }
    },

    /**
     * Toggle snap to grid
     */
    toggleSnapToGrid: () => {
        Canvas.snapToGrid = !Canvas.snapToGrid;
        Utils.notify(`Snap to grid ${Canvas.snapToGrid ? 'enabled' : 'disabled'}`, 'info');
    },

    /**
     * Context menu
     */
    showContextMenu: (x, y) => {
        const contextMenu = document.getElementById('context-menu');
        if (!contextMenu) return;

        const activeObjects = Canvas.canvas.getActiveObjects();
        
        contextMenu.innerHTML = `
            <div class="context-menu-item" onclick="Canvas.copy()">Copy</div>
            <div class="context-menu-item" onclick="Canvas.paste()">Paste</div>
            <div class="context-menu-item" onclick="Canvas.duplicate()">Duplicate</div>
            <hr>
            <div class="context-menu-item" onclick="Canvas.bringToFront()">Bring to Front</div>
            <div class="context-menu-item" onclick="Canvas.sendToBack()">Send to Back</div>
            <hr>
            <div class="context-menu-item" onclick="Canvas.removeSelected()">Delete</div>
        `;

        contextMenu.style.left = x + 'px';
        contextMenu.style.top = y + 'px';
        contextMenu.style.display = 'block';

        // Close menu on click outside
        const closeMenu = (e) => {
            contextMenu.style.display = 'none';
            document.removeEventListener('click', closeMenu);
        };
        setTimeout(() => {
            document.addEventListener('click', closeMenu);
        }, 100);
    },

    /**
     * Keyboard shortcuts
     */
    handleKeyDown: (e) => {
        // Don't handle shortcuts if typing in input
        if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
            return;
        }

        const ctrl = e.ctrlKey || e.metaKey;

        if (ctrl && e.key === 'z') {
            e.preventDefault();
            Canvas.undo();
        } else if (ctrl && e.key === 'y') {
            e.preventDefault();
            Canvas.redo();
        } else if (ctrl && e.key === 'c') {
            e.preventDefault();
            Canvas.copy();
        } else if (ctrl && e.key === 'v') {
            e.preventDefault();
            Canvas.paste();
        } else if (ctrl && e.key === 'd') {
            e.preventDefault();
            Canvas.duplicate();
        } else if (e.key === 'Delete' || e.key === 'Backspace') {
            e.preventDefault();
            Canvas.removeSelected();
        } else if (e.key === 'Escape') {
            Canvas.canvas.discardActiveObject();
            Canvas.canvas.requestRenderAll();
        }
    },

    /**
     * History management
     */
    saveState: () => {
        if (Canvas._loadingState) return;

        const state = Canvas.getState();
        
        // Remove future states if we're in the middle of history
        Canvas.history = Canvas.history.slice(0, Canvas.historyIndex + 1);
        
        // Add new state
        Canvas.history.push(state);
        
        // Limit history size
        if (Canvas.history.length > Canvas.maxHistory) {
            Canvas.history.shift();
        } else {
            Canvas.historyIndex++;
        }
    },

    getState: () => {
        const objects = Canvas.canvas.getObjects().filter(obj => !obj.isGrid);
        return JSON.stringify(objects.map(obj => obj.widgetData));
    },

    loadState: (state) => {
        Canvas._loadingState = true;

        // Clear canvas except grid
        const objects = Canvas.canvas.getObjects().filter(obj => !obj.isGrid);
        objects.forEach(obj => Canvas.canvas.remove(obj));

        // Load widgets
        const widgets = JSON.parse(state);
        widgets.forEach(widget => {
            Widgets.renderWidget(widget, Canvas.canvas);
        });

        Canvas.canvas.requestRenderAll();
        Canvas._loadingState = false;
    },

    undo: () => {
        if (Canvas.historyIndex > 0) {
            Canvas.historyIndex--;
            Canvas.loadState(Canvas.history[Canvas.historyIndex]);
            Utils.notify('Undo', 'info');
        } else {
            Utils.notify('Nothing to undo', 'info');
        }
    },

    redo: () => {
        if (Canvas.historyIndex < Canvas.history.length - 1) {
            Canvas.historyIndex++;
            Canvas.loadState(Canvas.history[Canvas.historyIndex]);
            Utils.notify('Redo', 'info');
        } else {
            Utils.notify('Nothing to redo', 'info');
        }
    },

    /**
     * Clear canvas
     */
    clear: () => {
        if (Utils.confirm('Clear all widgets from canvas?')) {
            const objects = Canvas.canvas.getObjects().filter(obj => !obj.isGrid);
            objects.forEach(obj => Canvas.canvas.remove(obj));
            Canvas.canvas.requestRenderAll();
            Canvas.saveState();
            Utils.notify('Canvas cleared', 'success');
        }
    },

    /**
     * Get all widgets from canvas
     */
    getAllWidgets: () => {
        return Canvas.canvas.getObjects()
            .filter(obj => !obj.isGrid && obj.widgetData)
            .map(obj => Widgets.updateWidgetFromFabric(obj));
    },

    /**
     * Load widgets onto canvas
     */
    loadWidgets: (widgets) => {
        Canvas._loadingState = true;
        
        // Clear existing widgets
        const objects = Canvas.canvas.getObjects().filter(obj => !obj.isGrid);
        objects.forEach(obj => Canvas.canvas.remove(obj));

        // Add new widgets
        widgets.forEach(widget => {
            Widgets.renderWidget(widget, Canvas.canvas);
        });

        Canvas.canvas.requestRenderAll();
        Canvas._loadingState = false;
        Canvas.saveState();
    },

    /**
     * Update properties panel based on selection
     */
    updatePropertiesPanel: () => {
        if (window.Properties && typeof Properties.updatePanel === 'function') {
            const allObjects = Canvas.canvas.getActiveObjects();
            let activeObjects = allObjects;
            if (activeObjects.length === 0) {
                const activeObject = Canvas.canvas.getActiveObject();
                if (activeObject) {
                    if (activeObject.type === 'activeSelection' && typeof activeObject.getObjects === 'function') {
                        activeObjects = activeObject.getObjects();
                    } else {
                        activeObjects = [activeObject];
                    }
                }
            }

            // Filter out grid lines and objects without widgetData
            activeObjects = activeObjects.filter(obj => !obj.isGrid && obj.widgetData);
            console.log('Updating properties panel for', activeObjects.length, 'widget objects (filtered from', allObjects.length, 'total)');
            Properties.updatePanel(activeObjects);
        }
    },

    /**
     * Resize canvas
     */
    resize: (width, height) => {
        Canvas.canvas.setWidth(width);
        Canvas.canvas.setHeight(height);
        Canvas.drawGrid();
        Canvas.canvas.requestRenderAll();
    },

    /**
     * Set canvas background color
     */
    setBackgroundColor: (color) => {
        if (!color) {
            console.warn('Invalid background color provided');
            return;
        }
        // Validate color format
        if (!Utils.isValidColor(color) && color !== 'transparent') {
            console.warn('Invalid color format:', color);
            return;
        }
        Canvas.canvas.backgroundColor = color;
        Canvas.canvas.requestRenderAll();
    }
};
