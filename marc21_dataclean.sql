/*
INSTALL plpython3u - IT IS IMPORTANT TO ADD IN THE COMMAND LINE THE VERSION OF PLPYTHON AND OF PG
sudo apt-get install postgresql-plpython3-11

INTALL UNIDECODE
pip install unidecode
*/

CREATE TYPE tm_fecha AS (
	fecha1 integer, 
	fecha1q Varchar, 
	fecha2 integer, 
	fecha2q Varchar
);

CREATE OR REPLACE FUNCTION tm_cleandate(x text) 
/*
THIS FUNCTION AIMS TO CLEAN AND NORMALIZE DATES IN MARC21 DATA SCRAPPING
THE INPUT IS AN STRING CONTAINING A DATE
THE OUTPUT IS AN ARRAY OF ARRAYS WHERE EACH INNER ARRAY CONTAINS A FIRST ELEMENT WITH THE DATA AND SECOND WITRH THE QUALITY IN => D FOR DATE, Y FOR YEAR, C FOR CENTURY
*/
RETURNS tm_fecha
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
v = x
vOut = {'|||'}

if v != '|||':
if re.match(r'^.*[0-9]{4}-[0-9]{2}\b.*$', v):
    f = re.findall(r'([0-9]{4})-([0-9]{2})', v)[0]

    if int(f[0][2:4])<int(f[1]):
        v=f[0]+'-'+f[0][0:2]+f[1]
    elif int(f[0][0:2])<int(f[1]):
        v=f[0]+'-'+f[1]+'00'

vOut = []
v = v.split('-')
v = [x.lower() for x in v]
v = [x.replace('?', '') for x in v]
v = [x.strip() for x in v]

for i in list(range(len(v))):
    f = re.findall(r'([0-9]+)th.*cen.*', v[i])
    if len(f) > 0:
        for ff in f:
            vOut.append([f'{ff}00', 'century incomplete'])
        continue

    f = re.findall(r'([0-9]+)\s*a[\s.j]*c', v[i])
    if len(f) > 0:
        for ff in f:
            vOut.append([f'-{ff}', 'year'])
        continue

    if re.match(r'.*(s.|segle|sec.|siglo|century|siecle).*\b[mdclxvi]+\b.*', v[i]):
        f = re.findall(r'.*(s.|segle|sec.|siglo|century|siecle).*(\b[mdclxvi]+\b).*', v[i])[0]
        f = str(roman_to_int(f[1]))
        f = '-'+f if re.match(r'.*a[\s.j]*c\b.*', v[i]) else f
        vOut.append([f, 'century'])
        continue                

    if re.match(r'[\D]*[0-9]+[\D]*', v[i]):
        y = re.findall(r'[0-9]{3,4}', v[i])
        if len(y) > 0:
            vOut.append([y[0], 'year'])
            continue
        y = re.findall(r'[0-9]{2}', v[i])
        if len(y) > 0:
            vOut.append([y[0]+'00', 'century incomplete'])
            continue

if len(vOut) == 1:
    vOut = [vOut[0][0], vOut[0][1], '|||', '|||']

elif len(vOut) >= 2: 
    if vOut[1][0] < vOut[0][0]:
        vOut = [vOut[1][0], vOut[1][1], vOut[0][0], vOut[0][1]]
    else:
        vOut = [vOut[0][0], vOut[0][1], vOut[1][0], vOut[1][1]]

else:
    print('>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>')
    print(c, x)
    pass

return vOut
$$ LANGUAGE plpython3u;


CREATE OR REPLACE FUNCTION tmd_cleanlang(x text) 
/*
THIS FUNCTION AIMS TO CLEAN AND NORMALIZE LANGUAGES IN MARC21 DATA SCRAPPING
THE INPUT IS AN STRING CONTAINING A LANGUAGE
*/
RETURNS text
AS $$
import unidecode
import re
import Levenshtein as leven
from iso639 import languages

langs = sorted([l.name for l in languages])
langDict = {}
dataOut = []

l = l.lower().strip()
l = unidecode.unidecode(l)

langList.add(l)
l = re.split(r'\-|\&|\sy\s|\si\s|\,|\se\s|\=|\sand\s|\set\s|\su\.\s', l)

for ll in l:
lengCode = None

ll = re.sub(r'\W+', ' ', ll)
ll = re.sub(r'\s\s+', ' ', ll)
ll = ll.strip()

if re.match(r'^[\w]{3}$', ll):
    try:
        ll = languages.get(part2b=ll)
        lengCode = ll.part2b

    except:
        langDict[ll] = ''

elif ll.title() in langs:
    ll = languages.get(name=ll.title())
    lengCode = ll.part2b

elif any(x.title() in langs for x in ll.split(' ')):
    ll = list(set([x.title() for x in ll.split(' ') if x.title() in langs]))
    ll = ll[0]
    ll = languages.get(name=ll.title())
    lengCode = ll.part2b
    
elif ll == 'span':
    ll = languages.get(name='Spanish')
    lengCode = ll.part2b
    
elif ll == 'engl':
    ll = languages.get(name='English')
    lengCode = ll.part2b
    
elif ll == 'arabe':
    ll = languages.get(name='Arabic')
    lengCode = ll.part2b

elif sorted([leven.distance(ll.title(), x) for x in langs])[0] < 2:
    lang = [x for x in langs if leven.distance(ll.title(), x) < 2][0]
    ll = languages.get(name=lang)
    lengCode = ll.part2b

else:
    langDict[ll] = ''
    
dataOut.append(lengCode)

dataOut = [x for x in dataOut if x and x != '']
d1 = dataOut[0] if len(dataOut) > 0 else None
d2 = dataOut[1] if len(dataOut) > 1 else None
dataOut = {'l1': d1, 'l2': d2}
#     print(dataOut)
    
if exp_dict:
listDict = [{'nom': x, 'nom_c': ''} for x in sorted(langDict.keys())]
listDict = [{'nom': x, 'nom_c':languages.get(name=x).part2b} for x in langs if languages.get(name=x).part2b != ''] + listDict
dfLangDict = pd.DataFrame(listDict)
dfLangDict.to_sql('lang_dict', con = PG_CON, schema = 'data_in', if_exists = 'append', index = False)

return dataOut
$$ LANGUAGE plpython3u;
