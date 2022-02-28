import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingDoor;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingResetVolume;

event void FCallEndGame();

class ACurlingEndSessionManager : AHazeActor
{
	FCallEndGame EventCallEndGame;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent LeftSideVacuumSystem;
	default LeftSideVacuumSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = LeftSideVacuumSystem)
	UBillboardComponent LeftVisuals;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent RightSideVacuumSystem;
	default RightSideVacuumSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent, Attach = RightSideVacuumSystem)
	UBillboardComponent RightVisuals;

	UPROPERTY(Category = "Setup")
	ACurlingResetVolume ResetVolume;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartPull;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent EndPull;

	UPROPERTY()
	TArray<ACurlingStone> EndSessionStoneArray;

	UPROPERTY(Category = "Setup")
	TSubclassOf<UHazeCapability> DoorCapability;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet EndSessionCapabilitySheet;

	FHazeAcceleratedFloat AcceleratedStoneSpeed;
	float MaxAcceleratedSpeed = 900.f;

	bool bActivateEndSession;
	bool bCanActivateDoor;
	bool bCanOpenDoor;

	FVector ClosedDoorLoc;
	FVector OpenDoorLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AcceleratedStoneSpeed.SnapTo(0.f);

		AddCapabilitySheet(EndSessionCapabilitySheet);
	}

	void SetSystemState(bool bShouldActivate)
	{
		if (bShouldActivate)
		{
			if (LeftSideVacuumSystem != nullptr)
				LeftSideVacuumSystem.Activate();
			if (RightSideVacuumSystem != nullptr)
				RightSideVacuumSystem.Activate();

			AkComp.HazePostEvent(StartPull);
		}
		else
		{
			if (LeftSideVacuumSystem != nullptr)
				LeftSideVacuumSystem.Deactivate();
			if (RightSideVacuumSystem != nullptr)
				RightSideVacuumSystem.Deactivate();	

			AkComp.HazePostEvent(EndPull);
		}
	}
}