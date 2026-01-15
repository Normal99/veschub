/**
 * VescHub Editor - Storage Module
 * Handles localStorage operations for saving/loading dashboards
 */

const Storage = {
    STORAGE_KEY_PREFIX: 'veschub_',
    PROJECTS_KEY: 'veschub_projects',
    CURRENT_PROJECT_KEY: 'veschub_current_project',
    AUTOSAVE_KEY: 'veschub_autosave',

    /**
     * Get all saved projects
     */
    getProjects: () => {
        try {
            const projects = localStorage.getItem(Storage.PROJECTS_KEY);
            return projects ? JSON.parse(projects) : [];
        } catch (error) {
            console.error('Error loading projects:', error);
            return [];
        }
    },

    /**
     * Save project list
     */
    saveProjects: (projects) => {
        try {
            localStorage.setItem(Storage.PROJECTS_KEY, JSON.stringify(projects));
            return true;
        } catch (error) {
            console.error('Error saving projects:', error);
            Utils.notify('Error saving projects', 'error');
            return false;
        }
    },

    /**
     * Get current project
     */
    getCurrentProject: () => {
        try {
            const projectId = localStorage.getItem(Storage.CURRENT_PROJECT_KEY);
            if (!projectId) return null;
            
            const projectData = localStorage.getItem(Storage.STORAGE_KEY_PREFIX + projectId);
            return projectData ? JSON.parse(projectData) : null;
        } catch (error) {
            console.error('Error loading current project:', error);
            return null;
        }
    },

    /**
     * Save current project
     */
    saveCurrentProject: (dashboard) => {
        try {
            const projectId = dashboard.name.toLowerCase().replace(/[^a-z0-9]/g, '_') + '_' + Date.now();
            const projects = Storage.getProjects();
            
            // Check if project already exists
            const existingIndex = projects.findIndex(p => p.id === projectId || p.name === dashboard.name);
            
            const projectMeta = {
                id: existingIndex >= 0 ? projects[existingIndex].id : projectId,
                name: dashboard.name,
                description: dashboard.description || '',
                lastModified: new Date().toISOString(),
                thumbnail: null // Could generate thumbnail in future
            };
            
            if (existingIndex >= 0) {
                projects[existingIndex] = projectMeta;
            } else {
                projects.push(projectMeta);
            }
            
            // Save project data
            localStorage.setItem(Storage.STORAGE_KEY_PREFIX + projectMeta.id, JSON.stringify(dashboard));
            
            // Save project list
            Storage.saveProjects(projects);
            
            // Set as current project
            localStorage.setItem(Storage.CURRENT_PROJECT_KEY, projectMeta.id);
            
            Utils.notify('Project saved successfully', 'success');
            return true;
        } catch (error) {
            console.error('Error saving project:', error);
            
            // Check if quota exceeded
            if (error.name === 'QuotaExceededError') {
                Utils.notify('Storage quota exceeded. Please delete old projects.', 'error');
            } else {
                Utils.notify('Error saving project', 'error');
            }
            return false;
        }
    },

    /**
     * Load project by ID
     */
    loadProject: (projectId) => {
        try {
            const projectData = localStorage.getItem(Storage.STORAGE_KEY_PREFIX + projectId);
            if (!projectData) {
                Utils.notify('Project not found', 'error');
                return null;
            }
            
            localStorage.setItem(Storage.CURRENT_PROJECT_KEY, projectId);
            Utils.notify('Project loaded successfully', 'success');
            return JSON.parse(projectData);
        } catch (error) {
            console.error('Error loading project:', error);
            Utils.notify('Error loading project', 'error');
            return null;
        }
    },

    /**
     * Delete project
     */
    deleteProject: (projectId) => {
        try {
            const projects = Storage.getProjects();
            const filteredProjects = projects.filter(p => p.id !== projectId);
            
            // Remove project data
            localStorage.removeItem(Storage.STORAGE_KEY_PREFIX + projectId);
            
            // Update project list
            Storage.saveProjects(filteredProjects);
            
            // Clear current project if it was deleted
            const currentProjectId = localStorage.getItem(Storage.CURRENT_PROJECT_KEY);
            if (currentProjectId === projectId) {
                localStorage.removeItem(Storage.CURRENT_PROJECT_KEY);
            }
            
            Utils.notify('Project deleted', 'success');
            return true;
        } catch (error) {
            console.error('Error deleting project:', error);
            Utils.notify('Error deleting project', 'error');
            return false;
        }
    },

    /**
     * Auto-save current state
     */
    autoSave: (dashboard) => {
        try {
            localStorage.setItem(Storage.AUTOSAVE_KEY, JSON.stringify({
                dashboard: dashboard,
                timestamp: new Date().toISOString()
            }));
            console.log('Auto-saved at', new Date().toLocaleTimeString());
        } catch (error) {
            console.error('Auto-save failed:', error);
        }
    },

    /**
     * Get auto-saved data
     */
    getAutoSave: () => {
        try {
            const data = localStorage.getItem(Storage.AUTOSAVE_KEY);
            return data ? JSON.parse(data) : null;
        } catch (error) {
            console.error('Error loading auto-save:', error);
            return null;
        }
    },

    /**
     * Clear auto-save
     */
    clearAutoSave: () => {
        try {
            localStorage.removeItem(Storage.AUTOSAVE_KEY);
        } catch (error) {
            console.error('Error clearing auto-save:', error);
        }
    },

    /**
     * Export all data (for backup)
     */
    exportAll: () => {
        try {
            const allData = {};
            for (let i = 0; i < localStorage.length; i++) {
                const key = localStorage.key(i);
                if (key.startsWith(Storage.STORAGE_KEY_PREFIX) || key === Storage.PROJECTS_KEY) {
                    allData[key] = localStorage.getItem(key);
                }
            }
            return JSON.stringify(allData, null, 2);
        } catch (error) {
            console.error('Error exporting data:', error);
            return null;
        }
    },

    /**
     * Import all data (from backup)
     */
    importAll: (jsonString) => {
        try {
            const allData = JSON.parse(jsonString);
            Object.keys(allData).forEach(key => {
                localStorage.setItem(key, allData[key]);
            });
            Utils.notify('Data imported successfully', 'success');
            return true;
        } catch (error) {
            console.error('Error importing data:', error);
            Utils.notify('Error importing data', 'error');
            return false;
        }
    },

    /**
     * Clear all data
     */
    clearAll: () => {
        if (Utils.confirm('Are you sure you want to delete all saved projects? This cannot be undone.')) {
            try {
                const keys = [];
                for (let i = 0; i < localStorage.length; i++) {
                    const key = localStorage.key(i);
                    if (key.startsWith(Storage.STORAGE_KEY_PREFIX) || 
                        key === Storage.PROJECTS_KEY || 
                        key === Storage.CURRENT_PROJECT_KEY ||
                        key === Storage.AUTOSAVE_KEY) {
                        keys.push(key);
                    }
                }
                keys.forEach(key => localStorage.removeItem(key));
                Utils.notify('All data cleared', 'success');
                return true;
            } catch (error) {
                console.error('Error clearing data:', error);
                Utils.notify('Error clearing data', 'error');
                return false;
            }
        }
        return false;
    },

    /**
     * Get storage usage (approximate)
     */
    getStorageInfo: () => {
        try {
            let totalSize = 0;
            for (let i = 0; i < localStorage.length; i++) {
                const key = localStorage.key(i);
                if (key.startsWith(Storage.STORAGE_KEY_PREFIX)) {
                    totalSize += localStorage.getItem(key).length;
                }
            }
            
            const sizeInKB = (totalSize / 1024).toFixed(2);
            const sizeInMB = (totalSize / 1024 / 1024).toFixed(2);
            
            return {
                projectCount: Storage.getProjects().length,
                totalSize: totalSize,
                sizeInKB: sizeInKB,
                sizeInMB: sizeInMB,
                estimatedQuota: 5 * 1024 * 1024, // ~5MB typical localStorage quota
                percentUsed: ((totalSize / (5 * 1024 * 1024)) * 100).toFixed(1)
            };
        } catch (error) {
            console.error('Error getting storage info:', error);
            return null;
        }
    }
};
