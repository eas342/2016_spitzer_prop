from astropy.io import ascii

def make_tex():
    """
    Makes a table from the AOR file.
    First run perl disintegrating.aor to get a parsed file.
    """
    
    tb = ascii.read('disintegrating_parsed.txt')
    
    tb.write('aor_table.tex')
