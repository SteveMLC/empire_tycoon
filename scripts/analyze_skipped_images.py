#!/usr/bin/env python3
"""
Script to analyze all real estate images in Empire Tycoon and report on those
that weren't cropped by the previous script (non-768px height images).
"""

import os
import sys
from PIL import Image
import json
from datetime import datetime

# Base directory for images
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'images'))

# Folders to exclude (non-real estate folders)
EXCLUDE_FOLDERS = ['mogul_avatars', 'premium_avatars', 'platinum_unlocks']

# Target dimensions from the cropping script
TARGET_HEIGHT = 768  # Original height that was targeted for cropping

def analyze_image(image_path):
    """
    Analyze an image and return its properties.
    """
    try:
        # Open the image
        img = Image.open(image_path)
        
        # Get image properties
        width, height = img.size
        format_name = img.format
        mode = img.mode
        
        # Check if this image was skipped by the cropping script
        was_skipped = height != TARGET_HEIGHT
        
        # Get file size
        file_size = os.path.getsize(image_path)
        
        return {
            "path": image_path,
            "dimensions": f"{width}x{height}",
            "width": width,
            "height": height,
            "format": format_name,
            "mode": mode,
            "size_bytes": file_size,
            "size_kb": round(file_size / 1024, 2),
            "was_skipped": was_skipped
        }
    except Exception as e:
        return {
            "path": image_path,
            "error": str(e)
        }

def process_directory(directory):
    """
    Process all jpg images in a directory.
    """
    results = []
    
    for filename in os.listdir(directory):
        if filename.lower().endswith('.jpg') and not filename.endswith('.backup'):
            image_path = os.path.join(directory, filename)
            results.append(analyze_image(image_path))
    
    return results

def main():
    """
    Main function to analyze all real estate images.
    """
    all_results = []
    skipped_images = []
    processed_folders = 0
    
    print(f"Starting image analysis in: {BASE_DIR}")
    
    # Process each folder in the base directory
    for folder_name in os.listdir(BASE_DIR):
        folder_path = os.path.join(BASE_DIR, folder_name)
        
        # Skip if it's not a directory or is in the exclude list
        if not os.path.isdir(folder_path) or folder_name in EXCLUDE_FOLDERS:
            continue
        
        print(f"Analyzing folder: {folder_name}")
        results = process_directory(folder_path)
        all_results.extend(results)
        
        # Track skipped images
        for result in results:
            if result.get("was_skipped", False):
                skipped_images.append(result)
        
        processed_folders += 1
    
    # Generate report
    print(f"\nAnalysis complete!")
    print(f"Processed {processed_folders} folders")
    print(f"Analyzed {len(all_results)} images")
    print(f"Found {len(skipped_images)} images that were skipped by the cropping script")
    
    # Save detailed report to file
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    report_file = os.path.join(os.path.dirname(__file__), f"skipped_images_report_{timestamp}.json")
    
    with open(report_file, 'w') as f:
        json.dump({
            "timestamp": timestamp,
            "total_folders": processed_folders,
            "total_images": len(all_results),
            "skipped_images_count": len(skipped_images),
            "skipped_images": skipped_images
        }, f, indent=2)
    
    print(f"Detailed report saved to: {report_file}")
    
    # Print summary of skipped images
    print("\nSummary of skipped images:")
    print("-" * 80)
    print(f"{'Folder':<25} {'Image':<30} {'Dimensions':<15}")
    print("-" * 80)
    
    for img in skipped_images:
        path_parts = img["path"].split(os.sep)
        folder = path_parts[-2]
        image = path_parts[-1]
        print(f"{folder:<25} {image:<30} {img['dimensions']:<15}")

if __name__ == "__main__":
    main()
