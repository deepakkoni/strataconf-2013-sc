"""properties of the person"""
from gemini.extractor.base import Extractor

import re

class NumBodyMarks(Extractor):
    schema = "int"
    requires = ()
    def extract(self, record, already=None):
        marks = record['profile'].get('BodyMarks', "")
        return len(marks.split(';'))

class HasTattoo(Extractor):
    schema = 'boolean'
    requires = ()
    tattoo_pattern = re.compile(r'\bTAT(TOO)?\b')
    def extract(self, record, already=None):
        marks = record['profile'].get('BodyMarks', "")
        return bool(self.tattoo_pattern.search(marks))


class IsMale(Extractor):
    schema = 'boolean'
    requires = ()
    def extract(self, record, already=None):
        return record['profile'].get('Gender') == 'm'

class HairColor(Extractor):
    normalizer = {
        'bro': 'brown',
        'blk': 'black',
        'bln': 'blond',
        'gry': 'gray',
        'grey': 'gray',
        }
    schema = {'type': 'enum', 'name': 'HairColors',
              'symbols': ('black', 'brown', 'gray', 'blond', 'red',
                          'other', 'unknown')}
    requires = ()
    def extract(self, record, already=None):
        recorded = record['profile'].get('HairColor', None)
        if recorded is None:
            return 'unknown'
        recorded = recorded.lower()
        if recorded in self.normalizer:
            recorded = self.normalizer[recorded]
        for i in self.schema['symbols']:
            if recorded.startswith(i):
                recorded = i
                break
        if recorded in self.schema['symbols']:
            return recorded
        else:
            return 'other'

class EyeColor(Extractor):
    normalizer = {
        'bro': 'brown',
        'blu': 'blue',
        'blk': 'black',
        'hzl': 'hazel',
        'haz': 'hazel',
        'grn': 'green',
        }
    schema = {'type': 'enum',  'name': 'EyeColors',
              'symbols': ('black', 'brown', 'hazel', 'blue', 'green',
                          'other', 'unknown')}
    requires = ()
    def extract(self, record, already=None):
        recorded = record['profile'].get('EyeColor', None)
        if recorded is None:
            return 'unknown'
        recorded = recorded.lower()
        if recorded in self.normalizer:
            recorded = self.normalizer[recorded]
        for i in self.schema['symbols']:
            if recorded.startswith(i):
                recorded = i
        if recorded in self.schema['symbols']:
            return recorded
        else:
            return 'other'

class SkinColor(Extractor):
    normalizer = {
        'drk': 'dark',
        'blk': 'dark',
        'lbr': 'light',
        'dbr': 'dark',
        'far': 'fair', # ?
        'olive': 'medium',
        'mbr': 'medium',
        'olv': 'medium',
        'rud': 'light',
        'ruddy': 'light',
        'fair': 'light',
        'freckled': 'light',
        'unk': 'unknown',
        }
    schema = {'type': 'enum', 'name': 'SkinColors',
              'symbols': ('dark', 'light', 'medium', 
                          'other', 'unknown')}
    requires = ()
    def extract(self, record, already=None):
        recorded = record['profile'].get('SkinColor', None)
        if recorded is None:
            return 'unknown'
        recorded = recorded.lower()
        if recorded in self.normalizer:
            recorded = self.normalizer[recorded]

        for i in self.schema['symbols']:
            if recorded.startswith(i):
                recorded = i
                break
        if recorded.startswith('fair'):
            recorded = 'light'
        elif recorded.startswith('black'):
            recorded = 'dark'
            
        if recorded in self.schema['symbols']:
            return recorded
        else:
            return 'other'

