%v = visa('ni', 'USB0::0x05E6::0x6510::04340543::INSTR');
v = instrfind('Type', 'visa-usb', 'RsrcName', 'TCPIP0::***::inst0::INSTRUSB0::0x05E6::0x6510::04340543::INSTR', 'Tag', '');
if isempty(v)
    v = visa('ni', 'TCPIP0::192.168.1.165::inst0::INSTR');
else
    fclose(v);
    v = v(1);
end

fopen(v);
data = query(v, '*IDN?');
%fprintf(v, '*IDN?\n');
%data = fscanf(v);
fprintf('instrument = %s', data);
fprintf(v, 'beeper.beep(1, 1000)');

fprintf(v, 'reset()');
fprintf(v, '*cls');
fprintf(v, 'defbuffer1.clear()');
fprintf(v, 'defbuffer1.fillmode = buffer.FILL_CONTINUOUS');
fprintf(v, 'channel.open("slot1")');

% Establish channel settings for the scan card configuration...
fprintf(v, 'channel.setdmm("101:102", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_DC_VOLTAGE)');
fprintf(v, 'channel.setdmm("103:104", dmm.ATTR_MEAS_FUNCTION, dmm.FUNC_RESISTANCE)');
fprintf(v, 'channel.setdmm("101:104", dmm.ATTR_MEAS_RANGE_AUTO, dmm.ON)');
fprintf(v, 'channel.setdmm("101:104", dmm.ATTR_MEAS_AUTO_ZERO, dmm.ON)');
fprintf(v, 'channel.setdmm("101:104", dmm.ATTR_MEAS_DIGITS, dmm.DIGITS_4_5)');
fprintf(v, 'channel.setdmm("101:104", dmm.ATTR_MEAS_NPLC, 1.0)\n');

% Apply custom labels to each channel for better UI feedback
fprintf(v, 'channel.setlabel("101", "DCV1")');
fprintf(v, 'channel.setlabel("102", "DCV2")');
fprintf(v, 'channel.setlabel("103", "RES1")');
fprintf(v, 'channel.setlabel("104", "RES2")');
fprintf(v, 'display.watchchannels = "101:104"');
fprintf(v, 'display.changescreen(display.SCREEN_SCAN_SWIPE)');

% Generate the scan...
fprintf(v, 'scan.create("101:104")');
scanCnt = 100;
myDelay = 0.5;
fprintf(v, 'scan.scancount = %d', scanCnt);
fprintf(v, 'scan.scaninterval = %d', myDelay);

% Start the scan and wait...
fprintf(v, 'trigger.model.initiate()');

chanCount = 4;
startIndex = 1;
endIndex = chanCount;
targetCnt = scanCnt * chanCount;
rdgsCaptured = 0;
looper = 1;
while (endIndex ~= targetCnt)
    fprintf(v, 'statsVar = buffer.getstats(defbuffer1)');
    data = query(v, 'print(statsVar.n)');
    statsVar = int16(str2double(data));
    %fprintf('%d\n', data);
    
    while (statsVar - rdgsCaptured) < chanCount
        pause(myDelay);
        fprintf(v, 'statsVar = buffer.getstats(defbuffer1)');
        data = query(v, 'print(statsVar.n)');
        statsVar = int16(str2double(data));
        %fprintf('%d\n', data);
    end
    %fprintf('%d\n', looper);
    looper = looper + 1;
    % Extract the data...
    sndBuffer = sprintf('printbuffer(%d, %d, defbuffer1)', startIndex, endIndex);
    rcvBuffer = query(v, sndBuffer);
    fprintf('%s', rcvBuffer);
    rcvBuffer = "";
	startIndex = startIndex + chanCount;
	endIndex = endIndex + chanCount;
	rdgsCaptured = rdgsCaptured + chanCount;
end

%printf('%s', data);
fclose(v);
delete(v);
clear v;

