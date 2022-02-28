import Cake.LevelSpecific.Tree.DarkRoom.FireflySwarm;

class UFireflyCatchCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"FireflyCatch");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UFireflyFlightComponent FlightComp;
	
	float CatchDrag = 1.8f;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlightComp = UFireflyFlightComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (FlightComp.OverlappingSwarms.Num() == 0)
			return EHazeNetworkActivation::DontActivate;
	
        return EHazeNetworkActivation::ActivateUsingCrumb;
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FlightComp.OverlappingSwarms.Num() <= 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			float CenterForce = 3000.f;
			FVector CenterDirection = FlightComp.OverlappingSwarms[0].ActorLocation - Player.ActorLocation;
			
			// Increase CenterForce the further out from the center you get
			CenterForce = CenterDirection.Size() * 20.f;
			
			CenterDirection.Normalize();
			FlightComp.Velocity += CenterDirection * CenterForce * DeltaTime;
			FlightComp.Velocity -= FlightComp.Velocity * CatchDrag * DeltaTime;
		}
	}
	
}