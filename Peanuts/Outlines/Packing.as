// Trading memory for processing power.
// Equivalents to these functions are also in Packing.usf

float floor(float a)
{
    return FMath::FloorToInt(a);
}

float AddMargin(float a)
{
    float s = 0.1f;
    return a * (1.0f - s) + (s * 0.5f);
}
float RemoveMargin(float a)
{
    float s = 0.1f;
    return (a - (s * 0.5f)) * (1.0f + s);
}


float ScaleUp(float a)
{
    return floor(a * 1000000.0f);
}
float ScaleDown(float a)
{
    return (a) / 1000000.0f;
}


float PackTwoFloats(float a, float b)
{
    return AddMargin(a) + ScaleUp(b);
}
FVector2D UnpackTwoFloats(float a)
{
    return FVector2D(RemoveMargin(a - floor(a)), ScaleDown(a));
}

float PackFloatAndInt(float a, float b, float c)
{
    return AddMargin(a) + (b * 8) + c;   
}
FVector UnpackFloatAndInt(float a)
{
    return FVector(RemoveMargin(a % 1.0f), floor(floor(a) / 8.0f), floor(a) % 8.0f);
}
