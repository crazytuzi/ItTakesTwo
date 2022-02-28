import Vino.Tutorial.TutorialStatics;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingComponent;
import Vino.Movement.Capabilities.Sliding.CharacterSlidingStatics;
import Vino.Movement.Components.MovementComponent;

class USlopeSlidingTutorialCapability : UHazeCapability
{	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 110;

	default CapabilityDebugCategory = n"Tutorial SlopeSliding";

	AHazePlayerCharacter Player;
	UCharacterSlidingComponent SlidingComp;
	UHazeMovementComponent MoveComp;

	float DefaultMoveSpeed = 800.f;

	UPROPERTY()
	float TutorialShowUpActivationTime = 0.5f;

	UPROPERTY()
	float TutorialShowUpCooldown = 0.5f;

	float ActivationTimer = 0.f;
	float CooldownTimer = 0.f;

	UPROPERTY()
	TArray<FTutorialPrompt> TutorialPrompts;

	bool bHasDisplayedTutorial = false;
	bool bHasPressedButtons = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SlidingComp = UCharacterSlidingComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CooldownTimer > 0.f)
			return EHazeNetworkActivation::DontActivate;

		if (IsActioning(ActionNames::MovementSlide))
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsAirborne())
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.DownHit.Component != nullptr)
			if (!MoveComp.DownHit.Component.HasTag(ComponentTags::Slideable))
				return EHazeNetworkActivation::DontActivate;

		// Compare speed to required speed (based off of slope angle)
		if (GetVelocityFlattenedToSlope().Size() < GetRequiredSpeedForSlide())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(ActionNames::MovementSlide))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!HasControl())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.IsAirborne())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (MoveComp.DownHit.Component != nullptr)
			if (!MoveComp.DownHit.Component.HasTag(ComponentTags::Slideable))
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Compare speed to required speed (based off of slope angle)
		if (GetVelocityFlattenedToSlope().Size() < GetRequiredSpeedForSlide())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ActivationTimer = TutorialShowUpActivationTime;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveTutorialPromptByInstigator(this);

		CooldownTimer = TutorialShowUpCooldown;
		bHasDisplayedTutorial = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{	
		if (CooldownTimer > 0.f)
			CooldownTimer -= DeltaTime;
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (ActivationTimer > 0.f)
			ActivationTimer -= DeltaTime;
		else if (!bHasDisplayedTutorial)
		{
			for (auto TutorialPrompt : TutorialPrompts)
			{
				Player.ShowTutorialPrompt(TutorialPrompt, this);
			}		
		
			bHasDisplayedTutorial = true;
		}

	}	

	// Copied from CharacterSlidingCapability
	FVector GetVelocityFlattenedToSlope() const
	{
		FVector ConstrainedVelocity = Math::ConstrainVectorToSlope(MoveComp.Velocity, MoveComp.DownHit.ImpactNormal, MoveComp.WorldUp);
		return ConstrainedVelocity;
	}

	// Copied from CharacterSlidingCapability
	float GetRequiredSpeedForSlide() const
	{	
		float RequiredSpeed = 0.f;
		float EffectiveAngle = GetEffectiveSlopeAngle(MoveComp.DownHit.Normal, MoveComp.WorldUp, MoveComp.Velocity.GetSafeNormal());

		if (SlidingComp.SlideSpeedCurve != nullptr)
			RequiredSpeed = DefaultMoveSpeed * SlidingComp.SlideSpeedCurve.GetFloatValue(EffectiveAngle);
		else
			RequiredSpeed = DefaultMoveSpeed * 1.4f;
		
		return RequiredSpeed;
	}

}
