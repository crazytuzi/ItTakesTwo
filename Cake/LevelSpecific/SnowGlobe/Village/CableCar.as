import Vino.Movement.MovementSettings;

event void FCableCarReadyToDeparture();

class CableCar : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UStaticMeshComponent CableCar;

	UPROPERTY(DefaultComponent)
	USphereComponent Collider;

	UPROPERTY(DefaultComponent)
	USceneComponent TeleportLocation;

	UPROPERTY()
	FCableCarReadyToDeparture OnReadyToDepature;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;

	bool bMayOverlaps;
	bool bCodyOverlaps;

	bool bFiredOnce;

	UPROPERTY()
	bool bCableCarStarted;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Collider.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
        Collider.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player == nullptr)
		return;

		UMovementSettings::SetMoveSpeed(Player, 500.f, this);
		// Player.ApplyCameraSettings(CameraSettings, 2.f, this, EHazeCameraPriority::Low);

        if(Player.HasControl())
		{
			PlayerOverlapstateChanged(Player, true);
		}
    }

    UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player == nullptr)
		return;

		// Player.ClearSettingsByInstigator(this);
		// Player.ClearCameraSettingsByInstigator(this);

        if(Player.HasControl())
		{
			PlayerOverlapstateChanged(Player, false);
		}
    }

	UFUNCTION(NetFunction)
	void PlayerOverlapstateChanged(AHazePlayerCharacter Player, bool Overlapped)
	{
		if (HasControl())
		{
			if (Player.IsMay())
			{
				bMayOverlaps = Overlapped;
			}

			else
			{
				bCodyOverlaps = Overlapped;
			}

			if (bCodyOverlaps && bMayOverlaps)
			{
				StartCableCar();
			}
		}
	}

	UFUNCTION(NetFunction)
	void StartCableCar()
	{
		if (bFiredOnce)
		return;

		OnReadyToDepature.Broadcast();

		if (Game::GetCody().HasControl())
		{
			float DistanceToCollider = Game::GetCody().ActorCenterLocation.Distance(Collider.GetWorldLocation());
			if (DistanceToCollider > Collider.GetWorldScale().X * 100)
			{
				Game::GetCody().SetActorLocation(TeleportLocation.WorldLocation);
			}
		}

		if (Game::GetMay().HasControl())
		{
			float DistanceToCollider = Game::GetMay().ActorCenterLocation.Distance(Collider.GetWorldLocation());
			if (DistanceToCollider > Collider.GetWorldScale().X  * 100)
			{
				Game::GetMay().SetActorLocation(TeleportLocation.WorldLocation);
			}
		}

		bFiredOnce = true;
	}
}