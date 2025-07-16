#!/usr/bin/env python3
"""
Test script to crop real estate images in a single folder.
This script processes all real estate images in the specified folder, cropping them to 1024x735.
"""

import os
import sys
import shutil
from PIL import Image

# Base directory for images
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'images'))

# Test folder (rural_kenya)
TEST_FOLDER = 'rural_kenya'

# Target dimensions
TARGET_WIDTH = 1024
TARGET_HEIGHT = 735

def create_backup(image_path):
    """
    Create a backup of the original image.
    """
    backup_path = image_path + '.backup'
    shutil.copy2(image_path, backup_path)
    print(f"Created backup: {backup_path}")

def crop_image(image_path):
    """
    Crop an image by removing 33 pixels from the bottom.
    """
    try:
        # Create backup
        create_backup(image_path)
        
        # Open the image
        img = Image.open(image_path)
        
        # Get original dimensions
        width, height = img.size
        print(f"Original dimensions: {width}x{height}")
        
        # Crop the image (remove 33 pixels from bottom)
        # Format: (left, top, right, bottom)
        cropped_img = img.crop((0, 0, width, height - 33))
        
        # Get new dimensions
        new_width, new_height = cropped_img.size
        print(f"New dimensions: {new_width}x{new_height}")
        
        # Save the cropped image, overwriting the original
        cropped_img.save(image_path, quality=95)
        
        return True
    except Exception as e:
        print(f"Error processing {image_path}: {str(e)}")
        return False

def process_directory(directory):
    """
    Process all jpg images in a directory.
    """
    success_count = 0
    error_count = 0
    
    for filename in os.listdir(directory):
        if filename.lower().endswith('.jpg'):
            image_path = os.path.join(directory, filename)
            print(f"\nProcessing: {image_path}")
            
            if crop_image(image_path):
                success_count += 1
            else:
                error_count += 1
    
    return success_count, error_count

def main():
    """
    Main function to process images in the test folder.
    """
    folder_path = os.path.join(BASE_DIR, TEST_FOLDER)
    
    if not os.path.isdir(folder_path):
        print(f"Error: Test folder '{TEST_FOLDER}' not found in {BASE_DIR}")
        return
    
    print(f"Starting test crop on folder: {TEST_FOLDER}")
    print(f"Target dimensions: {TARGET_WIDTH}x{TARGET_HEIGHT}")
    
    success, error = process_directory(folder_path)
    
    print(f"\nTest cropping complete!")
    print(f"Successfully cropped {success} images")
    print(f"Encountered {error} errors")
    print(f"\nPlease check the images in {folder_path} to verify the results.")
    print("Original images have been backed up with .backup extension.")

if __name__ == "__main__":
    main()
