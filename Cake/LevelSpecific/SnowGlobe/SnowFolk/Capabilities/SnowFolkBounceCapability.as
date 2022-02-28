import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkSplineFollower;

class USnowFolkBounceCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnowFolkBounceCapability");
	default CapabilityDebugCategory = n"SnowFolkBounceCapability";
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 100;

	ASnowfolkSplineFollower SnowFolk;
	UBouncePadResponseComponent BounceResponseComp;
	UHazeAkComponent AudioComp;
	USnowFolkFauxCollisionComponent FauxCollisionComp;

	AHazePlayerCharacter BouncingPlayer;
	float BounceEndTime;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SnowFolk = Cast<ASnowfolkSplineFollower>(Owner);
		BounceResponseComp = UBouncePadResponseComponent::Get(Owner);
		AudioComp = UHazeAkComponent::GetOrCreate(Owner);
		FauxCollisionComp = USnowFolkFauxCollisionComponent::Get(Owner);

		BounceResponseComp.OnBounce.AddUFunction(this, n"HandlePlayerBounced");
		FauxCollisionComp.OnPlayerDownImpact.AddUFunction(this, n"HandlePlayerDownImpact");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{	
		if (SnowFolk.bIsRecovering)
			return EHazeNetworkActivation::DontActivate;

		if (SnowFolk.bIsHit)
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(n"PlayerBounced"))
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SnowFolk.bIsRecovering)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (SnowFolk.bIsHit)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (BouncingPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Time::GameTimeSeconds > BounceEndTime)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams& ActivationParams)
	{
		SnowFolk.bIsJumpedOn = true;
		BounceEndTime = Time::GameTimeSeconds + SnowFolk.SquishDuration;
		SnowFolk.BP_PlayerBounce(BouncingPlayer);

		if (SnowFolk.BounceAudioEvent != nullptr)
			AudioComp.HazePostEvent(SnowFolk.BounceAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams& DeactivationParams)
	{
		SnowFolk.bIsJumpedOn = false;
		BouncingPlayer = nullptr;
	}

	UFUNCTION()
	void HandlePlayerDownImpact(AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeValue(n"VerticalVelocity", SnowFolk.BounceVerticalVelocity);
		Player.SetCapabilityAttributeValue(n"GroundPoundModifier", 1.1f);
		Player.SetCapabilityAttributeValue(n"HorizontalVelocityModifier", SnowFolk.BounceHorizontalVelocityModifier);
		Player.SetCapabilityAttributeObject(n"BouncedObject", SnowFolk);
		Player.SetCapabilityActionState(n"Bouncing", EHazeActionState::Active);
	}

	UFUNCTION(NotBlueprintCallable)
	void HandlePlayerBounced(AHazePlayerCharacter Player, bool bGroundPounded)
	{
		BouncingPlayer = Player;
		SnowFolk.SetCapabilityActionState(n"PlayerBounced", EHazeActionState::ActiveForOneFrame);
	}
}