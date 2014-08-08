#include <stdio.h>

void printOct ( int val ) { printf ("%o\n", val); }

void printHex ( int val ) { printf ("%X\n", val); } 

void printInstrument1 ( int val ) { printf ("%u\n", val);
							printf("Instrument 1: Flute Picked\n");}

void printOff ( int val ) { printf ("%u\n", val);
							printf("OFF Instrument\n");}
							
void printInstrument2 ( int val ) { printf ("%u\n", val);
							printf("Instrument 2: Vibrato Trumpet Picked\n");}