import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CastleCourtyardCraneActor;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Audio.AudioStatics;
import Vino.Animations.ThreeShotAnimation;

class UCastleCourtyardCraneHeightCapability : UHazeCapability
{
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayCraneHeightAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopCraneHeightAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayPulleytAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopPulleyAudioEvent;
	
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 40;

	AHazePlayerCharacter Player;
	UHazeBaseMovementComponent Movement;
	ACastleCourtyardCraneActor Crane;
	USceneComponent AttachComponent;

	UPROPERTY(Category = "Setup")
	TPerPlayer<FCraneThreeShotSequence> Animations;
	bool bEnterAnimationFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Movement = UHazeBaseMovementComponent::GetOrCreate(Player);		
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (HasControl() && Crane == nullptr && !IsActive())
			Crane = Cast<ACastleCourtyardCraneActor>(GetAttributeObject(n"CraneActor"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Crane == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (Crane.PlayerControllingHeight != Player)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bEnterAnimationFinished)
			return EHazeNetworkDeactivation::DontDeactivate;

		if (!IsActioning(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"CraneActor", Crane);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Crane = Cast<ACastleCourtyardCraneActor>(ActivationParams.GetObject(n"CraneActor"));

		// Capability blocks
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::MovementAction,this);

		// Attach and cleanup crumbs
		Player.TriggerMovementTransition(this);
		Player.AttachToComponent(Crane.CraneHeightInteractionComp, AttachmentRule = EAttachmentRule::SnapToTarget);

		Crane.SyncedTargetConstrainLength.OverrideControlSide(Owner);

		// Enter animation
		FHazeAnimationDelegate OnEnterFinished;
		OnEnterFinished.BindUFunction(this, n"OnEnterFinished");
		Player.PlaySlotAnimation(OnBlendingOut = OnEnterFinished, Animation = Animations[Player].Enter);

		// Stick tutorial
		FTutorialPrompt UpDownPrompt;
		UpDownPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
		ShowTutorialPrompt(Player, UpDownPrompt, this);		

		// Audio
		HazeAudio::SetPlayerPanning(Crane.CraneTopHazeAkComp, Player);
		Crane.CraneTopHazeAkComp.HazePostEvent(PlayCraneHeightAudioEvent);
		Crane.PulleyHazeAkComp.HazePostEvent(PlayPulleytAudioEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		// Capability Unblocks
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction,this);
		
		bEnterAnimationFinished = false;
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		// Exit animation
		Player.StopAllSlotAnimations();
		Player.PlayEventAnimation(Animation = Animations[Player].Exit);

		// Tutorial / cancel
		RemoveTutorialPromptByInstigator(Player, this);
		RemoveCancelPromptByInstigator(Player, this);
		
		// Audio
		Crane.CraneTopHazeAkComp.HazePostEvent(StopCraneHeightAudioEvent);
		Crane.PulleyHazeAkComp.HazePostEvent(StopPulleyAudioEvent);

		Crane.CraneHeightDeactivated(Player);

		if (Crane.CurrentAttachedActor == nullptr)
			return;
		ACourtyardCraneWreckingBall WreckingBall = Cast<ACourtyardCraneWreckingBall>(Crane.CurrentAttachedActor);
		if (WreckingBall == nullptr)
			return;
		WreckingBall.PlayersInteractingWithCrane[Player] = false;
	}

	UFUNCTION()
	void OnEnterFinished()
	{
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), Animations[Player].MH, true, PlayRate = 0.f);

		ShowCancelPrompt(Player, this);
		bEnterAnimationFinished = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bEnterAnimationFinished)
			return;

		if (HasControl() && !Crane.bBallAttachmentInProgress)
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			float InputStrength = -Input.Y;

			float NewConstraintLength = Crane.SyncedTargetConstrainLength.Value + (Crane.ConstraintSettings.LengthAdjustRate * InputStrength * DeltaTime);			
			Crane.SyncedTargetConstrainLength.Value = FMath::Clamp(NewConstraintLength, Crane.ConstraintSettings.MinimumLength, Crane.ConstraintSettings.MaximumLength);
		}
		
		Crane.CrankProgress += Crane.AcceleratedConstraintLength.Velocity * DeltaTime * 0.005f;
		Crane.CrankProgress = Crane.CrankProgress % 1.f;
		if (Crane.CrankProgress < 0.f)
			Crane.CrankProgress = 1.f + Crane.CrankProgress;

		// Update rope on the crane
		Crane.CraneMesh.SetScalarParameterValueOnMaterialIndex(2, n"Scroll Speed Y", 7.5f);
		Crane.CraneMesh.SetScalarParameterValueOnMaterialIndex(2, n"CustomTime", Crane.CrankProgress);

		// Update the cable comp material that connects to the magnet
		float MagicNumber = 650;
		float Tiling = 1000;
		float TilingValue = (Crane.AcceleratedConstraintLength.Value - MagicNumber) / Tiling;
		Crane.CableComp.SetScalarParameterValueOnMaterials(n"Tiling X", TilingValue);

		Player.SetSlotAnimationPosition(Animations[Player].MH, Crane.CrankProgress);

		float HeightAdjustSpeed = Crane.AcceleratedConstraintLength.Velocity;
		float HeightSpeedNormalized = FMath::GetMappedRangeValueClamped(FVector2D(-250, 250), FVector2D(-1, 1), HeightAdjustSpeed);
		Crane.CraneTopHazeAkComp.SetRTPCValue("Rtpc_Castle_Courtyard_Interactable_Crane_HeightSpeed", HeightSpeedNormalized);
		Crane.PulleyHazeAkComp.SetRTPCValue("Rtpc_Castle_Courtyard_Interactable_Crane_HeightSpeed", HeightSpeedNormalized);

		if (Crane.CurrentAttachedActor == nullptr)
			return;
		ACourtyardCraneWreckingBall WreckingBall = Cast<ACourtyardCraneWreckingBall>(Crane.CurrentAttachedActor);
		if (WreckingBall == nullptr)
			return;
		WreckingBall.PlayersInteractingWithCrane[Player] = true;
	}
}