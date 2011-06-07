#ifndef __BASE_ANGLE_HH__
#define __BASE_ANGLE_HH__

#include <boost/format.hpp>
#include <math.h>

namespace base
{

/** 
 * This class represents an angle, and can be used instead of double for
 * convenience. The class has a canonical representation of the angle in
 * degrees, in the interval PI < rad <= PI. 
 */
class Angle
{
public:
    /** 
     * angle in radians.
     * this value will always be PI < rad <= PI
     *
     * @note don't use this value directly. It's only public to allow this class
     * to be used as an interface type.
     */
    double rad;

    /** 
     * default constructor, which will leave the angle uninitialized.
     */
    Angle() {}
    
protected:
    explicit Angle( double rad ) : rad(rad) 
    { 
	canonize(); 
    }

    void canonize()
    {
	if( rad > M_PI || rad <= -M_PI )
	{
	    double intp;
	    const double side = copysign(M_PI,rad);
	    rad = -side + 2*M_PI * modf( (rad-side) / (2*M_PI), &intp ); 
	}
    }

public:
    /**
     * static conversion from radians to degree
     * @param rad angle in radians
     * @result angle in degree
     */
    static inline double rad2Deg( double rad )
    {
	return rad / M_PI * 180.0;
    }

    /**
     * static conversion from degree to radians
     * @param deg angle in degree
     * @result angle in radians
     */
    static inline double deg2Rad( double deg )
    {
	return deg / 180.0 * M_PI;
    }

    /** 
     * use this method to get an angle from radians.
     * @return representation of the given angle.
     * @param rad - angle in radians.
     */
    static inline Angle fromRad( double rad )
    {
	return Angle( rad );
    }

    /** 
     * use this method to get an angle from degrees.
     * @return representation of the given angle.
     * @param deg - angle in degrees.
     */
    static inline Angle fromDeg( double deg )
    {
	return Angle( deg / 180.0 * M_PI );
    }

    /**
     * @return canonical value of the angle in radians
     */
    double inline getRad() const 
    {
	return rad;
    }

    /**
     * @return canonical value of the angle in degrees
     */
    double inline getDeg() const
    {
	return rad / M_PI * 180;
    }

    /**
     * compare two angles for approximate equality
     * @param other - angle to compare
     * @param prec - precision interval in deg
     * @return true if angle is approximately equal 
     */
    bool inline isApprox( Angle other, double prec = 1e-5 )
    {
	return fabs( other.rad - rad ) < prec;
    }
};

static inline Angle operator+( Angle a, Angle b )
{
    return Angle::fromRad( a.getRad() + b.getRad() );
}

static inline Angle operator-( Angle a, Angle b )
{
    return Angle::fromRad( a.getRad() - b.getRad() );
}

static inline Angle operator*( Angle a, double b )
{
    return Angle::fromRad( a.getRad() * b );
}

static inline Angle operator*( double a, Angle b )
{
    return Angle::fromRad( a * b.getRad() );
}

static inline std::ostream& operator << (std::ostream& os, Angle angle)
{
    os << angle.getRad() << boost::format("[%3.1fdeg]") % angle.getDeg();
    return os;
}

}

#endif