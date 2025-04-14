/**
 * Empire Tycoon - Enhanced Flutter Error Handling
 * This script handles common Flutter errors, especially those related to missing dependencies.
 */

// Initialize error handling system
(function() {
  // Error tracking
  let flutterErrors = [];
  let errorWasHandled = false;
  let dependencyErrors = new Set();
  
  // References to loading UI elements for updates
  let loadingText;
  let loadingSubtext;
  let loadingContainer;
  let retryButton;
  
  // Setup error handler when document is ready
  window.addEventListener('DOMContentLoaded', function() {
    console.log('Flutter error handler initialized');
    
    // Cache UI elements
    loadingText = document.getElementById('loading-text');
    loadingSubtext = document.getElementById('loading-subtext');
    loadingContainer = document.getElementById('loading');
    
    // Set up global error handlers
    window.addEventListener('error', handleGlobalError);
    window.addEventListener('unhandledrejection', handlePromiseRejection);
  });
  
  /**
   * Main error handler for uncaught exceptions
   * @param {ErrorEvent} event - The error event
   */
  function handleGlobalError(event) {
    console.error('Global error detected:', event);
    
    const errorMsg = event.message || 'Unknown error';
    
    // Skip non-Flutter errors or errors we've already handled
    if (errorWasHandled || isNonCriticalError(errorMsg)) {
      return;
    }
    
    // Check for dependency-related errors
    if (isDependencyError(errorMsg)) {
      handleDependencyError(errorMsg);
      return;
    }
    
    // Record all Flutter errors for tracking patterns
    flutterErrors.push({
      message: errorMsg,
      timestamp: new Date().toISOString(),
      stack: event.error?.stack || 'No stack available'
    });
    
    // Let the default handler continue
    console.log('Error recorded for analysis');
  }
  
  /**
   * Handle Promise rejection events
   * @param {PromiseRejectionEvent} event - The promise rejection event
   */
  function handlePromiseRejection(event) {
    console.error('Unhandled Promise Rejection:', event.reason);
    
    const errorMsg = event.reason?.message || 'Unknown promise rejection';
    
    // Skip if already handled or non-critical
    if (errorWasHandled || isNonCriticalError(errorMsg)) {
      return;
    }
    
    // Check for dependency-related errors in promises
    if (isDependencyError(errorMsg)) {
      handleDependencyError(errorMsg);
      return;
    }
    
    // Record all Flutter-related promise rejections
    flutterErrors.push({
      message: errorMsg,
      timestamp: new Date().toISOString(),
      type: 'promise',
      stack: event.reason?.stack || 'No stack available'
    });
  }
  
  /**
   * Check if an error is related to missing Flutter dependencies
   * @param {string} errorMsg - The error message
   * @returns {boolean} True if this is a dependency error
   */
  function isDependencyError(errorMsg) {
    const dependencyErrorPatterns = [
      /Type ['"]Vector2['"] not found/i,
      /Type ['"]Matrix4['"] not found/i,
      /Error when reading.*vector_math/i,
      /Error when reading.*characters/i,
      /Error when reading.*collection/i,
      /Error when reading.*meta/i,
      /pub-cache.*not found/i
    ];
    
    return dependencyErrorPatterns.some(pattern => pattern.test(errorMsg));
  }
  
  /**
   * Handle dependency-specific errors with custom recovery
   * @param {string} errorMsg - The specific error message
   */
  function handleDependencyError(errorMsg) {
    console.log('Handling dependency error:', errorMsg);
    
    // Only track unique dependency errors
    if (!dependencyErrors.has(errorMsg)) {
      dependencyErrors.add(errorMsg);
      
      // Extract the dependency name from the error
      let dependencyName = 'Flutter dependency';
      if (errorMsg.includes('Vector2') || errorMsg.includes('Matrix4') || errorMsg.includes('vector_math')) {
        dependencyName = 'vector_math';
      } else if (errorMsg.includes('characters')) {
        dependencyName = 'characters';
      } else if (errorMsg.includes('collection')) {
        dependencyName = 'collection';
      } else if (errorMsg.includes('meta')) {
        dependencyName = 'meta';
      }
      
      console.log(`Identified dependency issue with: ${dependencyName}`);
      
      // Update the UI to show a helpful message
      updateLoadingUI('Dependency Issue Detected', 
        `The app is missing a required component (${dependencyName}).<br><br>` +
        'This can happen due to caching issues with Flutter web.<br><br>' +
        'Please try refreshing the page to fix this issue.');
      
      // Add a retry button if not already present
      addRetryButton();
      
      // Mark as handled to prevent duplicate messages
      errorWasHandled = true;
    }
  }
  
  /**
   * Some errors can be ignored as non-critical
   * @param {string} errorMsg - The error message
   * @returns {boolean} True if this is a non-critical error
   */
  function isNonCriticalError(errorMsg) {
    const nonCriticalPatterns = [
      /ResizeObserver loop limit exceeded/i,
      /ResizeObserver loop completed/i,
      /Script error/i,
      /favicon/i,
      /loading chunk/i
    ];
    
    return nonCriticalPatterns.some(pattern => pattern.test(errorMsg));
  }
  
  /**
   * Update the loading UI with custom error messages
   * @param {string} title - The error title
   * @param {string} message - The detailed error message
   */
  function updateLoadingUI(title, message) {
    if (!loadingText || !loadingSubtext || !loadingContainer) {
      console.error('Could not update loading UI - elements not found');
      return;
    }
    
    // Make sure loading screen is visible
    loadingContainer.style.display = 'flex';
    loadingContainer.style.opacity = '1';
    
    // Update text elements
    loadingText.innerText = title;
    loadingText.style.color = '#d32f2f';
    loadingSubtext.innerHTML = message;
    
    // Hide spinner if present
    const spinner = document.getElementById('loading-spinner');
    if (spinner) {
      spinner.style.display = 'none';
    }
    
    // Hide progress bar if present
    const progressBar = document.querySelector('.loading-progress');
    if (progressBar) {
      progressBar.style.display = 'none';
    }
  }
  
  /**
   * Add a retry button to the loading screen
   */
  function addRetryButton() {
    if (!loadingContainer || document.querySelector('.retry-button')) {
      return; // Container not found or button already exists
    }
    
    retryButton = document.createElement('button');
    retryButton.innerText = 'Refresh';
    retryButton.className = 'retry-button';
    retryButton.onclick = function() {
      window.location.reload();
    };
    
    loadingContainer.appendChild(retryButton);
  }
  
  // Make error handler available for manual triggering
  window.flutterErrorHandler = {
    reportError: function(errorMsg) {
      if (isDependencyError(errorMsg)) {
        handleDependencyError(errorMsg);
      }
    }
  };
})();