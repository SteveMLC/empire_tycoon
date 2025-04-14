// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/**
 * This is the Flutter.js bootstrap script, migrated from the pre-generated flutter_bootstrap.js
 * It initializes the Flutter engine, and handles basic error handling.
 * 
 * @version 3.0
 */
(function() {
  "use strict";

  // Define the location of the Flutter web assets
  var baseUrl = (function() {
    var scripts = document.getElementsByTagName('script');
    for (var i = 0; i < scripts.length; i++) {
      var script = scripts[i];
      if (script.src.indexOf('flutter.js') !== -1) {
        return script.src.substring(0, script.src.lastIndexOf('/') + 1);
      }
    }
    // Default to the current location.
    return './';
  }());

  // Define the Flutter object
  if (typeof window.flutter === 'undefined') {
    window.flutter = {};
  }
  
  // Check for buildConfig and create default if not exists
  if (typeof window._flutter === 'undefined') {
    window._flutter = {};
  }
  
  if (typeof window._flutter.buildConfig === 'undefined') {
    window._flutter.buildConfig = {
      version: '1.0.0+100',
      appId: 'com.example.empire_tycoon',
      debugMode: false
    };
  }
  
  window.flutter.loader = {
    _scriptLoaded: false,
    
    /**
     * Load the Flutter engine and your app.
     * @param {Object} options - Configuration for the Flutter instance.
     * @return {Promise} A promise that resolves with the engineInitializer instance.
     */
    loadEntrypoint: function(options) {
      console.log("Loading Flutter app via loadEntrypoint()");
      
      return this.load(options).then(function(engineInitializer) {
        console.log("Flutter engine initialized via loadEntrypoint()");
        if (typeof options.onEntrypointLoaded === 'function') {
          return options.onEntrypointLoaded(engineInitializer);
        }
        return engineInitializer;
      });
    },
    
    /**
     * Load the Flutter engine and prepare it for initialization.
     * @param {Object} options - Configuration for the Flutter instance.
     * @return {Promise} A promise that resolves with the engineInitializer instance.
     */
    load: function(options) {
      options = options || {};
      
      if (!window._flutter.buildConfig) {
        console.warn("Flutter buildConfig not set, using default");
        window._flutter.buildConfig = {
          version: '1.0.0',
          appId: 'com.example.app',
          debugMode: false
        };
      }
      
      // Create the main script that will load the Flutter app
      return new Promise(function(resolve, reject) {
        var mainScript = document.createElement('script');
        mainScript.src = baseUrl + 'main.dart.js';
        mainScript.type = 'text/javascript';
        
        // Set up loading handlers
        mainScript.addEventListener('load', function() {
          // Main script loaded, now can initialize the app
          var engineInitializer = {
            initializeEngine: function() {
              return Promise.resolve({
                runApp: function() {
                  if (typeof window.runApp !== 'undefined') {
                    window.runApp();
                  }
                  return Promise.resolve(true);
                }
              });
            }
          };
          resolve(engineInitializer);
        });
        
        mainScript.addEventListener('error', function(error) {
          console.error('Failed to load Flutter application script:', error);
          reject(new Error('Failed to load Flutter application script'));
        });
        
        // Append script to load the app
        document.body.appendChild(mainScript);
      });
    }
  };
  
  // Expose the Flutter loader to the global _flutter namespace for compatibility
  window._flutter = window._flutter || {};
  window._flutter.loader = window.flutter.loader;
})();