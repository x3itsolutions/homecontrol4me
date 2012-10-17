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

#include <EEPROM.h>
#include <WProgram.h>

#define PWD_MAX_SIZE 10
#define NAMES_MAX_SIZE 20
#define EEPROM_CONFIGADDRESS 0
#define MAX_NUMBERS 10

class eeprom{
public:

eeprom();
    int write();
    int read();
    void setMac(byte*);
    void setIp(byte*);
    void setMask(byte*);
    void setGw(byte*);
    void setDhcp(boolean);
    void setPasswd(char*);
    void setNumber(byte*);
    void setName(int, char*);

    
    
struct config_t
{
    byte mac[6];
    byte ip[4];
    byte mask[4];
    byte gw[4];
    boolean dhcp;
    char passwd[PWD_MAX_SIZE+1];
    byte number[MAX_NUMBERS];
    char name[MAX_NUMBERS][NAMES_MAX_SIZE+1];
    
} data;

};
