import Vino.DoublePull.DoublePullComponent;

class UDoublePullActorAnimationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DoublePull");
	default CapabilityDebugCategory = n"Gameplay";

	default TickGroup = ECapabilityTickGroups::LastMovement;

	UDoublePullComponent DoublePull;
	FVector PrevLocation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DoublePull = UDoublePullComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (DoublePull == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (DoublePull.Spline == nullptr)
			return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (DoublePull == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (DoublePull.Spline == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PrevLocation = Owner.ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector Delta = (Owner.ActorLocation - PrevLocation); 
		FVector Direction = Delta.GetSafeNormal();

        FHazeRequestLocomotionData AnimationRequest;
        AnimationRequest.LocomotionAdjustment.DeltaTranslation = Delta;
        AnimationRequest.LocomotionAdjustment.WorldRotation = Owner.ActorQuat;
        AnimationRequest.WantedWorldTargetDirection = Direction;
        AnimationRequest.WantedWorldFacingRotation = Owner.ActorQuat;

		AnimationRequest.AnimationTag = n"DoublePull";
		AnimationRequest.SubAnimationTag = NAME_None;

		auto CharacterOwner = Cast<AHazeCharacter>(Owner);
		DoublePull.SetAnimationParams(CharacterOwner, Direction);
		CharacterOwner.RequestLocomotion(AnimationRequest);

		CharacterOwner.SetAnimBoolParam(n"DoublePullCodyInteracting", DoublePull.IsPlayerInteracting(Game::GetCody()));
		CharacterOwner.SetAnimBoolParam(n"DoublePullMayInteracting", DoublePull.IsPlayerInteracting(Game::GetMay()));

		PrevLocation = Owner.ActorLocation;
	}
};