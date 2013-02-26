from gemini.extractor.base import Extractor

class NumOffenses(Extractor):
    schema = "int"
    requires = ()
    def extract(self, record, already=None):
        return len(record['offenses'])

def offense_classes (offenses):
    return filter(None, [i.get('OffenseClass', None) for i in offenses])
        
class OnlyTraffic(Extractor):
    """true if only minors are traffic offenses"""
    schema = "boolean"
    requires = ()
    def extract(self, record, already=None):
        non_traffic = filter(lambda x: x not in ('STV', 'TV'),
                             offense_classes(record['offenses']))
        return not len(non_traffic)

