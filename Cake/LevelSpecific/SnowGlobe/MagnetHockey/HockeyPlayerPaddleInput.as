import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPlayerComp;

class UHockeyPlayerPaddleInput : UHazeCapability
{
	default CapabilityTags.Add(n"HockeyPlayerPaddleMovement");

	default CapabilityDebugCategory = n"GamePlay";
	default CapabilityDebugCategory = n"AirHockey";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UHockeyPlayerComp PlayerComp;

	UHazeCameraUserComponent UserComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UHockeyPlayerComp::Get(Player);
		UserComp = UHazeCameraUserComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.HockeyPlayerState == EHockeyPlayerState::InPlay)
        	return EHazeNetworkActivation::ActivateLocal;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.HockeyPlayerState == EHockeyPlayerState::InPlay)
			return EHazeNetworkDeactivation::DontDeactivate;
		
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.AttachToActor(PlayerComp.HockeyPaddle, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector MovementDirection = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
		
		FVector CamForward = UserComp.CurrentDesiredRotation.ForwardVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal();

		if (CamForward.IsZero())
			CamForward = UserComp.CurrentDesiredRotation.UpVector.ConstrainToPlane(FVector::UpVector).GetSafeNormal();
		
		FVector CamRight = UserComp.CurrentDesiredRotation.RightVector.GetSafeNormal();

		PlayerComp.HockeyPaddle.PlayerInput = CamRight * MovementDirection.X + CamForward * MovementDirection.Y;
	}
}