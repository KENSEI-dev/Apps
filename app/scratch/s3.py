import math
def haversine_m(lat1, lng1, lat2, lng2):
    R=6371000
    p1,p2=math.radians(lat1), math.radians(lat2)
    dp=math.radians(lat2 - lat1)
    d1=math.radians(lng2 -lng1)
    a=math.sin(dp/2)**2+math.cos(p2)*math.cos(p2)*math.sin(d1/2)**2
    return 2*R*math.asin(math.sqrt(a))
if __name__=="__main__":
    print(haversine_m(22.5851, 88.3486, 22.5448, 88.3426))
    print(haversine_m(22.5, 88.3, 22.5, 88.3))