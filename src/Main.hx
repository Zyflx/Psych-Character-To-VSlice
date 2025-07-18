package;

import haxe.Json;
import haxe.io.Path;
import sys.io.File;

using StringTools;

class Main {
    /**
     * Number which represents a error.
     */
    private static final FALIURE: Int = 1;

    /**
     * Number which represents a successful code run.
     */
    private static final SUCCESS: Int = 0;

    public static function main():Void {
        final args: Array<String> = Sys.args();
        var fileName: String = '';
        
        if(args.length == 0)
            fileName = awaitInput('Psych Character JSON:');

        if(Path.extension(fileName) == '')
            fileName += '.json';

        var psychJSON: Dynamic = null;

        try {
            psychJSON = Json.parse(File.getContent(fileName));
        } catch(e: haxe.Exception) {
            closeWithMessage('ERROR: Invalid JSON Data.', 2, FALIURE);
        }

        final characterName: String = awaitInput('Character Name?');
        // No multi sparrow support sorry
        // Maybe figure out how to do multi sparrow in the future?
        final characterImage: String = psychJSON.image.split(',')[0];

        final vsliceJSON: Map<String, Dynamic> = [
            'version' => '1.0.0',
            'name' => characterName,
            'renderType' => 'sparrow',
            'assetPath' => characterImage,
            'scale' => psychJSON.scale,
            'healthIcon' => {
                'id': psychJSON.healthicon,
                'isPixel': psychJSON.no_antialiasing
            },
            'offsets' => psychJSON.position,
            'cameraOffsets' => psychJSON.camera_position,
            'isPixel' => psychJSON.no_antialiasing,
            'danceEvery' => 2,
            'singTime' => psychJSON.sing_duration,
            'startingAnimation' => 'idle',
            'animations' => [],
            'flipX' => psychJSON.flip_x
        ];

        for(animation in cast(psychJSON.animations, Array<Dynamic>)) {
            final anim: String = animation.anim;

            vsliceJSON.get('animations').push({
                name: anim,
                prefix: animation.name,
                offsets: animation.offsets,
                looped: animation.loop,
                frameRate: animation.fps,
                frameIndices: animation.indices
            });

            if(anim.startsWith('dance') && vsliceJSON.get('startingAnimation') == 'idle')
                vsliceJSON.set('startingAnimation', 'danceRight');
        }

        // assumes character is a gf-like character.
        if(vsliceJSON.get('startingAnimation') == 'danceRight')
            vsliceJSON.set('danceEvery', 1);

        final fileContent: String = Json.stringify(vsliceJSON, null, '\t');
        File.saveContent('${Path.withoutExtension(fileName)} (converted).json', fileContent);

        closeWithMessage('Character Successfully Converted.');
    }

    /**
     * Awaits an input from the user.
     * @param message Message to print while input is being awaited.
     */
    private static function awaitInput(message: String):String {
        Sys.println(message);
        final input: String = Sys.stdin().readLine();
        Sys.println('');
        return input;
    }

    /**
     * Waits a speicified amount of time before closing.
     * @param waitTime The amount of time to wait.
     * @param code The exit code.
     */
    private static function waitAndClose(waitTime: Float, code: Int):Void {
        Sys.sleep(waitTime);
        Sys.exit(code);
    }

    /**
     * `waitAndClose` except it displays a message along with it.
     * @param message The message to display.
     * @param waitTime The amount of time to wait before closing.
     * @param code The exit code.
     */
    private static function closeWithMessage(message: String, waitTime: Float = 1.0, ?code: Int):Void {
        Sys.println(message);
        waitAndClose(waitTime, code ?? SUCCESS);
    }
}