
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;

class UCharacterLandingStunCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::LandingStun);
	default CapabilityTags.Add(CapabilityTags::Collision);
    default TickGroup = ECapabilityTickGroups::ReactionMovement;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	bool bPlayingStunAnimation = false;

	UPROPERTY()
	UAnimSequence StunAnimation;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;

    // Internal Variables
	UHazeMovementComponent Movement;
	AHazeCharacter CharacterOwner;
	AHazePlayerCharacter Player;

	UCameraShakeBase CurrentActiveShake = nullptr;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CharacterOwner = Cast<AHazeCharacter>(Owner);
        ensure(CharacterOwner != nullptr);
		Movement = UHazeMovementComponent::GetOrCreate(Owner);
		Player = Cast<AHazePlayerCharacter>(CharacterOwner);
	}
    
    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        // if (Movement.BecameGrounded() && Math::ConstrainVectorToDirection(Movement.GetPreviousVelocity(), Movement.WorldUp).Size() >= Movement.MaxFallSpeed - 10.f)
		// {
        //     return EHazeNetworkActivation::ActivateLocal;
		// }
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bPlayingStunAnimation)
        	return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bPlayingStunAnimation = true;

		SetMutuallyExclusive(n"Movement", true);
		CharacterOwner.BlockCapabilities(n"CharacterFacing", this);
		
		FHazeAnimationDelegate BlendingOutEvent;
		BlendingOutEvent.BindUFunction(this, n"BlendOutFunction");
		CharacterOwner.PlaySlotAnimation(FHazeAnimationDelegate(), BlendingOutEvent, StunAnimation, BlendTime = 0.1f);

		if(Player != nullptr)
		{
			CurrentActiveShake = Player.PlayCameraShake(CameraShake);
			Player.PlayForceFeedback(ForceFeedback, false, true, n"LandingRumble");
		}
	}

	UFUNCTION()
	void BlendOutFunction()
	{
		bPlayingStunAnimation = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(bPlayingStunAnimation)
		{
			CharacterOwner.StopAnimation();

			if(Player != nullptr)
			{
				Player.StopCameraShake(CurrentActiveShake);
				Player.StopForceFeedback(ForceFeedback, n"LandingRumble");
			}
		}

		SetMutuallyExclusive(n"Movement", false);
		CharacterOwner.UnblockCapabilities(n"CharacterFacing", this);
	}

}
