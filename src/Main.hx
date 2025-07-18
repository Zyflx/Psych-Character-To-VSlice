package;

import haxe.Json;
import haxe.io.Path;
import sys.io.File;

using StringTools;

/**
 * Abstract which denotes the different conversion modes available.
 */
enum abstract ConvertMode(String) from String to String {
    var PSYCH_TO_VSLICE = 'PSYCH_TO_VSLICE';
    var VSLICE_TO_PSYCH = 'VSLICE_TO_PSYCH';
}

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
        final convertMode: ConvertMode = awaitInput('Convert Mode:');

        switch(convertMode) {
            case ConvertMode.PSYCH_TO_VSLICE:
                psychToVSlice(args);
            case ConvertMode.VSLICE_TO_PSYCH:
                vsliceToPsych(args);
            case _:
                closeWithMessage('No Conversion Method Specified. Closing...', 2, FALIURE);
        }

        closeWithMessage('Character Successfully Converted!');
    }

    /**
     * Converts a Psych Engine character JSON to a V-Slice compatible character JSON.
     * @param args List of arguments that were passed in (if any).
     */
    private static function psychToVSlice(args: Array<String>):Void {
        var fileName: String = args.length == 0 ? awaitInput('Psych Character JSON:') : args[0].trim();

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
            'version' => '1.0.1',
            'name' => characterName,
            'renderType' => 'sparrow',
            'assetPath' => characterImage,
            'scale' => psychJSON.scale ?? 1.0,
            'healthIcon' => {
                'id': psychJSON.healthicon ?? 'face',
                'isPixel': psychJSON.no_antialiasing ?? false
            },
            'offsets' => psychJSON.position ?? [0, 0],
            'cameraOffsets' => psychJSON.camera_position ?? [0, 0],
            'isPixel' => psychJSON.no_antialiasing ?? false,
            'danceEvery' => 2,
            'singTime' => psychJSON.sing_duration ?? 8.0, // V-Slice's default sing time is 8.
            'startingAnimation' => 'idle',
            'animations' => [],
            'flipX' => psychJSON.flip_x ?? false
        ];

        for(animation in cast(psychJSON.animations, Array<Dynamic>)) {
            var anim: String = animation.anim;
            if(anim.endsWith('-loop')) anim = anim.replace('-loop', '-hold');

            vsliceJSON.get('animations').push({
                name: anim,
                prefix: animation.name,
                offsets: animation.offsets,
                looped: animation.loop ?? false,
                frameRate: animation.fps ?? 24,
                frameIndices: animation.indices ?? []
            });

            if(anim.startsWith('dance') && vsliceJSON.get('startingAnimation') == 'idle')
                vsliceJSON.set('startingAnimation', 'danceRight');
        }

        // assumes character is a gf-like character.
        if(vsliceJSON.get('startingAnimation') == 'danceRight')
            vsliceJSON.set('danceEvery', 1);

        final fileContent: String = Json.stringify(vsliceJSON, null, '\t');
        File.saveContent('${Path.withoutExtension(fileName)} (converted).json', fileContent);
    }

    /**
     * Converts a V-Slice character JSON to a Psych Engine compatible character JSON.
     * @param args 
     */
    private static function vsliceToPsych(args: Array<String>):Void {
        var fileName: String = args.length == 0 ? awaitInput('V-Slice Character JSON:') : args[0].trim();

        if(Path.extension(fileName) == '')
            fileName += '.json';

        var vsliceJSON: Dynamic = null;

        try {
            vsliceJSON = Json.parse(File.getContent(fileName));
        } catch(e: haxe.Exception) {
            closeWithMessage('ERROR: Invalid JSON Data.', 2, FALIURE);
        }

        final psychJSON: Map<String, Dynamic> = [
            'animations' => [],
            'no_antialiasing' => vsliceJSON.isPixel ?? false,
            'image' => vsliceJSON.assetPath,
            'position' => vsliceJSON.offsets ?? [0, 0], 
            'healthicon' => vsliceJSON.healthIcon != null ? vsliceJSON.healthIcon.id : 'face',
            'flip_x' => vsliceJSON.flipX ?? false,
            'healthbar_colors' => [255, 0, 0],
            'camera_position' => vsliceJSON.cameraOffsets ?? [0, 0],
            'sing_duration' => vsliceJSON.singTime ?? 6.1, // Psych Engine's default sing time is 6.1, similar to legacy base game and other legacy based engines.
            'scale' => vsliceJSON.scale ?? 1.0
        ];

        final images: Array<String> = [];

        for(animation in cast(vsliceJSON.animations, Array<Dynamic>)) {
            var anim: String = animation.name;
            if(anim.endsWith('-hold')) anim = anim.replace('-hold', '-loop');

            psychJSON.get('animations').push({
                offsets: animation.offsets,
                loop: animation.looped ?? false,
                anim: anim,
                name: animation.prefix,
                fps: animation.frameRate ?? 24,
                indices: animation.frameIndices ?? []
            });

            if(animation.assetPath != null)
                images.push(animation.assetPath);
        }

        for(i in 0...images.length) {
            // Skip duplicate names
            if((psychJSON.get('image') + '').contains(images[i])) continue;
            psychJSON.set('image', psychJSON.get('image') + ((i != images.length - 1) ? ',' : '') + '${images[i]}');
        }

        final fileContent: String = Json.stringify(psychJSON, null, '\t');
        File.saveContent('${Path.withoutExtension(fileName)} (converted).json', fileContent);
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