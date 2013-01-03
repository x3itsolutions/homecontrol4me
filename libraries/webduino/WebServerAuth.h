/* -*- Mode: C++; tab-width: 2; indent-tabs-mode: nil;  c-file-style: "k&r"; c-basic-offset: 2; -*-

   Webduino Auth Extension
   Copyright 2010 Claudio Baldazzi
   Webduino: Copyright 2009 Ben Combee, Ran Talbott
   
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
*/
/*
   Webduino Auth Extension: WebServerAuth is a derived class from Webduino WebServer.
   With the derived class WebServerAuth, the WebServer class is mostly unchanged. 
   The only change to WebServer class is the declaration of private part in protected.
*/

#ifndef WEBDUINOAUTH_H_
#define WEBDUINOAUTH_H_

#include <string.h>
#include <stdlib.h>

#if WEBDUINO_SERIAL_DEBUGGING
#include <HardwareSerial.h>
#endif

#include "EncodeBase64.h"
#include "WebServer.h"

class WebServerAuth: public WebServer {

public:
		WebServerAuth(const char* user, const char* passwd,
									const char *urlPrefix = "/", int port = 80);
		WebServerAuth(const char *urlPrefix = "/", int port = 80);				
		int setAuth(const char* user, const char* passwd);
							
		void httpAuthFail();
		bool checkAuth();

		void processConnection();
		void processConnection(char *buff, int *bufflen);

protected:
		void processHeaders();

private:
		bool  m_bAuth;
		char  m_base64BasicAuth[32];		// user:password max 24 chars
	
		bool checkAuth(const char* base64Auth);
};

WebServerAuth::WebServerAuth(const char* user, const char* passwd,
														 const char *urlPrefix, int port): WebServer(urlPrefix,port) {
		int	idx = 0;
		char buf[24];

		for(int i = 0; i<strlen(user); i++)
				buf[idx++] = user[i];
		buf[idx++] = ':';
		for(int i = 0; i<strlen(passwd); i++)
				buf[idx++] = passwd[i];
		buf[idx] = 0x00;
	
		int error = EncodeBase64::encode(buf,strlen(buf),m_base64BasicAuth,32);
		if(error) strcpy(m_base64BasicAuth,"YWRtaW46YWRtaW4=");		// "admin:admin"
}
WebServerAuth::WebServerAuth(const char *urlPrefix, int port): WebServer(urlPrefix,port) {
	strcpy(m_base64BasicAuth,"YWRtaW46YWRtaW4=");
}
int WebServerAuth::setAuth(const char* user, const char* passwd) {
		int	idx = 0;
		char buf[24];

		for(int i = 0; i<strlen(user); i++)
				buf[idx++] = user[i];
		buf[idx++] = ':';
		for(int i = 0; i<strlen(passwd); i++)
				buf[idx++] = passwd[i];
		buf[idx] = 0x00;
	
		int error = EncodeBase64::encode(buf,strlen(buf),m_base64BasicAuth,32);
		if(error) {
			strcpy(m_base64BasicAuth,"YWRtaW46YWRtaW4=");		// "admin:admin"
			return -1;
		}
		return 0;
}

void WebServerAuth::httpAuthFail()
{
		P(failAuthMsg) =
    		"HTTP/1.0 401 Authorization Required" CRLF
    		WEBDUINO_SERVER_HEADER
    		"WWW-Authenticate: Basic realm=\"Arduino\"" CRLF
    		"Content-Type: text/html" CRLF
    		CRLF
    		"<html><body><h1>401 Unauthorized.</h1></body></html>";

		printP(failAuthMsg);
}

bool WebServerAuth::checkAuth(const char* base64Auth) {
		
		// Sample:	
		// Authorization: Basic YWRtaW46YWRtaW4=

		int ch;
	
  	do {				// absorb whitespace
    		ch = read();
  	} while(ch == ' ' || ch == '\t');

  	// read Auth Type (Basic)
  	int bufIdx = 0;
  	char buf[32];
  	while((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z')) {
	  		buf[bufIdx++] = ch;
  	  	ch = read();
  	}
  	buf[bufIdx] = 0x00;

  	if(0 != strcasecmp("Basic",buf)) return false;

  	do {				// absorb whitespace
    		ch = read();
  	} while(ch == ' ' || ch == '\t');
	
  	// read Base64 Auth
  	bufIdx = 0;
  	while(ch != '\r' && ch != '\n') {
	  		buf[bufIdx++] = ch;
  	  	ch = read();
  	}
		push(ch);
		buf[bufIdx] = 0x00;

		if(0 != strcmp(m_base64BasicAuth,buf)) return false;
		
		return true;
}

void WebServerAuth::processHeaders() {

		// look for two things: the Content-Length header and the double-CRLF
		// that ends the headers.

		while (1) {
    		if(expect("Content-Length:")) {
      			readInt(m_contentLength);
#if WEBDUINO_SERIAL_DEBUGGING > 1
      			Serial.print("\n*** got Content-Length of ");
      			Serial.print(m_contentLength);
      			Serial.print(" ***");
#endif
      			continue;
				}

				// Modified by Claudio
				if(expect("Authorization:")) {
						m_bAuth = checkAuth(m_base64BasicAuth);
#if WEBDUINO_SERIAL_DEBUGGING > 1
						Serial.print("\n*** got Authorization of ");
						Serial.print(m_bAuth);
						Serial.print(" ***");
#endif
						continue;
				}
				// End modification

    		if (expect(CRLF CRLF)) {
      			m_readingContent = true;
      			return;
    		}

    		// no expect checks hit, so just absorb a character and try again
    		if (read() == -1) {
      			return;
    		}
		}
}

// processConnection with a default buffer
void WebServerAuth::processConnection() {
  	char request[WEBDUINO_DEFAULT_REQUEST_LENGTH];
  	int  request_len = WEBDUINO_DEFAULT_REQUEST_LENGTH;
  	processConnection(request, &request_len);
}

void WebServerAuth::processConnection(char *buff, int *bufflen) {
		m_client = m_server.available();
		m_bAuth = false;

		if(m_client) {
				m_readingContent = false;
				buff[0] = 0;
				ConnectionType requestType = INVALID;
#if WEBDUINO_SERIAL_DEBUGGING > 1
				Serial.println("*** checking request ***");
#endif
				getRequest(requestType, buff, bufflen);
#if WEBDUINO_SERIAL_DEBUGGING > 1
				Serial.print("*** requestType = ");
				Serial.print((int)requestType);
				Serial.println(", request = \"");
				Serial.print(buff);
				Serial.println("\" ***");
#endif
				processHeaders();
#if WEBDUINO_SERIAL_DEBUGGING > 1
				Serial.println("*** headers complete ***");
#endif

				// Modified by Claudio
				if(!m_bAuth) {
						httpAuthFail();
				}
				else {
						int urlPrefixLen = strlen(m_urlPrefix);
						if (strcmp(buff, "/robots.txt") == 0) {
								noRobots(requestType);
						}
						else if(requestType == INVALID ||
							strncmp(buff, m_urlPrefix, urlPrefixLen) != 0 ||
							!dispatchCommand(requestType, buff + urlPrefixLen,
							(*bufflen) >= 0)) {
								m_failureCmd(*this, requestType, buff, (*bufflen) >= 0);
						}
				}
				// End modification

#if WEBDUINO_SERIAL_DEBUGGING > 1
    		Serial.println("*** stopping connection ***");
#endif
    		m_client.stop();
		}
}

#endif	// WEBDUINOAUTH_H_