package isc.zlib;

import java.util.Arrays;
import java.util.zip.Deflater;

public abstract class Java {

    public static byte[] compress(String inputString) {
        byte[] output = new byte[inputString.length()*3];
        try {
            // Encode a String into bytes
            byte[] input = inputString.getBytes("UTF-8");

            // Compress the bytes

            Deflater compresser = new Deflater();
            compresser.setInput(input);
            compresser.finish();
            int compressedDataLength = compresser.deflate(output);
            compresser.end();
            output = Arrays.copyOfRange(output, 0, compressedDataLength);

        } catch (java.io.UnsupportedEncodingException ex) {
            // handle
        }


        return output;
    }
}
