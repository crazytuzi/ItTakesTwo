import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCar;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCarWindupCharacterAnimComponent;

class UWindupPullbackCarPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WindupPullbackCarPlayerInputCapability");
	default CapabilityTags.Add(CapabilityTags::Input);

	default CapabilityDebugCategory = n"WindupPullbackCarPlayerInputCapability";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	APullbackCar PullbackCar;
	UPullbackCarWindupCharacterAnimComponent PullBackComponent;
	bool bCanCancel = false;
	//float TimeSinceActivation = 0.f;

	UPROPERTY()
	UHazeLocomotionFeatureBase CodyFeature;

	UPROPERTY()
	UHazeLocomotionFeatureBase MayFeature;

	UPROPERTY()
	FText TutorialPullCar;

	UPROPERTY()
	FText TutorialReleaseCar;

	UHazeLocomotionFeatureBase FeatureToUse; 

	bool bIsPulling = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PullBackComponent = UPullbackCarWindupCharacterAnimComponent::Get(Player);
		ensure(PullBackComponent != nullptr);
		FeatureToUse = Player == Game::GetCody() ? CodyFeature : MayFeature;
		Player.AddLocomotionFeature(FeatureToUse);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Player.RemoveLocomotionFeature(FeatureToUse);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (PullBackComponent.PullbackCar == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!PullBackComponent.bPlayerPullingCar)
			return EHazeNetworkActivation::DontActivate;

		if(PullBackComponent.PullbackCar.CurrentMovementState != EPullBackCarMovementState::WindingUp)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PullBackComponent.PullbackCar == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!PullBackComponent.bPlayerPullingCar)
			return EHazeNetworkDeactivation::DeactivateLocal;	

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PullbackCar = PullBackComponent.PullbackCar;
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this, n"Windup");
		Player.AttachToComponent(PullbackCar.WindupAttachComp, n"", EAttachmentRule::SnapToTarget);
		Player.OtherPlayer.DisableOutlineByInstigator(this);
		PullbackCar.DriverInteractComp.DisableForPlayer(Player, n"InOtherInteraction");

		FTutorialPrompt LeftStickPrompt;
		LeftStickPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_Down;
		LeftStickPrompt.Text = TutorialPullCar;
		ShowTutorialPrompt(Player, LeftStickPrompt, this);

		bCanCancel = false;
		PullbackCar.WindupDirection = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.StopAllSlotAnimations();
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.OtherPlayer.EnableOutlineByInstigator(this);

		RemoveTutorialPromptByInstigator(Player, this);

		if(PullbackCar != nullptr)
		{
			PullbackCar.DriverInteractComp.EnableForPlayerAfterFullSyncPoint(Player, n"InOtherInteraction");
			Player.RemoveCapabilitySheet(PullbackCar.PullerSheet, PullbackCar);
			PullbackCar = nullptr;	
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		PullBackComponent.PullVelocity = PullbackCar.MoveComp.Velocity.Size();
		PullBackComponent.TurnRate = (PullbackCar.CurrentWindupRotationForce * PullbackCar.WindupRotationForceMultiplier) * -1.f;

		FHazeRequestLocomotionData AnimRequest;
		AnimRequest.AnimationTag = n"PullbackCar";
		Player.RequestLocomotion(AnimRequest);

		if(PullbackCar.CurrentMovementState == EPullBackCarMovementState::WindingUp)
		{
			PullbackCar.WindupDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
			if (GetActiveDuration() >= 1.5f && !bCanCancel)
			{
				bCanCancel = true;

				FTutorialPrompt ReleasePrompt;
				ReleasePrompt.DisplayType = ETutorialPromptDisplay::Action;
				ReleasePrompt.Action = n"Cancel";
				ReleasePrompt.Text = TutorialReleaseCar;
				ShowTutorialPrompt(Player, ReleasePrompt, this);
			}

			if (WasActionStarted(ActionNames::Cancel) && bCanCancel)
			{
				PullbackCar.NetPlayerStoppedWindingUpCar();
			}
		}
	}
}