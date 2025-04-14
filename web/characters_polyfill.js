/**
 * Empire Tycoon - Characters Polyfill
 * This script provides emergency polyfills for characters package classes
 * if the actual Flutter dependencies fail to load.
 * 
 * NOTE: This is a temporary fallback solution only and should not be relied upon
 * for normal operation. It provides just enough functionality to prevent crashes.
 */

(function() {
  console.log('Loading Characters polyfill as emergency fallback');
  
  // Create a namespace for the characters package
  if (typeof window.characters === 'undefined') {
    window.characters = {};
  }
  
  // Define the CharacterRange class if not already defined
  if (typeof window.CharacterRange === 'undefined') {
    console.log('Polyfilling CharacterRange class');
    
    window.CharacterRange = class CharacterRange {
      constructor(start = 0, end = 0) {
        this.start = start;
        this.end = end;
      }
      
      get length() {
        return this.end - this.start;
      }
      
      toString() {
        return `CharacterRange(${this.start}, ${this.end})`;
      }
    };
    
    // Add to the characters namespace
    window.characters.CharacterRange = window.CharacterRange;
  }
  
  // Define a simple Characters class if not already defined
  if (typeof window.Characters === 'undefined') {
    console.log('Polyfilling Characters class');
    
    window.Characters = class Characters {
      constructor(string = '') {
        this._string = string;
      }
      
      // Basic iterator for character by character iteration
      *[Symbol.iterator]() {
        for (let i = 0; i < this._string.length; i++) {
          yield this._string[i];
        }
      }
      
      get length() {
        return this._string.length;
      }
      
      // Simple method to get string representation
      toString() {
        return this._string;
      }
    };
    
    // Add to the characters namespace
    window.characters.Characters = window.Characters;
  }
  
  // Define any character utilities
  if (typeof window.CharacterUtils === 'undefined') {
    window.CharacterUtils = {
      isDigit: function(char) {
        return /^\d$/.test(char);
      },
      isLetter: function(char) {
        return /^[a-zA-Z]$/.test(char);
      },
      isWhitespace: function(char) {
        return /^\s$/.test(char);
      }
    };
    
    // Add to the characters namespace
    window.characters.utils = window.CharacterUtils;
  }
  
  console.log('Characters polyfill loaded successfully');
})();