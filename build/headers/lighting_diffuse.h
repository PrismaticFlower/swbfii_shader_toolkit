#ifndef LIGHTING_DIFFUSE
#define LIGHTING_DIFFUSE

#if defined(__OPTION_LIGHT_DIRECTIONAL__) && \
    !defined(__OPTION_LIGHT_POINT0__) && \
    !defined(__OPTION_LIGHT_POINT1__) && \
    !defined(__OPTION_LIGHT_POINT23__) && \
    !defined(__OPTION_LIGHT_SPOT0__)
#define LIGHTING_2D
#elif defined(__OPTION_LIGHT_DIRECTIONAL__) && \
     defined(__OPTION_LIGHT_POINT0__) && \
    !defined(__OPTION_LIGHT_POINT1__) && \
    !defined(__OPTION_LIGHT_POINT23__) && \
    !defined(__OPTION_LIGHT_SPOT0__)
#define LIGHTING_2D1P
#elif defined(__OPTION_LIGHT_DIRECTIONAL__) && \
     defined(__OPTION_LIGHT_POINT0__) && \
     defined(__OPTION_LIGHT_POINT1__) && \
    !defined(__OPTION_LIGHT_POINT23__) && \
    !defined(__OPTION_LIGHT_SPOT0__)
#define LIGHTING_2D2P
#elif defined(__OPTION_LIGHT_DIRECTIONAL__) && \
     defined(__OPTION_LIGHT_POINT0__) && \
     defined(__OPTION_LIGHT_POINT1__) && \
     defined(__OPTION_LIGHT_POINT23__) && \
    !defined(__OPTION_LIGHT_SPOT0__)
#define LIGHTING_2D4P
#elif defined(__OPTION_LIGHT_DIRECTIONAL__) && \
     defined(__OPTION_LIGHT_POINT0__) && \
    !defined(__OPTION_LIGHT_POINT1__) && \
    !defined(__OPTION_LIGHT_POINT23__) && \
     defined(__OPTION_LIGHT_SPOT0__)
#define LIGHTING_2D1P1S
#elif defined(__OPTION_LIGHT_DIRECTIONAL__) && \
     defined(__OPTION_LIGHT_POINT0__) && \
     defined(__OPTION_LIGHT_POINT1__) && \
    !defined(__OPTION_LIGHT_POINT23__) && \
     defined(__OPTION_LIGHT_SPOT0__)
#define LIGHTING_2D2P1S
#elif defined(__OPTION_LIGHT_DIRECTIONAL__) && \
    !defined(__OPTION_LIGHT_POINT0__) && \
    !defined(__OPTION_LIGHT_POINT1__) && \
    !defined(__OPTION_LIGHT_POINT23__) && \
     defined(__OPTION_LIGHT_SPOT0__)
#define LIGHTING_2D1S
#else
#error Unexpected light configuration!
#endif

#endif