import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatPlayerComponent;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatPlayerAttachComponent;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatActor;


class USplineBoatPlayerPeddlingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SplineBoatPlayerPeddling");
	default CapabilityTags.Add(n"SplineBoat");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	USplineBoatPlayerComponent PlayerComp;

	USplineBoatPlayerAttachComponent PlayerAttachComp;

	ASplineBoatActor SplineBoat;

	float StartTime;
	float StartRate = 0.4f;

	bool bIsPeddling;

	FVector2D RightInput;
	FVector2D PreviousInput;

	float MaxSpeed = 400.f;

	bool bForwardMovement;
	bool bBackwardMovement;

	bool bCanCancel;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = USplineBoatPlayerComponent::GetOrCreate(Player);
		PlayerAttachComp = USplineBoatPlayerAttachComponent::GetOrCreate(Player);
		bCanCancel = false;
		System::SetTimer(this, n"DelayedCanCancel", 0.4f, false);
	}

	UFUNCTION()
	void DelayedCanCancel()
	{
		bCanCancel = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel) && bCanCancel)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::GameplayAction, this);
		Player.BlockCapabilities(n"CharacterSequenceTeleportCapability", this);
		Player.BlockCapabilities(n"CharacterTimeControlCapability", this);

		Player.CleanupCurrentMovementTrail();
		Player.SmoothSetLocationAndRotation(PlayerComp.LockedPosition, PlayerComp.RotatedPosition, 0.8f, 0.8f);
		Player.TriggerMovementTransition(this); 

		PlayerAttachComp.ChangeAttach(PlayerComp.BoatRef, true);
		
		ShowCancelPrompt(Player, this); 
		
		StartTime = System::GameTimeInSeconds + StartRate;

		if (Player.IsCody())
			Player.AddLocomotionFeature(PlayerComp.CodyLocomotion);
		else
			Player.AddLocomotionFeature(PlayerComp.MayLocomotion);

		if (!PlayerComp.bHaveCompletedTutorial && HasControl())
			PlayerComp.ShowRightPrompt(Player);

		SplineBoat = Cast<ASplineBoatActor>(PlayerComp.BoatRef);

		Player.OtherPlayer.DisableOutlineByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel); 
		
		Player.UnblockCapabilities(CapabilityTags::GameplayAction, this);
		Player.UnblockCapabilities(n"CharacterSequenceTeleportCapability", this);
		Player.UnblockCapabilities(n"CharacterTimeControlCapability", this);

		PlayerComp.CancelBoatAction.Execute(PlayerComp.OurInteractionComp); 
		PlayerAttachComp.ChangeAttach(PlayerComp.BoatRef, false);
		RemoveCancelPromptByInstigator(Player, this);
		PlayerComp.TargetSpeed = 0.f;

		if (Player.IsCody())
			Player.RemoveLocomotionFeature(PlayerComp.CodyLocomotion);
		else
			Player.RemoveLocomotionFeature(PlayerComp.MayLocomotion);	

		PlayerComp.RemovePrompts(Player);
		Player.OtherPlayer.EnableOutlineByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeRequestLocomotionData LocoMotionRequestData;
		LocoMotionRequestData.AnimationTag = n"PedalBoat";

		if (Player.Mesh.CanRequestLocomotion())
			Player.RequestLocomotion(LocoMotionRequestData);

		float Input = FMath::Clamp(-GetAttributeValue(AttributeNames::SecondaryLevelAbilityAxis) + GetAttributeValue(AttributeNames::PrimaryLevelAbilityAxis), -1.f, 1.f);

		if (!bForwardMovement && !PlayerComp.bHaveCompletedTutorial)
		{
			if (Input < 0.f)
				Input = 0.f;
		}

		float TargetSpeed = Input * MaxSpeed;

		if (PlayerComp.bIsSlow)
			TargetSpeed *= 0.35f;

		if (HasControl())
			TutorialCheck(Input);

		if (StartTime <= System::GameTimeInSeconds)
		{
			StartTime = System::GameTimeInSeconds + StartRate;

			if (HasControl())
				NetUpdateTargetSpeed(TargetSpeed);
		}
	}

	UFUNCTION()
	void TutorialCheck(float Input)
	{
		if (PlayerComp.bHaveCompletedTutorial)
			return;
			
		if (Input > 0.f && !bForwardMovement)
			bForwardMovement = true;

		if (Input < 0.f && !bBackwardMovement && bForwardMovement)
			bBackwardMovement = true;

		PrintToScreen("" + Player + " bForwardMovement: " + bForwardMovement);
		PrintToScreen("" + Player + " bBackwardMovement: " + bBackwardMovement);

		if (bBackwardMovement)
		{
			PlayerComp.RemovePrompts(Player);	

			if (!bForwardMovement)
				PlayerComp.ShowRightPrompt(Player);
		}

		if (bForwardMovement)
		{
			PlayerComp.RemovePrompts(Player);

			if (!bBackwardMovement)
				PlayerComp.ShowLeftPrompt(Player);			
		}

		if (bBackwardMovement && bForwardMovement)
		{
			PlayerComp.bHaveCompletedTutorial = true;
		}
	}

	UFUNCTION(NetFunction)
	void NetUpdateTargetSpeed(float Speed)
	{ 
		PlayerComp.TargetSpeed = Speed;
	}

	// UFUNCTION(NetFunction)
	// void NetBHasExit(bool InputbHasExited)
	// {
	// 	bHasExited = InputbHasExited;
	// }

	UFUNCTION()
	void CanDeactivatePeddle()
	{
		PlayerComp.bIsInBoat = false;
	}
}