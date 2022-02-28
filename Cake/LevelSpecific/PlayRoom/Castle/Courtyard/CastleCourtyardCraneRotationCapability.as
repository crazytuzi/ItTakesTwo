import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CastleCourtyardCraneActor;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Audio.AudioStatics;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureRotateCrane;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneWreckingBall;

class UCastleCourtyardCraneRotationCapability : UHazeCapability
{
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayCraneRotationAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopCraneRotationAudioEvent;
	
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 40;

	AHazePlayerCharacter Player;
	UHazeBaseMovementComponent Movement;
	ACastleCourtyardCraneActor Crane;
	USceneComponent AttachComponent;
	FHazePointOfInterest PointOfInterest;
	FHazeCameraBlendSettings Blend;

	UPROPERTY()
	TPerPlayer<FCraneRotationAnimations> Animations;
	UPROPERTY()
	TPerPlayer<ULocomotionFeatureRotateCrane> Features;
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

		if (Crane.PlayerRotatingCrane != Player)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bEnterAnimationFinished)
			return EHazeNetworkDeactivation::DontDeactivate;

		if(IsActioning(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
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
		Player.AttachToComponent(Crane.CraneRotationInteractComp, AttachmentRule = EAttachmentRule::SnapToTarget);

		Crane.SyncedTargetYaw.OverrideControlSide(Owner);

		// Enter animation
		FHazeAnimationDelegate OnEnterFinished;
		OnEnterFinished.BindUFunction(this, n"OnEnterFinished");
		Player.PlaySlotAnimation(OnBlendingOut = OnEnterFinished, Animation = Animations[Player].Enter);

		Player.AddLocomotionFeature(Features[Player]);

		// Stick tutorial
		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
		ShowTutorialPrompt(Player, TutorialPrompt, this);
		ShowCancelPrompt(Player, this);

		// Audio
		HazeAudio::SetPlayerPanning(Crane.CraneBaseHazeAkComp, Player);
		Crane.CraneBaseHazeAkComp.HazePostEvent(PlayCraneRotationAudioEvent);		
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
		Player.PlayEventAnimation(Animation = Animations[Player].Exit);
		
		// Tutorial / cancel
		RemoveTutorialPromptByInstigator(Player, this); 
		RemoveCancelPromptByInstigator(Player, this);

		Crane.CraneBaseHazeAkComp.HazePostEvent(StopCraneRotationAudioEvent);

		Crane.CraneRotationDeactivated(Player);

		if (Crane.CurrentAttachedActor == nullptr)
			return;
		ACourtyardCraneWreckingBall WreckingBall = Cast<ACourtyardCraneWreckingBall>(Crane.CurrentAttachedActor);
		if (WreckingBall == nullptr)
			return;
		WreckingBall.PlayersInteractingWithCrane[Player] = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bEnterAnimationFinished)
			return;

		// Update target crane target direction
		if (HasControl() && !Crane.bBallAttachmentInProgress)
		{
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);
			float InputStrength = Input.DotProduct(Owner.ActorForwardVector);

			float NewTargetYaw = Crane.SyncedTargetYaw.Value + (Crane.RotationSettings.RotationRate * InputStrength * DeltaTime);
			NewTargetYaw = FMath::Clamp(NewTargetYaw, -Crane.MaximumRotation, 0.f);

			Crane.SyncedTargetYaw.Value = NewTargetYaw;
		}

		// Animate based off of rotation speed
		float RotationSpeed = Crane.AcceleratedYaw.Velocity;
		float RotationSpeedPercentage = FMath::Clamp(RotationSpeed / Crane.RotationSettings.RotationRate, -1.f, 1.f);

		float RotationSpeedNormalized = FMath::GetMappedRangeValueClamped(FVector2D(-25.f, 25.f), FVector2D(-1.f, 1.f), RotationSpeed);

		Crane.CraneBaseHazeAkComp.SetRTPCValue("Rtpc_Castle_Courtyard_Interactable_Crane_RotationSpeed", RotationSpeedNormalized);

		Player.SetAnimFloatParam(n"Direction", RotationSpeedPercentage);

		FHazeRequestLocomotionData Request;
		Request.AnimationTag = n"RotateCrane";
		Player.RequestLocomotion(Request);

		if (Crane.CurrentAttachedActor == nullptr)
			return;
		ACourtyardCraneWreckingBall WreckingBall = Cast<ACourtyardCraneWreckingBall>(Crane.CurrentAttachedActor);
		if (WreckingBall == nullptr)
			return;
		WreckingBall.PlayersInteractingWithCrane[Player] = true;
	}

	UFUNCTION()
	void OnEnterFinished()
	{
		ShowCancelPrompt(Player, this);
		bEnterAnimationFinished = true;
	}

	UFUNCTION(NetFunction)
	void NetPlayPushAnim(UAnimSequence NewAnimToPlay)
	{
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(), NewAnimToPlay, true);
	}
}