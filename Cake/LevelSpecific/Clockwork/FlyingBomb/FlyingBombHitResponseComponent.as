
event void FOnHitByFlyingBomb(FVector ExplosionLocation, AHazePlayerCharacter DroppingPlayer);

class UFlyingBombHitResponseComponent : UActorComponent
{
	UPROPERTY()
	FOnHitByFlyingBomb OnHitByFlingBomb;
}