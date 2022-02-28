import Vino.Movement.Components.MovementComponent;

class UHopscotchBananaBounceAirMovement : UHazeCapability
{
	default CapabilityTags.Add(n"HopscotchBananaBounceAirMovement");

	default CapabilityDebugCategory = n"HopscotchBananaBounceAirMovement";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 70;

	AHazePlayerCharacter Player;
	UHazeMovementComponent MoveComp;
	bool bHasSlowedDown = false;
	float StartingVelo = 0.f;
	float NewVelo = 0.f;
	float VeloReduction = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if(!IsActioning(n"BananaBounce"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"BananaBounce"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (bHasSlowedDown)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bHasSlowedDown = false;
		NewVelo = MoveComp.HorizontalVelocity;
		VeloReduction = 0.f;

		FVector PlayerVelo = -UHazeMovementComponent::Get(Player).Velocity;
		PlayerVelo = FVector(PlayerVelo.X, PlayerVelo.Y, 0.f);
		PlayerVelo.Normalize();
		UHazeMovementComponent::Get(Player).SetVelocity(FVector::ZeroVector);
		Player.SetCapabilityAttributeVector(n"VerticalVelocityDirection", PlayerVelo);
		Player.SetCapabilityAttributeValue(n"VerticalVelocity", 2000.f);
		Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", 0.f);
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.SetCapabilityActionState(n"BananaBounce", EHazeActionState::Inactive);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (FMath::Abs(MoveComp.GetHorizontalVelocity()) < 800.f)
			bHasSlowedDown = true;

		FVector Velocity = MoveComp.Velocity;
		FVector Horizontal = Velocity.ConstrainToPlane(MoveComp.WorldUp);
		FVector Vertical = Velocity - Horizontal;
		FVector ModdedHorizontal = Horizontal.SafeNormal * NewVelo;
		MoveComp.SetVelocity(ModdedHorizontal + Vertical);

		NewVelo -= DeltaTime * VeloReduction;
		VeloReduction += DeltaTime * 3000.f;
	}
}