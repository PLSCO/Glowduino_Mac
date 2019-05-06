#include "WProgram.h"

/*
void dfu_mode() {
    EEPROM.write(0, 13);
    #define CPU_RESTART_ADDR (uint32_t *)0xE000ED0C
    #define CPU_RESTART_VAL 0x5FA0004
    #define CPU_RESTART (*CPU_RESTART_ADDR = CPU_RESTART_VAL);
    CPU_RESTART;
}
*/

extern "C" int main(void)
{
#if !defined(ARDUINO)
    
    // To use Teensy 3.0 without Arduino, simply put your code here.
    // For example:
    
    pinMode(13, OUTPUT);
    while (1) {
        digitalWriteFast(13, HIGH);
        delay(2000);
        digitalWriteFast(13, LOW);
        delay(2000);
    }
    
    
#else
    // Arduino's main() function just calls setup() and loop()....
    setup();
    while (1) {
        loop();
        yield();
    }
#endif
}
