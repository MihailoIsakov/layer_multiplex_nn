
def generate_coe(path, memory, radix=16, bytes_per_row=8, bits_per_value=2):
    f = open(path, 'w')

    f.write(";Logsig function, for values between -8 and 8 returns values between 0 and 1.\n")
    f.write(";Value -8 will have index 0, value 8 will have index 1024.\n")
    f.write("memory_initialization_radix = " + str(radix) + ";\n")
    f.write("memory_initialization_vector = \n")

    hex_format = "0" + str(bits_per_value) + "x"

    row_counter = 0
    for cell in memory:
        assert 0 <= cell 
        f.write(format(cell, hex_format) + " ")

        row_counter += 1
        if row_counter == bytes_per_row:
            f.write("\n")
            row_counter = 0





