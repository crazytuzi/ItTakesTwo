
struct FBoidObstacleInfo
{
	// The location for the trace hit
	UPROPERTY()
	FVector HitLocation;
	// The component that was hit
	UPROPERTY()
	UPrimitiveComponent Obstacle;
}
