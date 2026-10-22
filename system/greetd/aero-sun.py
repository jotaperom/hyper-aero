import math
import time
import datetime

LAT, LON = __LAT__, __LON__


def sun_times(day):
    n = day.timetuple().tm_yday
    g = 2 * math.pi / 365 * (n - 1)
    eqtime = 229.18 * (0.000075 + 0.001868 * math.cos(g) - 0.032077 * math.sin(g)
                       - 0.014615 * math.cos(2 * g) - 0.040849 * math.sin(2 * g))
    decl = (0.006918 - 0.399912 * math.cos(g) + 0.070257 * math.sin(g) - 0.006758 * math.cos(2 * g)
            + 0.000907 * math.sin(2 * g) - 0.002697 * math.cos(3 * g) + 0.00148 * math.sin(3 * g))
    phi = math.radians(LAT)
    x = math.cos(math.radians(90.833)) / (math.cos(phi) * math.cos(decl)) - math.tan(phi) * math.tan(decl)
    ha = math.degrees(math.acos(max(-1.0, min(1.0, x))))
    midnight = datetime.datetime(day.year, day.month, day.day, tzinfo=datetime.timezone.utc).timestamp()
    return midnight + (720 - 4 * (LON + ha) - eqtime) * 60, midnight + (720 - 4 * (LON - ha) - eqtime) * 60


now = time.time()
sunrise, sunset = sun_times(datetime.datetime.fromtimestamp(now).date())
print("day" if sunrise <= now < sunset else "night")
