// homecontrol4me EEPROM PREPARE v1.01

/* 
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
#include <stdlib.h>
#include <EEPROM.h>
#include "eeprom.h"


eeprom eeprom;

void setup() {    
    eeprom.setPasswd("admin");
    byte mac[] = {  0xDE, 0xAD, 0xBE, 0x11, 0xFE, 0xED };
    byte ip[] = { 192,168,2,10 };
    byte mask[] = {255,255,255,0};
    byte gw[] = { 192,168,2,1 };
    byte svip[] = { 192,168,2,1 };
    boolean dhcp = false;
    eeprom.setMac(mac);
    eeprom.setIp(ip);
    eeprom.setMask(mask);
    eeprom.setGw(gw);
    eeprom.setDhcp(dhcp);
    byte number[10];
    for (int i=0;i<10;i++)
    eeprom.data.number[i] = i+1;
    char name[10][12] = {"Beispiel 1", "Beispiel 2", "Beispiel 3", "Beispiel 4", "Beispiel 5", "Beispiel 6", "Beispiel 7", "Beispiel 8", "Beispiel 9", "Beispiel 10"};
    for(int i=0;i<10;i++)
    eeprom.setName(i,name[i]);
    eeprom.write();
}

void loop(){
}
