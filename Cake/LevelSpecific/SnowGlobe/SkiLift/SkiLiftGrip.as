import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetIceSkatingMagnetComponent;

class ASkiLiftGrip : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent GripRoot;

	UPROPERTY(DefaultComponent, Attach = GripRoot)
	UMagnetIceSkatingMagnetComponent MagnetComponent;

	AHazePlayerCharacter UsingPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MagnetComponent.OnActivatedBy.AddUFunction(this, n"PullGrip");
		MagnetComponent.OnDeactivatedBy.AddUFunction(this, n"ReleaseGrip");
	}

	UFUNCTION()
	void PullGrip(UHazeActivationPoint Point, AHazePlayerCharacter Player)
	{
		UsingPlayer = Player;
	}

	UFUNCTION()
	void ReleaseGrip(UHazeActivationPoint Point, AHazePlayerCharacter Player)
	{
		UsingPlayer = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DetlaTime)
	{
		if(UsingPlayer != nullptr)
		{
			//FVector Location = FMath::VInterpTo(GripRoot.GetWorldLocation(), UsingPlayer.GetActorLocation(), DetlaTime, 3.f);
			//GripRoot.SetWorldLocation(Location);

			FVector Target = UsingPlayer.GetActorLocation() - Root.GetWorldLocation();
			FVector TargetLocation = Root.GetWorldLocation() + Target * 0.5f;
			FRotator TargetRotation = Target.Rotation();

			FVector Location = FMath::VInterpTo(GripRoot.GetWorldLocation(), TargetLocation, DetlaTime, 3.f);
			FRotator Rotation = FMath::RInterpTo(GripRoot.GetWorldRotation(), TargetRotation, DetlaTime, 12.f);

			GripRoot.SetWorldLocationAndRotation(Location, Rotation);
		}
		else
		{
			FVector Location = FMath::VInterpTo(GripRoot.GetWorldLocation(), Root.GetWorldLocation(), DetlaTime, 3.f);
			FRotator Rotation = FMath::RInterpTo(GripRoot.GetWorldRotation(), Root.GetWorldRotation(), DetlaTime, 12.f);

			GripRoot.SetWorldLocationAndRotation(Location, Rotation);
		}

		//FVector Location = FMath::VInterpTo(GripRoot.GetWorldLocation(), Root.GetWorldLocation(), DetlaTime, 3.f);
		//GripRoot.SetWorldLocation(Location);
	}
}