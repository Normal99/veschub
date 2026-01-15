/**
 * VescHub Editor - Utility Functions
 * Common helper functions used throughout the editor
 */

const Utils = {
    /**
     * Generate a unique ID for widgets and screens
     */
    generateId: (prefix = 'widget') => {
        return `${prefix}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    },

    /**
     * Deep clone an object
     */
    deepClone: (obj) => {
        return JSON.parse(JSON.stringify(obj));
    },

    /**
     * Clamp a value between min and max
     */
    clamp: (value, min, max) => {
        return Math.min(Math.max(value, min), max);
    },

    /**
     * Snap value to grid
     */
    snapToGrid: (value, gridSize = 10) => {
        return Math.round(value / gridSize) * gridSize;
    },

    /**
     * Format color to hex
     */
    formatColor: (color) => {
        // Ensure color is in #RRGGBB format
        if (color.startsWith('#')) {
            return color.toUpperCase();
        }
        return `#${color}`.toUpperCase();
    },

    /**
     * Validate hex color
     */
    isValidColor: (color) => {
        return /^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{8})$/.test(color);
    },

    /**
     * Download a file
     */
    downloadFile: (filename, content, mimeType = 'application/json') => {
        const blob = new Blob([content], { type: mimeType });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    },

    /**
     * Load a file
     */
    loadFile: (callback, accept = '.json') => {
        const input = document.createElement('input');
        input.type = 'file';
        input.accept = accept;
        input.onchange = (e) => {
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = (event) => {
                    try {
                        const content = event.target.result;
                        callback(content, file.name);
                    } catch (error) {
                        console.error('Error reading file:', error);
                        alert('Error reading file: ' + error.message);
                    }
                };
                reader.readAsText(file);
            }
        };
        input.click();
    },

    /**
     * Show notification/toast
     */
    notify: (message, type = 'info', duration = 3000) => {
        // Create toast element
        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;
        toast.textContent = message;
        toast.style.cssText = `
            position: fixed;
            bottom: 20px;
            right: 20px;
            padding: 12px 20px;
            background-color: ${type === 'error' ? '#ff3333' : type === 'success' ? '#00ff00' : '#00aaff'};
            color: ${type === 'success' || type === 'info' ? '#000' : '#fff'};
            border-radius: 6px;
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.4);
            z-index: 10000;
            font-size: 0.9rem;
            font-weight: 600;
            animation: slideIn 0.3s ease;
        `;
        
        document.body.appendChild(toast);
        
        // Remove after duration
        setTimeout(() => {
            toast.style.animation = 'slideOut 0.3s ease';
            setTimeout(() => {
                document.body.removeChild(toast);
            }, 300);
        }, duration);
    },

    /**
     * Confirm dialog
     */
    confirm: (message, callback) => {
        const result = window.confirm(message);
        if (callback) callback(result);
        return result;
    },

    /**
     * Prompt dialog
     */
    prompt: (message, defaultValue = '', callback) => {
        const result = window.prompt(message, defaultValue);
        if (callback) callback(result);
        return result;
    },

    /**
     * Debounce function
     */
    debounce: (func, wait) => {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    },

    /**
     * Throttle function
     */
    throttle: (func, limit) => {
        let inThrottle;
        return function(...args) {
            if (!inThrottle) {
                func.apply(this, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    },

    /**
     * Get current timestamp in ISO format
     */
    getCurrentTimestamp: () => {
        return new Date().toISOString();
    },

    /**
     * Format date for display
     */
    formatDate: (date) => {
        return new Date(date).toLocaleDateString() + ' ' + new Date(date).toLocaleTimeString();
    },

    /**
     * Calculate distance between two points
     */
    distance: (x1, y1, x2, y2) => {
        return Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
    },

    /**
     * Check if point is inside rectangle
     */
    isPointInRect: (px, py, rx, ry, rw, rh) => {
        return px >= rx && px <= rx + rw && py >= ry && py <= ry + rh;
    },

    /**
     * Get VESC data sources
     */
    getVESCDataSources: () => {
        return [
            { value: 'speed', label: 'Speed (km/h)', type: 'float', units: 'km/h' },
            { value: 'battery_percent', label: 'Battery Percent (%)', type: 'float', units: '%' },
            { value: 'battery_voltage', label: 'Battery Voltage (V)', type: 'float', units: 'V' },
            { value: 'battery_current', label: 'Battery Current (A)', type: 'float', units: 'A' },
            { value: 'motor_current', label: 'Motor Current (A)', type: 'float', units: 'A' },
            { value: 'motor_temp', label: 'Motor Temperature (°C)', type: 'float', units: '°C' },
            { value: 'controller_temp', label: 'Controller Temperature (°C)', type: 'float', units: '°C' },
            { value: 'duty_cycle', label: 'Duty Cycle (%)', type: 'float', units: '%' },
            { value: 'rpm', label: 'RPM', type: 'float', units: 'RPM' },
            { value: 'amp_hours_used', label: 'Amp Hours Used (Ah)', type: 'float', units: 'Ah' },
            { value: 'amp_hours_charged', label: 'Amp Hours Charged (Ah)', type: 'float', units: 'Ah' },
            { value: 'watt_hours_used', label: 'Watt Hours Used (Wh)', type: 'float', units: 'Wh' },
            { value: 'watt_hours_charged', label: 'Watt Hours Charged (Wh)', type: 'float', units: 'Wh' },
            { value: 'odometer', label: 'Odometer (km)', type: 'float', units: 'km' },
            { value: 'trip_distance', label: 'Trip Distance (km)', type: 'float', units: 'km' },
            { value: 'fault_code', label: 'Fault Code', type: 'string', units: '' }
        ];
    },

    /**
     * Get default widget properties based on type
     */
    getDefaultWidgetProperties: (type) => {
        const common = {
            id: Utils.generateId('widget'),
            type: type,
            x: 50,
            y: 50,
            width: 200,
            height: 100,
            rotation: 0,
            opacity: 1.0,
            visible: true,
            zIndex: 0
        };

        const defaults = {
            text: {
                ...common,
                text: 'Text Widget',
                fontSize: 24,
                fontFamily: 'Roboto',
                fontWeight: 'normal',
                fontStyle: 'normal',
                textAlign: 'center',
                color: '#FFFFFF',
                backgroundColor: 'transparent',
                dataSource: '',
                suffix: '',
                prefix: '',
                decimals: 0
            },
            button: {
                ...common,
                width: 100,
                height: 100,
                imageUnpressed: '',
                imagePressed: '',
                action: {
                    type: 'switchScreen',
                    target: ''
                },
                hapticFeedback: true
            },
            gauge: {
                ...common,
                width: 200,
                height: 200,
                gaugeType: 'circular',
                minValue: 0,
                maxValue: 100,
                dataSource: '',
                units: '',
                needleColor: '#00FF00',
                backgroundColor: 'transparent',
                showTicks: true,
                tickCount: 10,
                zones: []
            },
            graph: {
                ...common,
                width: 300,
                height: 150,
                graphType: 'line',
                timeWindow: 30,
                backgroundColor: '#1A1A1A',
                gridColor: '#2A2A2A',
                showGrid: true,
                autoScale: true,
                dataSeries: []
            },
            progressbar: {
                ...common,
                width: 250,
                height: 40,
                orientation: 'horizontal',
                minValue: 0,
                maxValue: 100,
                fillColor: '#00FF00',
                backgroundColor: '#2A2A2A',
                dataSource: '',
                showValue: false
            },
            image: {
                ...common,
                imagePath: '',
                fitMode: 'contain'
            },
            shape: {
                ...common,
                shapeType: 'rectangle',
                fillColor: '#FFFFFF',
                strokeColor: '#FFFFFF',
                strokeWidth: 1
            },
            indicator: {
                ...common,
                width: 40,
                height: 40,
                onColor: '#00FF00',
                offColor: '#2A2A2A',
                dataSource: '',
                threshold: 0.5,
                blinkWhenOn: false
            },
            speedometer: {
                ...common,
                width: 250,
                height: 250,
                minValue: 0,
                maxValue: 120,
                units: 'km/h',
                dataSource: 'speed',
                needleColor: '#00FFFF',
                showDigitalDisplay: true,
                digitalFontSize: 48
            }
        };

        return defaults[type] || common;
    },

    /**
     * Validate widget against schema
     */
    validateWidget: (widget) => {
        // Basic validation
        if (!widget.id || !widget.type) {
            return { valid: false, errors: ['Widget must have id and type'] };
        }
        if (typeof widget.x !== 'number' || typeof widget.y !== 'number') {
            return { valid: false, errors: ['Widget must have numeric x and y coordinates'] };
        }
        if (typeof widget.width !== 'number' || typeof widget.height !== 'number') {
            return { valid: false, errors: ['Widget must have numeric width and height'] };
        }
        return { valid: true, errors: [] };
    },

    /**
     * Get widget type icon
     */
    getWidgetIcon: (type) => {
        const icons = {
            text: '📝',
            button: '🔘',
            gauge: '⏱️',
            graph: '📈',
            progressbar: '📊',
            image: '🖼️',
            shape: '⬜',
            indicator: '💡',
            speedometer: '🚗'
        };
        return icons[type] || '❓';
    }
};

// Add CSS animation for toasts if not exists
if (!document.getElementById('toast-animations')) {
    const style = document.createElement('style');
    style.id = 'toast-animations';
    style.textContent = `
        @keyframes slideIn {
            from {
                transform: translateX(400px);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
        @keyframes slideOut {
            from {
                transform: translateX(0);
                opacity: 1;
            }
            to {
                transform: translateX(400px);
                opacity: 0;
            }
        }
    `;
    document.head.appendChild(style);
}
