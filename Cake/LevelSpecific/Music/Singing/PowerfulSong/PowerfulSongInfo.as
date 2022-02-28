
// Data used for actors that contains PowerfulSongImpactComponent
USTRUCT()
struct FPowerfulSongInfo
{
	// The direction the song is travelling.
	UPROPERTY()
	FVector Direction;
	
	// The location on the mesh that was hit
	UPROPERTY()
	FVector ImpactLocation;

	// The Actor that instigated the song.
	UPROPERTY()
	AHazeActor Instigator;

	// The projectile that hit (Cast to APowerfulSongProjectile)
	UPROPERTY()
	AHazeActor Projectile;
}

struct FPowerfulSongImpactLocationInfo
{
	FVector ImpactLocation;
	UHazeActivationPoint ImpactComponent;
}

struct FPowerfulSongHitInfo
{
	TArray<FPowerfulSongImpactLocationInfo> Impacts;
	FVector ProjectileStartLocation;
	FVector ProjectileForwardDirection;
}

event void FOnPowerfulSongImpact(FPowerfulSongInfo Info);
