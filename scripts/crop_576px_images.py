#!/usr/bin/env python3
"""
Script to crop real estate images in Empire Tycoon that are 768x576 to 768x543
by removing 33 pixels from the bottom.
"""

import os
import sys
from PIL import Image
import shutil

# Base directory for images
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'images'))

# Folders to exclude (non-real estate folders)
EXCLUDE_FOLDERS = ['mogul_avatars', 'premium_avatars', 'platinum_unlocks']

# Target dimensions
TARGET_WIDTH = 768
TARGET_HEIGHT = 576
NEW_HEIGHT = 543  # 576 - 33 = 543

def create_backup(image_path):
    """
    Create a backup of the original image.
    """
    backup_path = image_path + '.backup'
    shutil.copy2(image_path, backup_path)
    return backup_path

def crop_image(image_path):
    """
    Crop an image by removing 33 pixels from the bottom if needed.
    Only crops images with dimensions of 768x576 pixels.
    Returns: (status, message)
      status: True if cropped, False if skipped or error
      message: 'cropped', 'skipped', or error message
    """
    try:
        # Open the image
        img = Image.open(image_path)
        
        # Get original dimensions
        width, height = img.size
        
        # Only crop if the dimensions are exactly 768x576
        if width == TARGET_WIDTH and height == TARGET_HEIGHT:
            # Create backup before modifying
            backup_path = create_backup(image_path)
            print(f"  Created backup: {backup_path}")
            
            # Crop the image (remove 33 pixels from bottom)
            # Format: (left, top, right, bottom)
            cropped_img = img.crop((0, 0, width, height - 33))
            
            # Save the cropped image, overwriting the original
            cropped_img.save(image_path, quality=95)
            print(f"  Cropped from {width}x{height} to {width}x{height-33}")
            return (True, 'cropped')
        else:
            print(f"  Skipping: Dimensions {width}x{height} (not 768x576)")
            return (False, 'skipped')
    except Exception as e:
        error_msg = str(e)
        print(f"  Error processing {image_path}: {error_msg}")
        return (False, error_msg)

def process_directory(directory):
    """
    Process all jpg images in a directory.
    """
    success_count = 0
    skipped_count = 0
    error_count = 0
    
    for filename in os.listdir(directory):
        if filename.lower().endswith('.jpg') and not filename.endswith('.backup'):
            image_path = os.path.join(directory, filename)
            print(f"Processing: {image_path}")
            
            status, message = crop_image(image_path)
            if status:
                success_count += 1
            elif message == 'skipped':
                skipped_count += 1
            else:
                error_count += 1
    
    return success_count, skipped_count, error_count

def main():
    """
    Main function to process all real estate images.
    """
    total_success = 0
    total_skipped = 0
    total_error = 0
    processed_folders = 0
    
    print(f"Starting image cropping process in: {BASE_DIR}")
    print(f"Target dimensions: {TARGET_WIDTH}x{TARGET_HEIGHT} -> {TARGET_WIDTH}x{NEW_HEIGHT}")
    print(f"Only cropping images with dimensions of exactly 768x576 pixels")
    
    # Process each folder in the base directory
    for folder_name in os.listdir(BASE_DIR):
        folder_path = os.path.join(BASE_DIR, folder_name)
        
        # Skip if it's not a directory or is in the exclude list
        if not os.path.isdir(folder_path) or folder_name in EXCLUDE_FOLDERS:
            continue
        
        print(f"\nProcessing folder: {folder_name}")
        success, skipped, error = process_directory(folder_path)
        total_success += success
        total_skipped += skipped
        total_error += error
        processed_folders += 1
        
        if success > 0:
            print(f"Completed folder: {folder_name} - {success} images cropped, {skipped} skipped, {error} errors")
        else:
            print(f"Completed folder: {folder_name} - No matching images found")
    
    print(f"\nCropping complete!")
    print(f"Processed {processed_folders} folders")
    print(f"Successfully cropped {total_success} images from 768x576 to 768x543")
    print(f"Skipped {total_skipped} images (not 768x576)")
    print(f"Encountered {total_error} errors")

if __name__ == "__main__":
    main()
