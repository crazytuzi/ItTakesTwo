enum EVacuumMode
{
	Suck,
	Blow
}

struct FExhaustDistanceMultiplierRange
{
	UPROPERTY()
	float Min = 0.f;

	UPROPERTY()
	float Max = 2.f;
}

enum EFanColor
{
    Green,
    Red
}