/* 
homecontrol 4 me - v1.102

homecontrol 4 me - Arduino Sketch for home control
Copyright (c) 2012 Fabian Behnke All right reserved.

This file is Part of homecontrol4me.

homecontrol4me is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

homecontrol4me is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Diese Datei ist Teil von homecontrol4me.

homecontrol4me ist Freie Software: Sie können es unter den Bedingungen
der GNU General Public License, wie von der Free Software Foundation,
Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren
veröffentlichten Version, weiterverbreiten und/oder modifizieren.

homecontrol4me wird in der Hoffnung, dass es nützlich sein wird, aber
OHNE JEDE GEWÄHRLEISTUNG, bereitgestellt; sogar ohne die implizite
Gewährleistung der MARKTFÄHIGKEIT oder EIGNUNG FÜR EINEN BESTIMMTEN ZWECK.
Siehe die GNU General Public License für weitere Details.

Sie sollten eine Kopie der GNU General Public License zusammen mit diesem
Programm erhalten haben. Wenn nicht, siehe <http://www.gnu.org/licenses/>.
*/

//needed Libraries:
//Ethernet DHCP - Georg Kaindl
//Streaming - Mikal Hart
//Webduino - Ben Combee and Ran Talbott
//Auth Extension  - Claudio Baldazzi
//RCSwitch - Suat Özgür

//---------- Attention: Please flash ---------------
//------- homecontrol4me EEPROM PREPARE ------------ 
//------- before flashing this sketch!!! -----------

//Libraries
#include <stdlib.h>
#include <string.h>
#include <SPI.h>
#include <EEPROM.h>
#include <Ethernet.h>
#include <Streaming.h>
#include <WebServerAuth.h>
#include "eeprom.h"
#include <EthernetDHCP.h>
#include <RCSwitch.h>

//Defines
#define WEB_PREFIX  ""
#define WEB_PORT  80
#define NAMELEN 10
#define VALUELEN 22


// -------------------- Global Vars -------------------------
// Network configuration in EEPROM
eeprom eeprom;
// Char Namelength & Valuelength for HTTP Post Method
char name[NAMELEN];
char value[VALUELEN];

// Is wireles electric socket on or off?!?
boolean powerOutlet[161];

// Instance of RCSwitch
RCSwitch mySwitch = RCSwitch();

// Instance of Webduino Webserver
WebServerAuth webserver("admin",eeprom.data.passwd,WEB_PREFIX,WEB_PORT);
// Admin Web setup function prototyping
void web_setup();

// ------------- switch socket function ---------------------
void switchWirelessOutlet(int number){

  mySwitch.disableReceive();
  delay(10);
  
  int numberStk = number % 5;
  if (numberStk == 0) numberStk = 5;

  if (powerOutlet[number] == false){ 
    mySwitch.switchOn(int2bin(((number-1)/5)+1), numberStk);
    powerOutlet[number] = true;
  } else{
    if (powerOutlet[number] == true){ 
      mySwitch.switchOff(int2bin(((number-1)/5)+1), numberStk);
      powerOutlet[number] = false;
    } 
  }
  
  delay(10);
  mySwitch.enableReceive(0, output);
}
//--------------- receive  ---------------------------
unsigned long switchMillis;
boolean switchOutletOn[4];
boolean switchOutletOff[4];
void output(unsigned long decimal, unsigned int length, unsigned int delay, unsigned int* raw) {
  switchMillis = millis();
  if (decimal != 0) {
    if (decimal == 5588305 && powerOutlet[eeprom.data.number[0]] == false){
      switchOutletOn[0] = true;
    }
    if (decimal == 5588308 && powerOutlet[eeprom.data.number[0]] == true){
      switchOutletOff[0] = true;
    }
  
    if (decimal == 5591377 && powerOutlet[eeprom.data.number[1]] == false){
      switchOutletOn[1] = true;
    }
    if (decimal == 5591380 && powerOutlet[eeprom.data.number[1]] == true){
      switchOutletOff[1] = true;
    }
  
    if (decimal == 5592145 && powerOutlet[eeprom.data.number[2]] == false){
      switchOutletOn[2] = true;
    }
    if (decimal == 5592148 && powerOutlet[eeprom.data.number[2]] == true){
      switchOutletOff[2] = true;
    }
    
    if (decimal == 5592337 && powerOutlet[eeprom.data.number[3]] == false){
      switchOutletOn[3] = true;
    }
    if (decimal == 5592415 && powerOutlet[eeprom.data.number[3]] == true){
      switchOutletOff[3] = true;
    }
  } 
}


// --------- convert byte to hex-string function ------------
char hexval[16] PROGMEM = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};
char* hexstr(byte b) {
    static char hex[3];
    hex[0] = pgm_read_byte_near(hexval+((b >> 4) & 0xF));
    hex[1] = pgm_read_byte_near(hexval+(b & 0x0F));
    hex[2] = 0x00;
    return hex;
}

// ------------ convert int to bin function ----------------
char* int2bin(unsigned int x)
{
  static char buffer[6];
  for (int i=0; i<5; i++) buffer[4-i] = '0' + ((x & (1 << i)) > 0);
  buffer[5] ='\0';
  return buffer;
}

// ------------------ Reset stuff --------------------------
void(* resetFunc) (void) = 0;
unsigned long resetMillis;
boolean resetSytem = false;

// ----------------- Arduino SETUP -------------------------
void setup() {
  // Transmitter is connected to Arduino Pin #7  
  mySwitch.enableTransmit(7);
  
  //Receiver is on Interrupt 0 - Arduino Pin #2  
  mySwitch.enableReceive(0, output);
 
  // Optional set pulse length.
  mySwitch.setPulseLength(350);  

    if(eeprom.data.dhcp == true)
    EthernetDHCP.begin(eeprom.data.mac, 1);
    else
    // init ethernet and servers
    Ethernet.begin(eeprom.data.mac, eeprom.data.ip, eeprom.data.gw, eeprom.data.mask);

    // Admin web init
    web_setup();
}
int i = 0;

// ---------------- Arduino LOOP --------------------
void loop() {
  unsigned long currentMillis = millis(); 
  
  if(switchOutletOn[0] == true && ((currentMillis - switchMillis) > 100)){
    switchWirelessOutlet((int)eeprom.data.number[0]);
    switchOutletOn[0] = false;
  }
  if(switchOutletOn[1] == true && ((currentMillis - switchMillis) > 100)){
    switchWirelessOutlet((int)eeprom.data.number[1]);
    switchOutletOn[1] = false;
  }
  if(switchOutletOn[2] == true && ((currentMillis - switchMillis) > 100)){
    switchWirelessOutlet((int)eeprom.data.number[2]);
    switchOutletOn[2] = false;
  }
  if(switchOutletOn[3] == true && ((currentMillis - switchMillis) > 100)){
    switchWirelessOutlet((int)eeprom.data.number[3]);
    switchOutletOn[3] = false;
  }
  
if(switchOutletOff[0] == true && ((currentMillis - switchMillis) > 100)){
    switchWirelessOutlet((int)eeprom.data.number[0]);
    switchOutletOff[0] = false;
  }
  if(switchOutletOff[1] == true && ((currentMillis - switchMillis) > 100)){
    switchWirelessOutlet((int)eeprom.data.number[1]);
    switchOutletOff[1] = false;
  }
  if(switchOutletOff[2] == true && ((currentMillis - switchMillis) > 100)){
    switchWirelessOutlet((int)eeprom.data.number[2]);
    switchOutletOff[2] = false;
  }
  if(switchOutletOff[3] == true && ((currentMillis - switchMillis) > 100)){
    switchWirelessOutlet((int)eeprom.data.number[3]);
    switchOutletOff[3] = false;
  }
//Reset the System after a second
if (resetSytem == true && (currentMillis - resetMillis) > 1000) resetFunc();

//DHCP poll
if(eeprom.data.dhcp == true)  
DhcpState state = EthernetDHCP.poll();

// Check web admin connection
webserver.processConnection();

}


// ---------------------------------------------------------------------
// Admin Web server
//
P(htmlHead1) = "<html><head>";
P(htmlHead2) = "<title>homecontrol 4 me</title>"
    "<style type=\"text/css\">"
    "body{font-family:sans-serif}"
    "h1{font-size:25pt;}"
    "p{font-size:20pt;}"
    "*{font-size:14pt}"
    "a{color:#9bbb1c;}"
    "</style>"
    "</head><body text=\"white\" bgcolor=\"#494949\">";
P(htmlBackTail) = "<br/><a href=\"javascript:history.back()\">Zur&uumlck!</a><br/><br/>";
P(htmlTail) = "<br/><a href=\"/\">Zur&uuml;ck zum Hauptmen&uuml;</a><br/><br/>"
    "</body></html>";
    
P(htmlTail2) = "</body></html>";  

P(trtd180) = "<tr><td width=\"400\" align=\"right\">";
P(tdtd) = "</td><td><input maxlength=\"10\" type=\"password\" name=\"";
P(tdtr) = "\"/></td></tr>";

P(submit) = 
    "</tbody></table>"
    "<br/>"
    "<input type='submit' value='Abschicken'/></form>";
P(posttable) = "method='post'>"
    "<table cellpadding=\"2\" border=\"1\" rules=\"rows\" frame=\"box\" bordercolor=\"white\" width=\"500\">"
    "<thead><b>";

int get_verified_ip(char* sip, byte ip[4]) {
    
    // verify IP string syntax and store in array
    
    char*  soctect = strtok(sip,".");
    if(!soctect) return -1;
    int    noctect = atoi(soctect);
    if(noctect >= 0 && noctect <= 255)
        ip[0] = noctect;
    else
        return -1;

    if(!(soctect = strtok(NULL,"."))) return -1;
    noctect = atoi(soctect);
    if(noctect >= 0 && noctect <= 255)
        ip[1] = noctect;
    else
        return -1;

    if(!(soctect = strtok(NULL,"."))) return -1;
    noctect = atoi(soctect);
    if(noctect >= 0 && noctect <= 255)
        ip[2] = noctect;
    else
        return -1;

    if(!(soctect = strtok(NULL,"."))) return -1;
    noctect = atoi(soctect);
    if(noctect >= 0 && noctect <= 255)
        ip[3] = noctect;
    else
        return -1;
        
    return 0;
}


// Webduino pages

void defaultCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete) {

  server.httpSuccess();
  server.printP(htmlHead1);
  {
      URLPARAM_RESULT rc;

  if (type == WebServer::HEAD)
    return;

  boolean schalte = false;
  if (strlen(url_tail))
    {
    while (strlen(url_tail))
      {
      rc = server.nextURLparam(&url_tail, name, NAMELEN, value, VALUELEN);
      if (rc == URLPARAM_EOS);
       else
        {
        if (schalte == true) switchWirelessOutlet(atoi(name));
        if (strcmp(name, "schalte") == 0) schalte = true ; 
        }
      }
      server.print("<meta http-equiv=\"refresh\" content=\"0; URL=index.html\">");
    }

  }
  
    char buf[4];
    
    
    //server.print("<meta http-equiv=\"refresh\" content=\"5; URL=index.html\">");    
    server.printP(htmlHead2);

    P(htmlT00a) =
    "<table><tr>"
    "<h1>homecontrol 4 me</h1><br/>";
    server.printP(htmlT00a); 
    
    P(Table1) = 
    
    "<td width=\"200\" height=\"200\"  bgcolor=\"";
    

    
    P(Table2) =
    "\" align=\"center\" onClick=\"document.location.href='index.html?schalte";



    P(Table3) =
    "';\" style=\"cursor:pointer;\">";
    

    
    P(Table4) =
    "</td>";
    
    
    for (int n=1; n<11;n++){
      server.printP(Table1);
      if (powerOutlet[(int)eeprom.data.number[n-1]]) server.print("#9bbb1c");
      else server.print("#7d7575");
      server.printP(Table2);
      server.print("&");
      server.print((int)eeprom.data.number[n-1]);
      server.printP(Table3);
      server.print(eeprom.data.name[n-1]);
      server.printP(Table4);
      if(n == 5)server.print("</tr><tr>");
    
    }
    
    P(Table5) =
    "</tr>"
    "</table>"
    "</br></br>[<a href=config>Einstellungen</a>] [<a href=netform>Netzwerk</a>] [<a href=pwdform>Passwort</a>]<br/><br/>";
    server.printP(Table5);

    server.printP(htmlTail2);
}

    
void netForm(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete) {
    char buf[4];
    
    if (type == WebServer::POST) {
        server.httpFail();
        return;
    }
    server.httpSuccess();
    
    server.printP(htmlHead1);
    server.printP(htmlHead2);
    
    P(top) = 
    "<h1>Netzwerkeinstellungen</h1><br/>"
    "<form action='/netpost' ";
    server.printP(top);
    
    
    server.printP(posttable);
    
    P(top2) = 
    "&Auml;ndern sie hier Ihre Netzwerkeinstellungen</b></thead><tbody>";
    server.printP(top2);
    
    server.printP(trtd180);
    P(htmlNetForm1) =
    "IP Addresse:</td><td><input type=\"text\" name=\"ip\" value=\"";
    server.printP(htmlNetForm1);
    
    server << itoa(eeprom.data.ip[0],buf,10) << "." << itoa(eeprom.data.ip[1],buf,10) << "." << itoa(eeprom.data.ip[2],buf,10) << "." << itoa(eeprom.data.ip[3],buf,10);
    
    server.printP(tdtr);
    server.printP(trtd180);
    P(htmlNetForm2) = 
    "Subnetzmaske:</td><td><input type=\"text\" name=\"mask\" value=\"";
    server.printP(htmlNetForm2);
    server << itoa(eeprom.data.mask[0],buf,10) << "." << itoa(eeprom.data.mask[1],buf,10) << "." << itoa(eeprom.data.mask[2],buf,10) << "." << itoa(eeprom.data.mask[3],buf,10);
    
    server.printP(tdtr);
    server.printP(trtd180);
    P(htmlNetForm3) = 
    "Gateway:</td><td><input type=\"text\" name=\"gw\" value=\"";
    server.printP(htmlNetForm3);
    server << itoa(eeprom.data.gw[0],buf,10) << "." << itoa(eeprom.data.gw[1],buf,10) << "." << itoa(eeprom.data.gw[2],buf,10) << "." << itoa(eeprom.data.gw[3],buf,10);
    
    server.printP(tdtr);
    server.printP(trtd180);
    P(htmlNetForm4) = 
    "DHCP:</td><td><input type=checkbox name=\"dh\" value=\"x\"";
    server.printP(htmlNetForm4);
    
    if(eeprom.data.dhcp == true)
      server << " checked";
      
    server.printP(tdtr);  
    server.printP(submit);

    server.printP(htmlTail);
}

//char name[6], value[22];
void netPost(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete) {
    int result = 0;
    char buf[5];
    P(htmlOk) = "Neue Einstellung ist OK!<br/>";
    P(htmlNOk1) = "IP ist nicht zul&auml;ssig!<br/>";
    P(htmlNOk2) = "Subnetzmaske ist nicht zul&auml;ssig!<br/>";
    P(htmlNOk3) = "Gateway ist nicht zul&auml;ssig!<br/>";
    
    if(type == WebServer::POST) {
        server.printP(htmlHead1);
        server.printP(htmlHead2);

        server.readPOSTparam(name, 6, value, 17);
        if(0 == strcmp(name,"ip")) {
            if(get_verified_ip(value, eeprom.data.ip))
                result = 1;
        }
        server.readPOSTparam(name, 6, value, 17);
        if(0 == strcmp(name,"mask") && !result) {
            if(get_verified_ip(value, eeprom.data.mask))
                result = 2;
        }
        server.readPOSTparam(name, 6, value, 17);
        if(0 == strcmp(name,"gw") && !result) {
            if(get_verified_ip(value, eeprom.data.gw))
                result = 3;
        }
        server.readPOSTparam(name, 6, value, 17);
        if(0 == strcmp(name,"dh") && !result){
          if(0 == strcmp(value,"x"))
            eeprom.data.dhcp = true;            
        }else eeprom.data.dhcp = false;


        switch(result) {
            case 0:
                eeprom.write();
                server.printP(htmlOk);
                server.printP(htmlTail);
                resetMillis = millis(); 
                resetSytem = true;
                break;
            case 1:
                server.printP(htmlNOk1);
                server.printP(htmlBackTail);
                break;
            case 2:
                server.printP(htmlNOk2);
                server.printP(htmlBackTail);
                break;
            case 3:
                server.printP(htmlNOk3);
                server.printP(htmlBackTail);
                break;
        }
        
    }
}


void pwdForm(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete) {

    if (type == WebServer::POST) {
        server.httpFail();
        return;
    }
    server.httpSuccess();
    
    server.printP(htmlHead1);
    server.printP(htmlHead2);
    
    P(top) ="<h1>Passwort &auml;ndern</h1><br/><form action='/pwdpost'";
     P(top2) = "Max.: 10 Zeichen</b></thead><tbody>";

    server.printP(top);
    server.printP(posttable);
    server.printP(top2);
    
    server.printP(trtd180);
    P(oldPW) = "Altes Passwort:"; 
    server.printP(oldPW);
    server.printP(tdtd);
    P(oldPWn) = "oldpw";
    server.printP(oldPWn);
    server.printP(tdtr);
    
    server.printP(trtd180);
    P(newPW) = "Neues passwort:"; 
    server.printP(newPW);
    server.printP(tdtd);
    P(newPWn) = "newpw";
    server.printP(newPWn);
    server.printP(tdtr);
    
    server.printP(trtd180);
    P(rePW) = "Passwort wiederholen:"; 
    server.printP(rePW);
    server.printP(tdtd);
    P(rePWn) = "repw";
    server.printP(rePWn);
    server.printP(tdtr);
    
    server.printP(submit);
    
    server.printP(htmlTail);
}

void pwdPost(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete) {

    char pwd[11];
    int result = 0;

    P(htmlOk) = "Neues Passwort wurde angenommen!<br/>";
    P(htmlNOk1) = "Fehler: Altes Passwort falsch!<br/>";
    P(htmlNOk2) = "Fehler: Neues Passwort stimmt nicht überein!<br/>";
    
    if(type == WebServer::POST) {
        server.printP(htmlHead1);
        server.printP(htmlHead2);
        server.readPOSTparam(name, 16, value, 16);
        if(0 == strcmp(name,"oldpw")) {
            if(!(0 == strcmp(value,eeprom.data.passwd))) 
                result = 1;
        }
        server.readPOSTparam(name, 16, value, 16);
        if(0 == strcmp(name,"newpw") && !result) {
                for(int i=0; i<strlen(value); i++){
                    pwd[i] = value[i];
                    
                  }
                for(int i=strlen(value); i<11; i++)
                    pwd[i] = 0x00;
        }
        server.readPOSTparam(name, 16, value, 16);
        if(0 == strcmp(name,"repw") && !result) {
            if((strlen(pwd) != strlen(value)) || !(0 == strcmp(value,pwd)))
                result = 2;
        }
        switch(result) {
            case 0:
                server.printP(htmlOk);
                server.printP(htmlTail);
                eeprom.setPasswd(pwd);  
                eeprom.write();
                resetMillis = millis(); 
                resetSytem = true;
                break;
            case 1:
                server.printP(htmlNOk1);
                server.printP(htmlBackTail);
                break;
 
            case 2:
                server.printP(htmlNOk2);
                server.printP(htmlBackTail);
                break;
        }  
    }
}

void failureCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete) {
  
    server.httpFail();
    P(failMsg) =
    "<html><body><h1>Seite wurde nicht gefunden!</h1></body></html>";    
    server.printP(failMsg);
}



void rawCmd(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{    
  server.httpSuccess();
  {
  URLPARAM_RESULT rc;

  if (type == WebServer::HEAD)
    return;

  boolean schalte = false;
  boolean stat = false;
  if (strlen(url_tail))
    {
    while (strlen(url_tail))
      {
      rc = server.nextURLparam(&url_tail, name, NAMELEN, value, VALUELEN);
      if (rc == URLPARAM_EOS);
       else
        {
        if (schalte == true) {
          switchWirelessOutlet(atoi(name));
          server.print(name);
          server.print(":");
          if (powerOutlet[atoi(name)]) server.print("1\n");
          else server.print("0\n");
        }
        if (stat == true){
          server.print(name);
          server.print(":");
          if (powerOutlet[atoi(name)]) server.print("1\n");
          else server.print("0\n");
        }
        if (strcmp(name, "schalte") == 0) schalte = true ; 
        if (strcmp(name, "status") == 0) stat = true ; 
        }
      }
    }else{
          for (int i=0;i<10;i++){
          server.print((int)eeprom.data.number[i]);
          server.print(":");
          server.print(eeprom.data.name[i]);
          server.print(":");
          if (powerOutlet[(int)eeprom.data.number[i]]) server.print("1\n");
          else server.print("0\n");
          }
    
    }

  }
}

void confForm(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete) {

    if (type == WebServer::POST) {
        server.httpFail();
        return;
    }
    server.httpSuccess();
    
    server.printP(htmlHead1);
    server.printP(htmlHead2);
    
    P(top) ="<h1>Einstellungen</h1><br/><form action='/confpost'";
    P(top2) = "Maximall&auml;nge: Namen 20 Zeichen</b></thead><tbody>";

    server.printP(top);
    server.printP(posttable);
    server.printP(top2);
    
    P(tr) = "<tr>";
    P(td) = "<td width=\"400\" align=\"right\">";
    P(td2) = "</td>";
    P(tr2) = "</tr>";
    P(tdtr) = "</td></tr>";
    P(input) = "<input type=\"text\" maxlength=\"20\" name=\"skd";
    P(input2) = "\" value=\"";
    P(input3) = "\"/>";
    
    P(select) = "<select name=\"num";
    P(select1) = "\">";
    P(option) = "<option";
    P(option1) = " value=\"";
    P(option2) = "\">";
    P(option3) = "</option>";
    P(select2) = "</select>";
    
    
    
    for(int i=0;i<10;i++){
      server.printP(tr);
      
      server.printP(td);
      server.print("Schaltfläche ");
      server.print(i+1);
      server.printP(td2);
      
      server.printP(td);
      server.printP(input);
      server.print(i);
      server.printP(input2);
      server.print(eeprom.data.name[i]);
      server.printP(input3);
      server.printP(td2);
      
      server.printP(td);
      
      server.printP(select);
      server.print(i);
      server.printP(select1);
      for (int j=1;j<=160;j++){
        server.printP(option);
        if (eeprom.data.number[i] == j)server.print(" selected");
        server.printP(option1);
        server.print(j);
        server.printP(option2);
        server.print(j);
        server.printP(option3);
      }
      server.printP(select2);
      
      server.printP(td2);
      
      server.printP(tr2);
    }
    
   

    server.printP(submit);
    
    server.printP(htmlTail);
}

void confPost(WebServer &server, WebServer::ConnectionType type, char *url_tail, bool tail_complete)
{
    char buf[4];
    char skd[5] = "skd";
    skd[4] = 0;
    char num[5] = "num";
    num[4] = 0;
    int result = 0;


    if(type == WebServer::POST) {
        server.printP(htmlHead1);
        server.printP(htmlHead2);
        for (int i=0;i<=9;i++){
          itoa(i,buf,10);
          
          server.readPOSTparam(name, 16, value, 22);
          skd[3] = buf[0];
          if(0 == strcmp(name,skd)){
            for (int j=0;j<strlen(value);j++)
            eeprom.data.name[i][j] = value[j];
            eeprom.data.name[i][strlen(value)] = 0;
          }
          
          server.readPOSTparam(name, 16, value, 22);    
          num[3] = buf[0];
          if(0 == strcmp(name,num)){
            eeprom.data.number[i] = atoi(value);
          }

          
          
        }
        eeprom.write();
        P(htmlOk) = "Einstellungen wurden &uuml;bernommen!<br/>";
        server.printP(htmlOk);  
        server.printP(htmlTail);    
    }
}

void web_setup() {
    webserver.begin();

    webserver.setDefaultCommand(&defaultCmd);
    webserver.addCommand("index.html", &defaultCmd);
    webserver.addCommand("netform", &netForm);
    webserver.addCommand("netpost", &netPost);
    webserver.addCommand("pwdform", &pwdForm);
    webserver.addCommand("pwdpost", &pwdPost);
    webserver.addCommand("config", &confForm);
    webserver.addCommand("confpost", &confPost);    
    webserver.addCommand("rawCmd", &rawCmd);
    webserver.setFailureCommand(&failureCmd);
 
}
//
// ---------------------------------------------------------------------


