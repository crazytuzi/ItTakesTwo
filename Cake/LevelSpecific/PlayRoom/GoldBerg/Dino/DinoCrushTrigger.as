import Cake.LevelSpecific.PlayRoom.GoldBerg.HeadButtingDino;

class UDinoCrushTrigger : UBoxComponent
{
	UPROPERTY()
	AHeadButtingDino Dino;

	UPROPERTY()
	AActor RespawnPoint;

	FVector LocationLastFrame;

	bool GetIsLowering()
	{
		return (LocationLastFrame.Z > WorldLocation.Z);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ComponentTickEnabled = false;
	}

	void CheckOverlapping()
	{
		bool IsOverlapping = false;

		if (GetIsLowering())
		{
			IsOverlapping = Trace::ComponentOverlapComponent(Dino.CrushCapsule, this, WorldLocation, WorldRotation.Quaternion(), false);
								 // Is reset in Dino BP
			if (IsOverlapping && !Dino.bWasCrushed)
			{
				Dino.TriggerDeathEffets(RespawnPoint.ActorTransform);
				Dino.bWasCrushed = true;
			}
		}
	}



	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CheckOverlapping();
		LocationLastFrame = WorldLocation;
	}
}