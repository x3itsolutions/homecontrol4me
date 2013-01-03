/*
 *  EncodeBase64.h
 *  MIME Base64 coding examples
 *
 *  encode() encodes an arbitrary data block into MIME Base64 format string
 *  I have found this code at link:
 *  http://bytes.com/topic/c/answers/666797-sample-base64-encoding-c-language 
 */

#include <avr/pgmspace.h>

namespace EncodeBase64 {

	// Global data used by binary-to-base64 conversions
	const char base64[] PROGMEM =	"ABCDEFGHIJKLMNOPQRSTUVWXYZ"
									"abcdefghijklmnopqrstuvwxyz"
									"0123456789"
									"+/";

	//
	// Encode source from raw data into Base64 encoded string
	//
	// Returns: 
	// 0 - Success
	// 1 - Error - dest too short
	//
	int encode(char *src, unsigned s_len, char *dst, unsigned d_len) {
	
		unsigned triad;
	
		for(triad = 0; triad < s_len; triad += 3) {
	
			unsigned long int sr;
			unsigned i_byte;
		
			for(i_byte = 0; (i_byte<3)&&(triad+i_byte<s_len); ++i_byte) {
				sr <<= 8;
				sr |= (*(src+triad+i_byte) & 0xff);
			}
		
			sr <<= (6-((8*i_byte)%6))%6;		// shift left to next 6bit alignment
		
			if(d_len < 4) return 1;				// error - dest too short
		
			*(dst+0) = *(dst+1) = *(dst+2) = *(dst+3) = '=';
			switch(i_byte) {
				case 3:
					//*(dst+3) = base64[sr&0x3f];
					*(dst+3) = pgm_read_byte_near(base64+(sr&0x3f));
					sr >>= 6;
				case 2:
					//*(dst+2) = base64[sr&0x3f];
					*(dst+2) = pgm_read_byte_near(base64+(sr&0x3f));
					sr >>= 6;
				case 1:
					//*(dst+1) = base64[sr&0x3f];
					*(dst+1) = pgm_read_byte_near(base64+(sr&0x3f));
					sr >>= 6;
					//*(dst+0) = base64[sr&0x3f];
					*(dst+0) = pgm_read_byte_near(base64+(sr&0x3f));
			}
			dst += 4; 
			d_len -= 4;
		}
		return 0;
	}

};
