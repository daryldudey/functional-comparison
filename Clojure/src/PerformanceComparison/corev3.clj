(ns PerformanceComparison.corev3
  (:gen-class)
  (:use [clojure.java.io]
        [clojure.algo.generic.math-functions]
        [clojure.core.memoize])
  (:require [clojure.string :as string]
            [taoensso.timbre.profiling :as profiling :refer (p profile)]))

(set! *warn-on-reflection* true)
(set! *unchecked-math* true)

(defrecord Activity [#^String id ^double lat ^double lng])
(defrecord Resource [#^String id ^double lat ^double lng])
(defrecord Allocation [#^String resource-id #^String activity-id ^double distance])
(defrecord SchemaData [activities resources])

(def ^:const earth-radius 6367450.0)
(def ^:const convert-to-rad (/ (. Math PI) 180.0))
(def ^:const convert-to-deg (/ 180.0 (. Math PI)))

(defn distance-between-points-lat-long ^double [^double lat1 ^double lon1 ^double lat2 ^double lon2]
  (let [dStartLatInRad ^double (p :c1 (* lat1 convert-to-rad))
        dStartLongInRad ^double (p :c2 (* lon1 convert-to-rad))
        dEndLatInRad ^double (p :c3 (* lat2 convert-to-rad))
        dEndLongInRad ^double (p :c4 (* lon2 convert-to-rad))
        dLongitude ^double (p :c5 (- dEndLongInRad dStartLongInRad))
        dLatitude ^double (p :c6 (- dEndLatInRad dStartLatInRad))
        dSinHalfLatitude ^double (p :c7 (sin (* dLatitude 0.5)))
        dSinHalfLongitude ^double (p :c8 (sin (* dLongitude 0.5)))
        a ^double (p :c9 (+ (* dSinHalfLatitude dSinHalfLatitude) (* (cos dStartLatInRad) (cos dEndLatInRad) dSinHalfLongitude dSinHalfLongitude)))
        c ^double (p :c10 (atan2 (sqrt a) (sqrt (- 1.0 a))))]
    (p :ce (* earth-radius (+ c c)))))

(defn schedule [r c activities resources allocations]
  (if (zero? c)
    (if (zero? (count resources)) 
      allocations
      (recur (first resources) 50 activities (rest resources) allocations))
    (do
      (let [aid-dist-unsorted (p :aid-unsorted (map #(list (:id %) (distance-between-points-lat-long (:lat %) (:lng %) (:lat r) (:lng r))) (vals activities)))

            ;; The sort-by is too slow. Use reduce to figure out the lowest
            aid-dist (p :aid-reduce (reduce #(if (< (second %1) (second %2)) %1 %2) aid-dist-unsorted))]

            ;; Old sort, so slow
;            aid-sorted (p :aid-sorted (sort-by second aid-dist-unsorted))
;            aid-dist (p :aid-first (first aid-sorted-reduce))]
        (let [new-allocation (p :new-allocation (Allocation. (:id r) (first aid-dist) (second aid-dist)))
              activities (p :activities (dissoc activities (first aid-dist)))
              allocations (p :allocation (conj allocations new-allocation))]
          (recur r (dec c) activities resources allocations))))))

(defn import-csv [csv]
  (loop [data csv sd (SchemaData. {} ())]
    (if-not (seq data)
      sd
      (do
        (let [f (first data) s (count f)]
          (let [sd-updated 
            (cond
              (= s 4) (let [a (Activity. (first f) (Double/parseDouble (second f)) (Double/parseDouble (nth f 2)))]
                        (update-in sd [:activities] assoc (first f) a))
              (= s 3) (let [r (Resource. (first f) (Double/parseDouble (second f)) (Double/parseDouble (nth f 2)))]
                        (update-in sd [:resources] conj r)))]
            (recur (rest data) sd-updated)))))))

(defn run []
  (with-open [rdr (reader "/Users/daryl/Development/Projects/FunctionalComparison/Data/DataSPIF.csv")]
    (let [csv (for [line (line-seq rdr)]
                (string/split line #","))]
      (let [sd (p :import (import-csv csv))
            activities (:activities sd)
            resources (rest (:resources sd))]
        (loop [countloop 5]
          (if (zero? countloop)
            0
            (let [allocations []
                  alloc (p :alloc (map #(:distance %) (schedule (first (:resources sd)) 50 activities resources allocations)))
                  total (p :reduce (reduce + alloc))]
              (p :print (println countloop ":" total))
            (recur (dec countloop)))))))))

(defn -main []
  (profile :info :Arithmetic (run)))
;;  (run))

