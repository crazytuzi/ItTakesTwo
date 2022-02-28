import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyManager;

class UHorseDerbyManagerWheelTurnCapability : UHazeCapability
{
	default CapabilityTags.Add(n"HorseDerbyManagerWheelTurnCapability");
	default CapabilityTags.Add(n"HorseDerby");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHorseDerbyManager Manager;

	FHazeAcceleratedFloat AccelSpeed;

	float SpeedTarget = 10.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Manager = Cast<AHorseDerbyManager>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Manager.Gamestate == EDerbyHorseState::GameActive)
       		return EHazeNetworkActivation::ActivateLocal;

       	return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Manager.Gamestate == EDerbyHorseState::Inactive && AccelSpeed.Value == SMALL_NUMBER)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AccelSpeed.SnapTo(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (Manager.Gamestate == EDerbyHorseState::GameActive)
			AccelSpeed.AccelerateTo(SpeedTarget, 4.f, DeltaTime);
		else
			AccelSpeed.AccelerateTo(0.f, 4.f, DeltaTime);
		
		//Both wheel1 and 2 should start with the same rotation
		FRotator NewRot = FRotator(AccelSpeed.Value * DeltaTime, 0.f, 0.f); 

		// Manager.Wheel1.SetActorRotation(NewRot);
		Manager.Wheel1.AddActorLocalRotation(NewRot);
		Manager.Wheel2.AddActorLocalRotation(NewRot);
	}
}