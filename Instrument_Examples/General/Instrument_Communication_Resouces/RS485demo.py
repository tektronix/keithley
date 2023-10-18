"""
    This example shows how a user might leverage the serial package to
    perform RS485 communications to different devices or instruments where
    the protocol is needed such as in cases where there is a need to control
    an environmental or temperature chamber.
"""

import serial

def crc_8(message_list):
    """
    Calculates CRC check following the CRC-MODBUS16 method.

    Params:
        message_list - A bytearray to calculate CRC
    Returns:
        x - Returns CRC check calculation
    """

    x = 0xFFFF
    for data in message_list:
        x = data ^ x
        for _ in range(8):
            x , carry_bit = x >> 1, x & 1

            if carry_bit == 1:
                x = x ^ 0xA001
    return x

def bytes(integer):
    """
    This function accepts an integer value representative of an expected
    or known byte count then returns the quotient and remainder of the
    devision operation performed. 

    Params:
        integer - The integer value to be used in the division. 
    Returns:
        This function returns the quotient and remainder terms from
        the division operation performed by divmod().
    """
    return divmod(integer, 0x100)


def send_rs485(message_list, com_port: str, baud_rate: int , par_bit: str, byte_size: int, stop_bits: int, time_out: float):
    """
    Sends desired bytearray message through desired RS-485 COM port.

    Params:
        message_list: bytearray of the command to send
        com_port: string of the com port name, example: 'COM4'
        baud_rate: baud rate setting for RS-485 e.g: 9600
        par_bit: parity bit settings
        byte_size: bite size for message
        stop_bits: stop bits
        time_out: timeout time in seconds
    Returns:
        returns the bytearray of the device response and the CRC check
        calculated from the first 6 bits if you wish to confirm the message
    """

    msg = bytearray(message_list)
    crc_int = crc_8(message_list)
    crcLSB = crc_int & 0xFF
    crcMSB = (crc_int & 0xFF00) >> 8
    msg.append(crcLSB)
    msg.append(crcMSB)
    ser = serial.Serial(com_port,
                        baudrate=baud_rate,
                        parity=par_bit,
                        bytesize=byte_size,
                        stopbits=stop_bits,
                        timeout=time_out)

    ser.write(msg)

    msg_reply = ser.read(100)
    reply_list = [msg_reply[i] for i in range (0, len(msg_reply))]

    try:
        ser.close()
        crc_reply = crc_8(reply_list[:len(reply_list) - 2])
        crcr_LSB = crc_reply & 0xFF
        crcr_MSB = (crc_reply & 0xFF00) >> 8
        crcr_list = [crcr_LSB, crcr_MSB]
        return reply_list, crcr_list
    except:
        ser.close()
        return -1

def main():
    com_port = "COM3"   #assign the COM port of the device
    adr_code = 0x01     #example MODBUS command, can be an ASCII string as well
    fc_code = 0x03
    start_adrh = 0x00
    start_adrl = 0x00
    datal_h = 0x00
    datal_l = 0x02

    msg = bytearray([adr_code,fc_code,start_adrh,start_adrl,datal_h,datal_l])

    reply_raw, crc_check = send_rs485(msg, com_port, 9600, 'N', 8, 1, 0.1)
    reply_int = [int(bit) for bit in reply_raw]
    print(reply_int)   #reply from RS485 device

if __name__ == "__main__":
    main()