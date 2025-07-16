#!/usr/bin/env python3
"""
Script to remove all .backup files created during the image cropping process.
"""

import os
import sys

# Base directory for images
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'assets', 'images'))

# Folders to exclude (non-real estate folders)
EXCLUDE_FOLDERS = ['mogul_avatars', 'premium_avatars', 'platinum_unlocks']

def remove_backups_in_directory(directory):
    """
    Remove all .backup files in a directory.
    """
    removed_count = 0
    
    for filename in os.listdir(directory):
        if filename.lower().endswith('.backup'):
            file_path = os.path.join(directory, filename)
            try:
                os.remove(file_path)
                print(f"Removed: {file_path}")
                removed_count += 1
            except Exception as e:
                print(f"Error removing {file_path}: {str(e)}")
    
    return removed_count

def main():
    """
    Main function to remove all backup files.
    """
    total_removed = 0
    processed_folders = 0
    
    print(f"Starting backup file cleanup in: {BASE_DIR}")
    
    # Process each folder in the base directory
    for folder_name in os.listdir(BASE_DIR):
        folder_path = os.path.join(BASE_DIR, folder_name)
        
        # Skip if it's not a directory or is in the exclude list
        if not os.path.isdir(folder_path) or folder_name in EXCLUDE_FOLDERS:
            continue
        
        print(f"\nProcessing folder: {folder_name}")
        removed = remove_backups_in_directory(folder_path)
        total_removed += removed
        processed_folders += 1
        
        if removed > 0:
            print(f"Completed folder: {folder_name} - {removed} backup files removed")
        else:
            print(f"Completed folder: {folder_name} - No backup files found")
    
    print(f"\nCleanup complete!")
    print(f"Processed {processed_folders} folders")
    print(f"Removed {total_removed} backup files")

if __name__ == "__main__":
    main()
