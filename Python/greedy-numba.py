import copy
import math 
import string
import sys
import timeit
from numba import double
from numba.decorators import jit, autojit


class Activity:
	id = ""
	lat = 0.0
	lon = 0.0

	def __init__(self, id, lat, lon):
		self.id = id
		self.lat = lat
		self.lon = lon

class Resource:
	id = ""
	lat = 0.0
	lon = 0.0

	def __init__(self, id, lat, lon):
		self.id = id
		self.lat = lat
		self.lon = lon

class Allocation:
	rid = ""
	aid = ""
	dist = 0.0

	def __init__(self, rid, aid, dist):
		self.rid = rid
		self.aid = aid
		self.dist = dist

class SchemaData:
	activity = [] 
	resource = [] 
	allocation = [] 

class Greedy(object):

	earthRadiusM = 6367450.0
	convert2Rad = math.pi / 180.0
	convert2Deg = 180.0 / math.pi
	seconds_per_metre = 0.0559234073

	@autojit()
	def distanceBetweenPointsLatLong(self, lat1, lon1, lat2, lon2):
		dStartLatInRad = lat1 * self.convert2Rad
		dStartLongInRad = lon1 * self.convert2Rad
		dEndLatInRad = lat2 * self.convert2Rad
		dEndLongInRad = lon2 * self.convert2Rad
		dLongitude = dEndLongInRad - dStartLongInRad
		dLatitude = dEndLatInRad - dStartLatInRad
		dSinHalfLatitude = math.sin(dLatitude * 0.5)
		dSinHalfLongitude = math.sin(dLongitude * 0.5)
		a = dSinHalfLatitude * dSinHalfLatitude + math.cos(dStartLatInRad) * math.cos(dEndLatInRad) * dSinHalfLongitude * dSinHalfLongitude
		c = math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
		return self.earthRadiusM * (c + c)

	def scheduleResources(self, sd):
		for res in sd.resource:
			for c in range(0, 50):
				lowest = sys.float_info.max
				lowestact = None
				for act in sd.activity:
					dist = self.distanceBetweenPointsLatLong(res.lat, res.lon, act.lat, act.lon)
					if dist < lowest:
						lowest = dist
						lowestact = act 
				sd.allocation.append(Allocation(res.id, lowestact.id, lowest))
				sd.activity.remove(lowestact)

a = []
r = []
#f = open('/Users/daryl/Development/Projects/FunctionalComparison/Data/DataSPIF.csv', 'r')
f = open('D:/Development/FunctionalComparison/Data/DataSPIF.csv', 'r')
for line in f:
	items = line.split(',')
	if len(items) == 3:
		r.append(Resource(items[0], float(items[1]), float(items[2])))
	else:
		a.append(Resource(items[0], float(items[1]), float(items[2])))

def go():
	gp = Greedy()
	for i in range(0, 100):
		sdi = SchemaData()
		sdi.resource = copy.deepcopy(r)
		sdi.activity = copy.deepcopy(a)
		sdi.allocation = []
		gp.scheduleResources(sdi)
		total = 0.0
		for j in sdi.allocation:
			total += j.dist 
		print "%d:%f" % (i, total)

timeit(go())