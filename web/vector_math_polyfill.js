/**
 * Empire Tycoon - Vector Math Polyfill
 * This script provides emergency polyfills for Vector2, Vector3, Matrix4, and related classes
 * if the actual Flutter dependencies fail to load.
 * 
 * NOTE: This is a temporary fallback solution only and should not be relied upon
 * for normal operation. It provides just enough functionality to prevent crashes,
 * but not full implementation.
 */

(function() {
  console.log('Loading enhanced Vector Math polyfill as emergency fallback');

  // Force define these classes to ensure they're available
  console.log('Polyfilling Vector2 class');
  
  // Basic Vector2 implementation
  window.Vector2 = class Vector2 {
    constructor(x = 0, y = 0) {
      this.x = x;
      this.y = y;
    }
    
    clone() {
      return new Vector2(this.x, this.y);
    }
    
    add(other) {
      this.x += other.x;
      this.y += other.y;
      return this;
    }
    
    subtract(other) {
      this.x -= other.x;
      this.y -= other.y;
      return this;
    }
    
    scale(factor) {
      this.x *= factor;
      this.y *= factor;
      return this;
    }
    
    length() {
      return Math.sqrt(this.x * this.x + this.y * this.y);
    }
    
    normalize() {
      const len = this.length();
      if (len > 0) {
        this.x /= len;
        this.y /= len;
      }
      return this;
    }
    
    toString() {
      return `[${this.x}, ${this.y}]`;
    }
    
    // Required static methods
    static zero() {
      return new Vector2(0, 0);
    }
    
    static copy(other) {
      return new Vector2(other.x, other.y);
    }
  };
  
  // Vector3 implementation
  console.log('Polyfilling Vector3 class');
  window.Vector3 = class Vector3 {
    constructor(x = 0, y = 0, z = 0) {
      this.x = x;
      this.y = y;
      this.z = z;
    }
    
    clone() {
      return new Vector3(this.x, this.y, this.z);
    }
    
    length() {
      return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
    }
    
    normalize() {
      const len = this.length();
      if (len > 0) {
        this.x /= len;
        this.y /= len;
        this.z /= len;
      }
      return this;
    }
    
    add(other) {
      this.x += other.x;
      this.y += other.y;
      this.z += other.z;
      return this;
    }
    
    subtract(other) {
      this.x -= other.x;
      this.y -= other.y;
      this.z -= other.z;
      return this;
    }
    
    scale(factor) {
      this.x *= factor;
      this.y *= factor;
      this.z *= factor;
      return this;
    }
    
    toString() {
      return `[${this.x}, ${this.y}, ${this.z}]`;
    }
    
    // Required static methods
    static zero() {
      return new Vector3(0, 0, 0);
    }
    
    static copy(other) {
      return new Vector3(other.x, other.y, other.z);
    }
  };
  
  // Add Quad class required by some Flutter widgets
  console.log('Polyfilling Quad class');
  window.Quad = class Quad {
    constructor(point0, point1, point2, point3) {
      this.point0 = point0 || new Vector3(0, 0, 0);
      this.point1 = point1 || new Vector3(1, 0, 0);
      this.point2 = point2 || new Vector3(1, 1, 0);
      this.point3 = point3 || new Vector3(0, 1, 0);
    }
    
    static points(p0, p1, p2, p3) {
      return new Quad(p0, p1, p2, p3);
    }
  };
  
  console.log('Polyfilling Matrix4 class');
  
  // Enhanced Matrix4 implementation
  window.Matrix4 = class Matrix4 {
    constructor() {
      // Create identity matrix (4x4)
      this.storage = [
        1, 0, 0, 0,
        0, 1, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1
      ];
    }
    
    static identity() {
      return new Matrix4();
    }
    
    static zero() {
      const m = new Matrix4();
      for (let i = 0; i < 16; i++) {
        m.storage[i] = 0;
      }
      return m;
    }
    
    clone() {
      const result = new Matrix4();
      for (let i = 0; i < 16; i++) {
        result.storage[i] = this.storage[i];
      }
      return result;
    }
    
    translate(x, y, z = 0) {
      // Simple translation implementation
      this.storage[12] += x;
      this.storage[13] += y;
      this.storage[14] += z;
      return this;
    }
    
    scale(x, y, z = 1) {
      // Simple scaling implementation
      this.storage[0] *= x;
      this.storage[5] *= y;
      this.storage[10] *= z;
      return this;
    }
    
    rotateZ(angle) {
      // Simple Z rotation
      const c = Math.cos(angle);
      const s = Math.sin(angle);
      
      const m00 = this.storage[0];
      const m01 = this.storage[1];
      const m10 = this.storage[4];
      const m11 = this.storage[5];
      
      this.storage[0] = c * m00 - s * m10;
      this.storage[1] = c * m01 - s * m11;
      this.storage[4] = s * m00 + c * m10;
      this.storage[5] = s * m01 + c * m11;
      
      return this;
    }
    
    invert() {
      // For emergency fallback, just return this (not a true inversion)
      console.warn('Matrix4 invert not fully implemented in polyfill');
      return this;
    }
    
    transform3(vector) {
      // Basic transformation of Vector3
      const x = vector.x;
      const y = vector.y;
      const z = vector.z;
      
      // Matrix multiplication with vector
      const nx = this.storage[0] * x + this.storage[4] * y + this.storage[8] * z + this.storage[12];
      const ny = this.storage[1] * x + this.storage[5] * y + this.storage[9] * z + this.storage[13];
      const nz = this.storage[2] * x + this.storage[6] * y + this.storage[10] * z + this.storage[14];
      
      return new Vector3(nx, ny, nz);
    }
    
    toString() {
      return `[Matrix4]`;
    }
  };
  
  // Add HeapPriorityQueue class needed by the scheduler
  console.log('Polyfilling HeapPriorityQueue class');
  window.HeapPriorityQueue = class HeapPriorityQueue {
    constructor(comparator) {
      this._queue = [];
      this._comparator = comparator || ((a, b) => a - b);
    }

    add(element) {
      this._queue.push(element);
      this._queue.sort(this._comparator);
      return this;
    }

    removeFirst() {
      if (this._queue.length === 0) {
        return null;
      }
      return this._queue.shift();
    }

    get isEmpty() {
      return this._queue.length === 0;
    }

    get length() {
      return this._queue.length;
    }
  };

  // Add PriorityQueue class
  console.log('Polyfilling PriorityQueue class');
  window.PriorityQueue = window.HeapPriorityQueue;

  // Add more Matrix4 static methods
  console.log('Adding Matrix4 additional methods');
  
  // Add diagonal3Values static method to Matrix4
  window.Matrix4.diagonal3Values = function(x, y, z) {
    const m = new Matrix4();
    m.storage[0] = x;
    m.storage[5] = y;
    m.storage[10] = z;
    return m;
  };
  
  // Add diagonal3 static method to Matrix4
  window.Matrix4.diagonal3 = function(vector) {
    const m = new Matrix4();
    m.storage[0] = vector.x;
    m.storage[5] = vector.y;
    m.storage[10] = vector.z;
    return m;
  };
  
  // Add getTransformTo method
  window.Matrix4.prototype.getTransformTo = function(other) {
    // In polyfill, just return identity matrix
    console.warn('getTransformTo is a stub in polyfill');
    return Matrix4.identity();
  };
  
  // Add applyToVector3 method
  window.Matrix4.prototype.applyToVector3 = function(vector) {
    return this.transform3(vector);
  };

  // Define a global object that Flutter code might try to access
  window.vector_math_64 = {
    Vector2: window.Vector2,
    Vector3: window.Vector3,
    Matrix4: window.Matrix4,
    Quad: window.Quad,
    HeapPriorityQueue: window.HeapPriorityQueue,
    PriorityQueue: window.PriorityQueue
  };
  
  // Same for the vector_math object
  window.vector_math = {
    Vector2: window.Vector2,
    Vector3: window.Vector3,
    Matrix4: window.Matrix4,
    Quad: window.Quad,
    HeapPriorityQueue: window.HeapPriorityQueue,
    PriorityQueue: window.PriorityQueue
  };
  
  // Add to collection namespace
  window.collection = {
    HeapPriorityQueue: window.HeapPriorityQueue,
    PriorityQueue: window.PriorityQueue
  };
  
  // Add to the dart namespace if it exists
  if (window.dart) {
    window.dart.vector_math = window.vector_math;
    window.dart.vector_math_64 = window.vector_math_64;
  }
  
  console.log('Enhanced Vector Math polyfill loaded as fallback');
})();