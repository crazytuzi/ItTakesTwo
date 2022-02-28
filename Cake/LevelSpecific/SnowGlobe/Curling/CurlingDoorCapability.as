import Cake.LevelSpecific.SnowGlobe.Curling.CurlingDoor;

class UCurlingDoorCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingDoorCapability");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ACurlingDoor Door;

	bool bCanDeactivate;

	float DoorSpeed = 1300.f;

	bool bPlayedClosingAudio;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Door = Cast<ACurlingDoor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Door.bCanActivateDoor)
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Door.bCanActivateDoor)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (Door.bIsOpening)
			Door.AudioOpenDoorEvent();
	
		bPlayedClosingAudio = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (Door.bIsOpening)
		{
			FVector NewLoc = FMath::VInterpConstantTo(Door.MeshComp.RelativeLocation, Door.OpenDoorLoc, DeltaTime, DoorSpeed);
			Door.MeshComp.SetRelativeLocation(NewLoc);

			float Distance = (Door.OpenDoorLoc - Door.MeshComp.RelativeLocation).Size();

			if (Distance < 3.f)
				Door.bCanActivateDoor = false;
		}
		else
		{
			if (!bPlayedClosingAudio)
			{
				Door.AudioCloseDoorEvent();
				bPlayedClosingAudio = true;
			}

			FVector NewLoc = FMath::VInterpConstantTo(Door.MeshComp.RelativeLocation, Door.ClosedDoorLoc, DeltaTime, DoorSpeed);
			Door.MeshComp.SetRelativeLocation(NewLoc);

			float Distance = (Door.ClosedDoorLoc - Door.MeshComp.RelativeLocation).Size();

			if (Distance < 3.f)
				Door.bCanActivateDoor = false;
		}
	}
}