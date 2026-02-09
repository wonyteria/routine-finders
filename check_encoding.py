
import os

def check_utf8(directory):
    for root, dirs, files in os.walk(directory):
        if '.git' in dirs:
            dirs.remove('.git')
        if 'node_modules' in dirs:
            dirs.remove('node_modules')
        if 'tmp' in dirs:
            dirs.remove('tmp')
        if 'vendor' in dirs:
            dirs.remove('vendor')
            
        for file in files:
            if file.endswith(('.rb', '.erb', '.html', '.css', '.js')):
                path = os.path.join(root, file)
                try:
                    with open(path, 'rb') as f:
                        content = f.read()
                    content.decode('utf-8')
                except UnicodeDecodeError as e:
                    print(f"INVALID UTF-8: {path} - {e}")

if __name__ == "__main__":
    check_utf8('e:\\Aintigravity\\routine-finders')
