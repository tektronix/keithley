# Server_Side.py
import socket                               # Import socket module
import sys
import os.path
import operator
import time


def write_data_to_file(output_data_path, dataStr):
    # This function writes the string data to the
    # target file.
    ofile = open(output_data_path, "a")  # append the target data
    dataStr = "{0}\n".format(dataStr)
    ofile.write(dataStr)

    ofile.close()  # Close the data file.
    return

# ================================================================================
#    MAIN CODE STARTS HERE
# ================================================================================
serverIpAddress = '192.168.1.14'            #socket.gethostnam # Get local machine name
serverPort = 60000                          # Define the port to which the client 
					    # will use

# Create socket object for the server
serverSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
serverSocket.bind((serverIpAddress, serverPort))

serverSocket.listen(5)                      # Enable our server to accept up to 5 
                                            # connections before refusing new 
					    # connections

print ('Server listening...')
print (socket.gethostbyname(socket.gethostname()))

while True:
    clientSocket, addr = serverSocket.accept()     	# Establish connection with 
													# client.
    print("Got connection from {0}".format(addr))

    # The first transimission as part of the TSP connect will be the instrument 
    # file name that will be written to during data transmission.
    filename = clientSocket.recv(1024).decode()

    # Subsequent writes will contain a string of data which will be written to 
    # the file until the sender issues a "done" string.
    data_to_write = clientSocket.recv(1024).decode()
    while (data_to_write):
        print(data_to_write.rstrip())
        if(data_to_write.__contains__("done")):
            break
        write_data_to_file(filename, data_to_write.rstrip())
        data_to_write = clientSocket.recv(1024).decode()

	# Close the active client connection to allow for other incoming connections
	# to be made. 
    clientSocket.close()
    print("Closed connection...")

# We can close the server socket, but have the option to leave open and
# run indefinitely so it is always listening for incoming connections
# and data.
serverSocket.close()
