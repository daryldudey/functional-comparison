package main

import (
	"fmt"
	"io/ioutil"
	"math"
	"strconv"
	"strings"
)

type Activity struct {
	id  string
	lat float64
	lon float64
}

type Resource struct {
	id  string
	lat float64
	lon float64
}

type Allocation struct {
	rid  string
	aid  string
	dist float64
}

type SchemaData struct {
	activity   map[string]Activity
	resource   []Resource
	allocation []Allocation
}

const earthRadiusM float64 = 6367450
const convert2Rad float64 = math.Pi / 180.0

func distanceBetweenPointsLatLong(lat1 float64, lon1 float64, lat2 float64, lon2 float64) float64 {
	dStartLatInRad := lat1 * convert2Rad
	dStartLongInRad := lon1 * convert2Rad
	dEndLatInRad := lat2 * convert2Rad
	dEndLongInRad := lon2 * convert2Rad
	dLongitude := dEndLongInRad - dStartLongInRad
	dLatitude := dEndLatInRad - dStartLatInRad
	dSinHalfLatitude := math.Sin(dLatitude * 0.5)
	dSinHalfLongitude := math.Sin(dLongitude * 0.5)
	a := dSinHalfLatitude*dSinHalfLatitude + math.Cos(dStartLatInRad)*math.Cos(dEndLatInRad)*dSinHalfLongitude*dSinHalfLongitude
	c := math.Atan2(math.Sqrt(a), math.Sqrt(1.0-a))
	return earthRadiusM * (c + c)
}

func scheduleResources(sd *SchemaData) {
	for _, res := range sd.resource {
		for c := 0; c < 50; c++ {
			lowest := math.Inf(0)
			lowestid := ""
			for xact, act := range sd.activity {
				dist := distanceBetweenPointsLatLong(res.lat, res.lon, act.lat, act.lon)
				if dist < lowest {
					lowest = dist
					lowestid = xact
				}
			}
			a := Allocation{rid: res.id, aid: lowestid, dist: lowest}
			sd.allocation = append(sd.allocation, a)
			delete(sd.activity, lowestid)
		}
	}
}

func build(lines []string) SchemaData {
	sd := SchemaData{}
	sd.activity = map[string]Activity{}
	sd.resource = []Resource{}
	for _, line := range lines {
		if len(line) > 0 {
			split := strings.Split(line, ",")
			lat, _ := strconv.ParseFloat(split[1], 64)
			lon, _ := strconv.ParseFloat(split[2], 64)
			switch len(split) {
			case 3:
				r := Resource{id: split[0], lat: lat, lon: lon}
				sd.resource = append(sd.resource, r)
			case 4:
				a := Activity{id: split[0], lat: lat, lon: lon}
				sd.activity[a.id] = a
			}
		}
	}
	return sd
}

func main() {
	content, err := ioutil.ReadFile("../Data/DataSPIF.csv")
	if err != nil {
		fmt.Println("Error opening file")
	}
	lines := strings.Split(string(content), "\n")
	sd := build(lines)
	for i := 0; i < 100; i++ {
		sdi := SchemaData{}
		sdi.activity = map[string]Activity{}
		for k, v := range sd.activity {
			sdi.activity[k] = v
		}
		sdi.resource = sd.resource
		sdi.allocation = []Allocation{}
		scheduleResources(&sdi)
		sum := 0.0
		for _, alloc := range sdi.allocation {
			sum += alloc.dist
		}
		fmt.Printf("%d : %f\n", i, sum)
	}
}
