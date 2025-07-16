#!/usr/bin/env python3
"""
Script to crop real estate images in Empire Tycoon by removing 33 pixels from the bottom.
This script processes all real estate images in the locale folders, cropping them to 1024x735.
"""

import os
import sys
from PIL import Image

# Base directory for images
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'images'))

# Folders to exclude (non-real estate folders)
EXCLUDE_FOLDERS = ['mogul_avatars', 'premium_avatars', 'platinum_unlocks']

# Target dimensions
TARGET_WIDTH = 1024
TARGET_HEIGHT = 735

def create_backup(image_path):
    """
    Create a backup of the original image.
    """
    import shutil
    backup_path = image_path + '.backup'
    shutil.copy2(image_path, backup_path)
    return backup_path

def crop_image(image_path):
    """
    Crop an image by removing 33 pixels from the bottom if needed.
    Only crops images with height of 768 pixels.
    Returns: (status, message)
      status: True if cropped, False if skipped or error
      message: 'cropped', 'skipped', or error message
    """
    try:
        # Open the image
        img = Image.open(image_path)
        
        # Get original dimensions
        width, height = img.size
        
        # Only crop if the height is 768 pixels
        if height == 768:
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
            print(f"  Skipping: Already at {width}x{height} (not 768px height)")
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
    print(f"Target dimensions: {TARGET_WIDTH}x{TARGET_HEIGHT}")
    print(f"Only cropping images with height of 768 pixels")
    
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
        
        print(f"Completed folder: {folder_name} - {success} images cropped, {skipped} skipped, {error} errors")
    
    print(f"\nCropping complete!")
    print(f"Processed {processed_folders} folders")
    print(f"Successfully cropped {total_success} images")
    print(f"Skipped {total_skipped} images (already at target height or other size)")
    print(f"Encountered {total_error} errors")

if __name__ == "__main__":
    main()
