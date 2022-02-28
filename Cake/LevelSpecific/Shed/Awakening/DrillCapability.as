import Cake.LevelSpecific.Shed.Awakening.DrillActor;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
class UDrillCapability : UHazeCapability
{
	AHazePlayerCharacter Player;
	ADrillActor Drill;
	bool bCancel;
	bool bShouldLaunch;

	UPROPERTY()
	UAnimSequence CodySwingMH;

	UPROPERTY()
	UAnimSequence MaySwingMH;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	UForceFeedbackEffect JumpRumble;

	default CapabilityTags.Add(n"LevelSpecific");

	UPROPERTY()
	FText JumpPrompt;

	bool bBothSidesActivatedCapability;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(GetAttributeObject(n"InteractingWithDrill") != nullptr)
		{
			return EHazeNetworkActivation::ActivateLocal;
		}
        
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bCancel && bBothSidesActivatedCapability)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}

		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UObject Object;
		ConsumeAttribute(n"InteractingWithDrill", Object);

		bCancel = false;
		bShouldLaunch = false;
		Drill = Cast<ADrillActor>(Object);

		ShowTutorial();
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		FHazeAnimationDelegate Delegate;

		if (Player.IsCody())
		{
			Player.PlaySlotAnimation(Delegate, Delegate, CodySwingMH, true, BlendTime = 0.f);
		}

		else
		{
			Player.PlaySlotAnimation(Delegate, Delegate, MaySwingMH, true, BlendTime = 0.f);
		}

		Player.PlayCameraShake(CamShake);

		bBothSidesActivatedCapability = false;
		Sync::FullSyncPoint(this, n"BothSidesEnteredDrill");
	}

	UFUNCTION()
	void BothSidesEnteredDrill()
	{
		bBothSidesActivatedCapability = true;
	}

	void ShowTutorial()
	{
		FTutorialPrompt Prompt;
		Prompt.Action = ActionNames::MovementJump;
		Prompt.Mode = ETutorialPromptMode::Default;
		Prompt.DisplayType = ETutorialPromptDisplay::Action;
		Prompt.Text = JumpPrompt;

		ShowTutorialPrompt(Player, Prompt, this);
	}

	void Stoptutorial()
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Stoptutorial();

		Player.Mesh.AttachToComponent(Player.MeshOffsetComponent, AttachmentRule = EAttachmentRule::SnapToTarget);
		Player.StopAllSlotAnimations();
		
		if (bShouldLaunch)
		{
			FHazeJumpToData JumpData;
			JumpData.TargetComponent = Drill.JumpLocation.RootComponent;
			JumpData.AdditionalHeight = Drill.AdditionalHeight;
			JumpData.bKeepVelocity = true;
			JumpTo::ActivateJumpTo(Player, JumpData);

			Player.PlayForceFeedback(JumpRumble, false, true, n"DrillJump");

			FHazePointOfInterest PoISettings;
			PoISettings.FocusTarget.Actor = Player;
			PoISettings.FocusTarget.LocalOffset = FVector(5000.f, 0.f, -2500.f);
			PoISettings.Blend.BlendTime = 1.f;
			PoISettings.Duration = 1.f;
			Player.ApplyPointOfInterest(PoISettings, this);
		}

		Player.StopAllInstancesOfCameraShake(CamShake);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsActioning(ActionNames::MovementJump))
		{
			bCancel = true;
			bShouldLaunch = true;
		}

		Player.SetFrameForceFeedback(0.075f, 0.075f);
	}
}