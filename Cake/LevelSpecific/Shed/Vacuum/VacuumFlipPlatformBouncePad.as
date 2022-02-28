import Vino.BouncePad.BouncePad;

event void FVacuumFlipPlatformBounce(AHazePlayerCharacter Player, ABouncePad Pad);

class AVacuumFlipPlatformBouncePad : ABouncePad
{
	UPROPERTY()
	FVacuumFlipPlatformBounce OnBounced;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		OnBouncePadBouncedOn.AddUFunction(this, n"Bounce");
	}

	UFUNCTION()
	void Bounce(AHazePlayerCharacter Player)
	{
		OnBounced.Broadcast(Player, this);
	}
}