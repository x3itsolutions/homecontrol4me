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

#include "eeprom.h"

eeprom::eeprom() {
    read();
}


int eeprom::write()
{
    byte Address = EEPROM_CONFIGADDRESS;
  
    const byte* p = (const byte*)(const void*)&data;
    int i;
    for (i = 0; i < sizeof(data); i++)
      EEPROM.write(Address++, *p++);
    return i;
}

int eeprom::read()
{
    byte Address = EEPROM_CONFIGADDRESS;
  
    byte* p = (byte*)(void*)&data;
    int i;
    for (i = 0; i < sizeof(data); i++)
      *p++ = EEPROM.read(Address++);
    return i;
}

void eeprom::setMac(byte* mac){
  for(int i=0;i<6;i++)
  data.mac[i] = mac[i];
}

void eeprom::setIp(byte* ip){
  for(int i=0;i<4;i++)
  data.ip[i] = ip[i];
}

void eeprom::setMask(byte* mask){
  for(int i=0;i<4;i++)
  data.mask[i] = mask[i];
}

void eeprom::setGw(byte* gw){
  for(int i=0;i<4;i++)
  data.gw[i] = gw[i];
}


void eeprom::setDhcp(boolean dhcp){
  data.dhcp = dhcp;
}

void eeprom::setPasswd(char* passwd){
  for(int i=0;i<strlen(passwd)+1;i++)
    data.passwd[i]=passwd[i];
}

void eeprom::setNumber(byte* number){
  for(int i=0;i<10;i++)
  data.number[i] = number[i];
}

void eeprom::setName(int number, char* name){
  

    for(int j=0;j<strlen(name)+1;j++){
      data.name[number][j]=name[j];
    }

}
