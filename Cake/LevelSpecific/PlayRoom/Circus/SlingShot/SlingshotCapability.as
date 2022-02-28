import Cake.LevelSpecific.PlayRoom.Circus.SlingShot.SlingShot;
import Cake.LevelSpecific.PlayRoom.Circus.SlingShot.SlingShotAnimationdataComponent;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureSlingShot;
import Vino.Tutorial.TutorialStatics;


class USlingShotCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"SlingShot");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	bool IsLaunched = false;

	AHazePlayerCharacter Player;

	ASlingShotActor SlingshotActor;


	// Internal tick order for the TickGroup, Lowest ticks first.
	default TickGroupOrder = 100;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CameraSettings;

	USlingShotAnimationDataComponent AnimData;

	UPROPERTY()
	ULocomotionFeatureSlingShot FeatureCody;

	UPROPERTY()
	ULocomotionFeatureSlingShot FeatureMay;

	bool bShowTutorial = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Player = Cast<AHazePlayerCharacter>(Owner);
		AnimData = USlingShotAnimationDataComponent::GetOrCreate(Player);
		Reset::RegisterPersistentComponent(AnimData);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
	Reset::UnregisterPersistentComponent(AnimData);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		ASlingShotActor SlingshotActorAttribute = Cast<ASlingShotActor>(GetAttributeObject(n"SlingShot"));
		
		
		if (SlingshotActorAttribute != nullptr)
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CheckIfShouldDeactive())
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

    bool CheckIfShouldDeactive() const
    {
        if(IsActioning(ActionNames::Cancel) && SlingshotActor.AllowCancel || IsActioning(n"ShootMarble"))
		{
			return true;
		}

		else 
		{
			return false;
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UObject SlihngShot;
		SlingshotActor = Cast<ASlingShotActor>(GetAttributeObject(n"SlingShot"));
		ConsumeAttribute(n"SlingShot", SlihngShot);

		if (Player.IsCody())
		{
			Player.AddLocomotionFeature(FeatureCody);
		}
		else
		{
			Player.AddLocomotionFeature(FeatureMay);
		}


		ShowTutorial();
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		FHazeCameraBlendSettings BlendSettings;
		Player.TriggerMovementTransition(this);
		//Player.ApplyCameraSettings(CameraSettings, BlendSettings, this);
		Player.AttachToComponent(SlingshotActor.HandleParent, n"", EAttachmentRule::KeepWorld);

		ShowCancelPrompt(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SlingshotActor.SetMoveDirection(0, Player);
		SlingshotActor.StopInteracting(Player);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		ConsumeAction(n"ShootMarble");

		if (Player.IsCody())
		{
			Player.RemoveLocomotionFeature(FeatureCody);
		}
		else
		{
			Player.RemoveLocomotionFeature(FeatureMay);
		}

		RemoveCancelPromptByInstigator(Player, this);
		Hidetutorial();

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
	}

	void ShowTutorial()
	{
		if (!bShowTutorial)
			return; 

		else
		{
			FTutorialPrompt Prompt;
			Prompt.Action = AttributeVectorNames::MovementRaw;
			Prompt.DisplayType = ETutorialPromptDisplay::LeftStick_Down;
			Prompt.MaximumDuration = 6;
			Prompt.Mode = ETutorialPromptMode::RemoveWhenPressed;
			
			ShowTutorialPrompt(Player, Prompt, this);
		}
	}

	void Hidetutorial()
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.MovementComponent.CanCalculateMovement())
		{
			FHazeRequestLocomotionData LocomotionDataRequest;
			LocomotionDataRequest.AnimationTag = n"SlingShot";
			Player.RequestLocomotion(LocomotionDataRequest);
		}


		if (Player.HasControl())
		{
			HandleInput();
		}

		float SyncedMoveForce;

		if (Player == SlingshotActor.InteractingPlayerOnLeft)
		{
			SyncedMoveForce = SlingshotActor.LeftPlayerMoveDirection;
		}

		else if (Player == SlingshotActor.InteractingPlayerOnRight)
		{
			SyncedMoveForce = SlingshotActor.RightPlayerMoveDirection;
		}
		HandleAnimationData(SyncedMoveForce);

		if (SlingshotActor.MoveState == ESlingShotMoveState::Pullback)
			Player.SetFrameForceFeedback(0.075f, 0.075f);
	}

	void HandleInput()
	{
		FVector MoveDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		float MoveForce = MoveDirection.DotProduct(SlingshotActor.ActorForwardVector);

		SlingshotActor.SetMoveDirection(MoveForce * -1, Player);
	}

	void HandleAnimationData(float MoveForce)
	{

		if (SlingshotActor.MoveState == ESlingShotMoveState::Pullback)
		{
			AnimData.bPulling = true;
			AnimData.bSliding = false;
			AnimData.bStruggling = false;
		}
		else if (SlingshotActor.MoveState == ESlingShotMoveState::SlideForward)
		{
			AnimData.bPulling = false;
			AnimData.bSliding = true;
			AnimData.bStruggling = false;
		}
		else if (SlingshotActor.MoveState == ESlingShotMoveState::NotMoving)
		{
			if (MoveForce > 0.5f)
			{
				AnimData.bPulling = false;
				AnimData.bSliding = false;
				AnimData.bStruggling = true;
			}

			else
			{
				AnimData.bPulling = false;
				AnimData.bSliding = false;
				AnimData.bStruggling = false;
			}
		}
	}
};