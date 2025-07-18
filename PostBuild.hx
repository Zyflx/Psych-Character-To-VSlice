package;

import sys.FileSystem;

class PostBuild {
    public static function main():Void {
        if(!FileSystem.exists('output/bin')) FileSystem.createDirectory('output/bin');
        FileSystem.rename('output/PsychCharToVSlice.exe', 'output/bin/PsychCharToVSlice.exe');
    }
}