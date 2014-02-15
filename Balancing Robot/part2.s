# Include nios_macros.s to workaround a bug in the movia pseudo-instruction.
.include "nios_macros.s"

.equ RED_LEDS, 0x10000000 	   # Use with 18 bits
.equ GREEN_LEDS, 0x10000010    # Used with 9 bits 
.equ ADDR_JP1, 0x10000060
.equ ADDR_JP2, 0x10000070
.equ ADDR_JP2_IRQ, 0x1000
.equ LEGO_INITIALIZE, 0x07f557ff  # Set direction of all motors to outputs 
.equ ENABLE_STATE_MODE, 0xffdfffff
.equ MOTOR0_EN_FWD, 0xfffffffc
.equ SENSOR1_EN_MOTOR0_FWD, 0xffffeffe
.equ SENSOR1_EN_MOTOR0_BCK, 0xffffeffc
.equ TIMER_ADDR ,0x10002000
# Best values are 50k and 50k or 50k (on) and 75k(off) 
 .equ PERIOD_ON,     0xc350   #   0xc350  #50000
 .equ PERIOD_OFF,  0xc350      #0x124F8     #0x30D40 #200000

.equ TIMER_LOOP,   1  # 10
   movui r2, 4
   stwio r2, 4(r7)                          /* Start the timer without continuing or interrupts */

#----------------
# Lego Commands
#----------------
# The below is to allow quick copy pasting and editing of values for project
# 0xf (ab)  effff   # Load threshold data to sensor 3 as 5  (ab) => 1(010 1)011

# 0xfffeffff      # Enable sensor 3 and disable everything else 
# Depending on surface, threshold value would change
# Threshold value is the value of the sensors when the car is at the balanced position
# Threshold value for left sensor (Sensor 0):
 
# Threshold value for right sensor (Sensor 1): 
# Pseudocode:
# 1. Load sensor threshold to both Sensor 0 and Sensor 1
# 2. Initialize motor to rotate left
# 3. Poll for left Sensor0, once it crosses threshold and is valid
# 4. Motor rotate right
# 5. Poll for right Sensor1, once it crosses threshold and is valid
# 6. Motor rotate left
# 7. Repeat step 3-6 forever. 
# Note: Only allowed to use polling  (value) mode for this mode 
#-------------
# Registers
#-------------

# Caller 
#
#
#

#Callee

# r2 = Parameter to send in, Period ON
# r3 = Parameter to send in, Period OFF 
# r4 = Parameter to send in, N 

# r8 = Address of JP1 (Lego Controller)
# r9 = To initialize Lego Controller and use for storing values 
# r10 = Address of RED Leds (Displays sensor 1 value) 
# r11 = Address of GREEN Leds (Displays Sensor 2 value)
# r12 = Holds latest value of Sensor1
# r13 = Holds latest value of Sensor 2 
# r14 = Keeps track of direction of movement of motor  (Forward = 0, backward = 1) at bit 1 (note: Bits start from 0)
# r15 = To keep track of converted r14's value 
# r16 = Stores temporary value for computation of and 
#TIMER 
# r17 = Address of Timer 
# r18 = Stores number of times to LOOP timer 
# r19 = Store period value 
# r20 = r12 - r13 

.text
.global	main

main: 
	# Inialization of Red Leds, Lego Controller 
	movia sp, 0x20000 # Set stack pointer to some large address
	movia r17, TIMER_ADDR 
	movia r10, RED_LEDS
	movia r11, GREEN_LEDS
	movia r8, ADDR_JP1 # Note: Connect Lego Controller to JP1
	movia r9, LEGO_INITIALIZE 
	stwio r9, 4(r8) # Set motors to output, sensors to input 
	movia r18, TIMER_LOOP
	
	# Motor forward and & enable Sensor1 (located on right) 
	# Enable Sensor1, let motor0 run forward (left),
MOTOR0_FORWARD:
	movia r9, SENSOR1_EN_MOTOR0_FWD
RECALCULATE: 
	stwio r9, 0(r8)
	mov r14, r9  # Let r14 keep track of direction of motor	
	# Make sure motor is moving 
	mov r9, r14
	ori r9, r9, 0x00000001
	
# PWM_MOTOR
# Set parameters to send in
movia r2, PERIOD_ON # Also known as N 
movia r3, PERIOD_OFF
movia r4, TIMER_LOOP 
call TIMER 



# Loop starrts here 
CHECK_SENSOR1:
	# Make sure motor is started 
	mov r9, r14
	ori r9, r9, 0x00000001
	stwio r9, 0(r8) 
	# Initialize Sensor 1 and maintain's motor current direction 
	add r15, r0, r0 # clear r15
	movia r16, 0x00000003
	and r15, r14, r16 # Maintain motor direction and if it is on
	movia r9, 0xffffefff # Turn on Sensor 1 
	movi r16, 0xfffffffc
	and r9, r9, r16 # Erase the part for motor direction
	or r9, r9, r15
	stwio r9, 0(r8)
	
	
	# Check for valid data sensor 1
	ldwio r9, 0(r8) 
	srli r9, r9, 13 # bit 13 equals to valid bit for sensor 1
	movia r16, 0x00000001
	and r9, r9, r16
	bne r0, r9, CHECK_SENSOR1

STORE_SENSOR1:
	ldwio r12, 0(r8)
	srli r12, r12, 27
	movia r16, 0x0f
	and r12, r12, r16 # To get the last 4 bits 
	stwio r12, 0(r10) 

CHECK_SENSOR0:
	# Initialize Sensor 1 and maintain's motor current direction 
	add r15, r0, r0 # clear r9
	movia r16, 0x00000003
	and r15, r14, r16 # Maintain motor direction and if it is on
	movia r9, 0xfffffbff # Turn on Sensor 0 
	movi r16, 0xfffffffc
	and r9, r9, r16 # Erase the part for motor direction
	or r9, r9, r15
	stwio r9, 0(r8)
	ldwio r9, 0(r8) 
	srli r9, r9, 11 # bit 11 equals to valid bit for sensor 0
	movia r16, 0x1
	and r9, r9, r16
	bne r0, r9, CHECK_SENSOR0

STORE_SENSOR0:
	ldwio r13, 0(r8)
	srli r13, r13, 27
	movia r16, 0x0f
	and r13, r13, r16 # To get the last 4 bits 
	stwio r13, 0(r11)  # Store into Green LED 

COMPARE_SENSOR: 
	movia r18, TIMER_LOOP # Reset timer loop 
# 	Tolerance 
	sub r20, r13, r12 
	movia r21 , 2
	movia r22, -2
#	bge r20, r0, MOTOR0_FORWARD # If sensor 1 is higher than sensor 0 (implies sensor 1 is further from ground and sensor 0 is closer to ground)
	bge r20, r21, MOTOR0_FORWARD
	ble r20, r22, MOTOR0_BACKWARD
	
STOP_MOTOR:
	# Make sure motor is running 
	movia r9, SENSOR1_EN_MOTOR0_FWD
	mov r14, r9
	movia r9, 0x00000001 
    # Change motor direction
	xor r14, r14, r9 
	br CHECK_SENSOR1
	
MOTOR0_BACKWARD: 
	movia r9, SENSOR1_EN_MOTOR0_BCK 
	br RECALCULATE
	

TIMER:
	andi r9, r9, 0x1 # get first bit to know if motor is on or off
	bne r9, r0, SET_PERIOD_OFF
	add r19, r2, r0 # r2 is period on

TIMER_COUNTDOWN:
   # Set timer period value 
   mov r9, r19
   stwio r9, 8(r17)
#   movi r9, %hi(r19)
	srli r9, r9, 16
   stwio r9, 12(r17)
   # Start timer
   stwio r0, 0(r17) # Ensure timeout bit is 0 (it turns 1 when countdown ends)
   movi r9, 0x4 # Start timer, and stop timer when reaches 0, and cancel interrupt. 
   stwio r9, 4(r17)
 
POLL_TIMER: 
	ldwio r9, 0(r17)
	andi r9, r9, 1
	beq r9, r0, POLL_TIMER
  
REVERSE_STATE: # By xoring with 1 
	movia r9, 0x00000001 
    # Change motor direction
	xor r14, r14, r9 
	stwio r14, 0(r8)
	subi r4, r4, 1
	bne r4, r0, TIMER
	ret

	SET_PERIOD_OFF:
	add r19, r3, r0 # r3 is PERIOD_OFF
	br TIMER_COUNTDOWN 

	
#0xfabeffff  # Sensor value is 5, set threshold value for sensor 0 
.end


