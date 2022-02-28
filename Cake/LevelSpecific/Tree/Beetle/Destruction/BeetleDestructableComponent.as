event void FBeetleDestructableImpact();

class UBeetleDestructableComponent : UActorComponent
{
	// This event will be broadcast by UBeetleDestroyObstaclesCapability when it detects an impact
	UPROPERTY()
	FBeetleDestructableImpact OnBeetleImpact;
}