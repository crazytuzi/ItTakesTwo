import Cake.LevelSpecific.Tree.DarkRoom.FireflySwarm;

class UFireflyAttachedFliesCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UFireflyFlightComponent FlightComp;
	UHazeBaseMovementComponent MoveComp;

	float FlyTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		FlightComp = UFireflyFlightComponent::GetOrCreate(Player);
		MoveComp = Player.MovementComponent;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (FlightComp.AttachedFireflies <= 0)
	        return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsGrounded())
	        return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (FlightComp.AttachedFireflies == 0)
	        return EHazeNetworkDeactivation::DeactivateLocal;

		if (MoveComp.IsGrounded())
	        return EHazeNetworkDeactivation::DeactivateLocal;
		
        return EHazeNetworkDeactivation::DontDeactivate;
	
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FlightComp.OnAttachFireflies();
		Print("OnAttach");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		FlyTime = 0.f;
		FlightComp.OnRemoveAttachedFireflies();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FlyTime += 5.f * DeltaTime * (1.f + FlightComp.AttachedFireflies * 0.4f);
	}
	
}