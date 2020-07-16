/*
INSTALL plpython3u - IT IS IMPORTANT TO ADD IN THE COMMAND LINE THE VERSION OF PLPYTHON AND OF PG
sudo apt-get install postgresql-plpython3-11

INTALL UNIDECODE
pip install unidecode
*/

CREATE OR REPLACE FUNCTION tmd_cleandate(x text) 
/*
THIS FUNCTION AIMS TO CLEAN AND NORMALIZE DATES IN MARC21 DATA SCRAPPING
THE INPUT IS AN STRING CONTAINING A DATE
THE OUTPUT IS AN ARRAY OF ARRAYS WHERE EACH INNER ARRAY CONTAINS A FIRST ELEMENT WITH THE DATA AND SECOND WITRH THE QUALITY IN => D FOR DATE, Y FOR YEAR, C FOR CENTURY
*/
RETURNS text
AS $$
import re
import unidecode

def int_to_roman(input):
    """ Convert an integer to a Roman numeral. """

    if not isinstance(input, type(1)):
        raise (TypeError, "expected integer, got %s" % type(input))
    if not 0 < input < 4000:
        raise (ValueError, "Argument must be between 1 and 3999")
    ints = (1000, 900,  500, 400, 100,  90, 50,  40, 10,  9,   5,  4,   1)
    nums = ('M',  'CM', 'D', 'CD','C', 'XC','L','XL','X','IX','V','IV','I')
    result = []
    for i in range(len(ints)):
        count = int(input / ints[i])
        result.append(nums[i] * count)
        input -= ints[i] * count
    return ''.join(result)
	
def roman_to_int(input):
    """ Convert a Roman numeral to an integer. """

    if not isinstance(input, type("")):
        raise TypeError#, "expected string, got %s" % type(input)
    input = input.upper(  )
    nums = {'M':1000, 'D':500, 'C':100, 'L':50, 'X':10, 'V':5, 'I':1}
    sum = 0
    for i in range(len(input)):
        try:
            value = nums[input[i]]
            # If the next place holds a larger number, this value is negative
            if i+1 < len(input) and nums[input[i+1]] > value:
                sum -= value
            else: sum += value
        except KeyError:
            raise (ValueError, 'input is not a valid Roman numeral: %s' % input)
    # easiest test for validity...
    if int_to_roman(sum) == input:
        return sum*100-100
    else:
#         raise (ValueError, 'input is not a valid Roman numeral: %s' % input)
        return None

global x
vOut = x

if x != '|||':
	vOut = []
	v = x.split('-')
	v = [x.lower() for x in v]
	v = [x.replace('?', '') for x in v]
	v = [x.strip() for x in v]

	for i in list(range(len(v))):
		f = re.findall(r'([0-9]+)th.*cen.*', v[i])
		if len(f) > 0:
			for ff in f:
				vOut.append(f'{ff}00')
			continue

		f = re.findall(r'([0-9]+)\s*a[\s.j]*c', v[i])
		if len(f) > 0:
			for ff in f:
				vOut.append(f'-{ff}')
			continue

		if re.match(r'.*(s.|segle|sec.|siglo|century|siecle).*\b[mdclxvi]+\b.*', v[i]):
			f = re.findall(r'.*(s.|segle|sec.|siglo|century|siecle).*(\b[mdclxvi]+\b).*', v[i])[0]
			f = str(roman_to_int(f[1]))
			f = '-'+f if re.match(r'.*a[\s.j]*c\b.*', v[i]) else f
			vOut.append(f)
			continue

		if re.match(r'[\D]*[0-9]+[\D]*', v[i]):
			vOut.append(re.findall(r'[0-9]+', v[i])[0])
			continue
		
		try:
			vOut = vOut if len(vOut) == 1 else ['-'+vOut[0], vOut[1]] if int(vOut[0]) > int(vOut[1]) else [vOut[0], vOut[1]]
			vOut = [int(x) for x in vOut]
		except:
			print(x, vOut)

return vOut
$$ LANGUAGE plpython3u;
