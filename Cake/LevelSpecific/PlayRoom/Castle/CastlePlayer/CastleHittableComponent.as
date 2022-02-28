
event void FOnHitByCastlePlayer(AHazePlayerCharacter Player, FVector HitLocation);

class UCastleHittableComponent : UActorComponent
{
	UPROPERTY()
	FOnHitByCastlePlayer OnHitByCastlePlayer;
};