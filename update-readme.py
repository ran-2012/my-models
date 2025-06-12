import os
import glob
import re

pre = '''

## List

'''

def updateReadme():
    print("Updating README.md...")
    
    # Get the repo root directory
    repo_root = os.path.dirname(os.path.abspath(__file__))
    
    # Dictionary to store folders with .blend files
    blend_folders = {}
    
    # Walk through all directories recursively
    for root, dirs, files in os.walk(repo_root):
        # Skip the .git directory if it exists
        if '.git' in dirs:
            dirs.remove('.git')
        
        # Check if there are any .blend files in the current directory
        blend_files = [f for f in files if f.endswith('.blend')]
        if blend_files:
            # Get relative path to the repo root
            rel_path = os.path.relpath(root, repo_root)
            if rel_path == '.':
                folder_name = os.path.basename(repo_root)
            else:
                folder_name = os.path.basename(root)
            
            # Store information about this folder
            blend_folders[rel_path] = {
                'name': folder_name,
                'blend_files': blend_files,
                # 'images': [f for f in files if f.lower().endswith(('.png', '.jpg', '.jpeg', '.gif'))]
                'images': [],
            }
    
    # Generate the README content
    readme_content = pre
    
    # Add sections for each folder with .blend files
    for rel_path, folder_info in sorted(blend_folders.items()):
        readme_content += f"### {folder_info['name']}\n\n"
        
        # Add links to blend files
        for blend_file in sorted(folder_info['blend_files']):
            file_path = os.path.join(rel_path, blend_file).replace('\\', '/')
            readme_content += f"- [{blend_file}]({file_path})\n"
        
        # Add images with adjusted size
        if folder_info['images']:
            readme_content += "\n"
            for image in sorted(folder_info['images']):
                image_path = os.path.join(rel_path, image).replace('\\', '/')
                readme_content += f"<img src=\"{image_path}\" alt=\"{image}\" height=\"200\">\n"
        
        readme_content += "\n"
    
    # Write the updated content to README.md
    with open(os.path.join(repo_root, 'readme.md'), 'w', encoding='utf-8') as f:
        f.write(readme_content)
    
    print("README.md updated successfully!")

if __name__ == "__main__":
    updateReadme()