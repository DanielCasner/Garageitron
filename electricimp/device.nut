/// Garage door (plus a few other things) control agent
// @author Daniel Casner www.danielcasner.org


door <- hardware.pin1;
monitor <- hardware.pin8;
door.configure(ANALOG_OUT);
door.write(0); // Not active
monitor.configure(ANALOG_IN);

monitorOut <- OutputPort("Monitor out");

class BiColor {
    s1 = null;
    s2 = null;
    
    constructor(pin1, pin2) {
        s1 = pin1;
        s2 = pin2;
        s1.configure(DIGITAL_OUT);
        s1.write(0);
        s2.configure(DIGITAL_OUT);
        s2.write(0);
    }
    
    function red() {
        s1.write(1);
        s2.write(0);
    }
    
    function green() {
        s1.write(0);
        s2.write(1);
    }
    
    function black() {
        s1.write(0);
        s2.write(0);
    }
}

led <- BiColor(hardware.pin7, hardware.pin9);


function doorDone() {
    door.write(0);
}

agent.on("door", function(arg) {
    server.log("Door commanded");
    door.write(1.0); // Short circuit
    imp.wakeup(0.2, doorDone);
});

agent.on("light", function(arg) {
    server.log("Light commanded");
    // Servo voltage to correct value
    local servo = 0.000;
    while ((monitor.read() > 4000) && (servo < 0.99)) {
        servo = servo + 0.001;
        door.write(servo);
        //server.log("  servo = " + servo + "  monitor = " + monitor.read());
        //imp.sleep(0.001);
    }
    server.log("  servo done");
    imp.wakeup(0.2, doorDone);
});

agent.on("led", function(arg) {
    switch (arg) {
    case 0:
        led.black();
        break;
    case 1:
        led.red();
        break;
    case 2:
        led.green()
        break;
    default:
        server.log("Invalid argument from agent for 'led' command:" + arg);
    }
});

lastVal <- 0;

function mainPoll() {
    local newVal = monitor.read();
    //server.log("Monitor: " + newVal);
    if ((newVal - lastVal) > 1000 || (lastVal - newVal) > 1000) {
        server.log("Monitor change: " + lastVal + " -> " + newVal);
        monitorOut.set(newVal);
    }
    lastVal = newVal;
    imp.wakeup(0.1, mainPoll);
}



imp.configure("Garageitron", [], [monitorOut]);
server.log("Configured :-)");
imp.wakeup(0.1, mainPoll);
