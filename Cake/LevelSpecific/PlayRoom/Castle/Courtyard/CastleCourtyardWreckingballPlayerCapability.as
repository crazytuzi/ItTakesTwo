import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CourtyardCraneWreckingBall;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureBowlingBallHanging;
import Vino.Movement.Jump.AirJumpsComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.CastleCourtyardCraneActor;
import Peanuts.SpeedEffect.SpeedEffectStatics;

class UCastleCourtyardWreckingballPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 50;

	AHazePlayerCharacter Player;
	UHazeBaseMovementComponent Movement;
	UCharacterAirJumpsComponent AirJumpsComp;
	ACastleCourtyardCraneActor Crane;

	ACourtyardCraneWreckingBall WreckingBall;
	USceneComponent AttachComponent;
	UInteractionComponent InteractComp;
	
	TPerPlayer<UHazeSmoothSyncFloatComponent> AccelerationStrengthSyncFloatComp;
	
	UPROPERTY()
	TPerPlayer<ULocomotionFeatureBowlingBallHanging> PlayerFeatures;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Movement = UHazeBaseMovementComponent::GetOrCreate(Player);
		AirJumpsComp = UCharacterAirJumpsComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!IsActioning(n"SwingingWreckingBall"))
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"BallActor", GetAttributeObject(n"BallActor"));
		OutParams.AddObject(n"AttachComp", GetAttributeObject(n"AttachComp"));
		OutParams.AddObject(n"InteractComp", GetAttributeObject(n"InteractComp"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		ConsumeAction(n"SwingingWreckingBall");

		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(CapabilityTags::MovementAction, this);
		
		Player.BlockMovementSyncronization(this);
		Player.CleanupCurrentMovementTrail();

		WreckingBall = Cast<ACourtyardCraneWreckingBall>(ActivationParams.GetObject(n"BallActor"));
		AttachComponent = Cast<USceneComponent>(ActivationParams.GetObject(n"AttachComp"));
		InteractComp = Cast<UInteractionComponent>(ActivationParams.GetObject(n"InteractComp"));
		Player.AttachToComponent(AttachComponent, AttachmentRule = EAttachmentRule::SnapToTarget);

		Crane = Cast<ACastleCourtyardCraneActor>(WreckingBall.CraneActorRef);

		AccelerationStrengthSyncFloatComp[0] = WreckingBall.MayAccelerationStrengthSyncFloat;
		AccelerationStrengthSyncFloatComp[1] = WreckingBall.CodyAccelerationStrengthSyncFloat;

		AirJumpsComp.ResetJumpAndDash();

		// Animations
		Player.AddLocomotionFeature(PlayerFeatures[Player]);

		// Tutorial
		FTutorialPrompt UpDownPrompt;
		UpDownPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
		ShowTutorialPrompt(Player, UpDownPrompt, this);
		ShowCancelPrompt(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		if (!WasActionStarted(ActionNames::Cancel))
			return;
		if (!FMath::IsNearlyEqual(-Crane.DoorRotation, Crane.AcceleratedYaw.Value, Crane.AlignSettings.AcceptanceAngle))
			return;

		OutParams.AddActionState(n"Cancelled");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);

		Player.SetCapabilityActionState(n"SwingingWreckingBall", EHazeActionState::Inactive);
		Player.UnblockMovementSyncronization(this);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		WreckingBall.BallDeactivated(InteractComp);

		RemoveTutorialPromptByInstigator(Player, this);
		RemoveCancelPromptByInstigator(Player, this);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		Player.RemoveLocomotionFeature(PlayerFeatures[Player]);

		AccelerationStrengthSyncFloatComp[Player].Value = 0.f;			

		if (DeactivationParams.GetActionState(n"Cancelled"))
		{
			FHazeJumpToData JumpToData;
			JumpToData.Transform = WreckingBall.CancelJumpToLocation.ActorTransform;
			JumpTo::ActivateJumpTo(Player, JumpToData);
		}

		FSpeedEffectRequest Request;
		Request.Instigator = this;
		Request.bSnap = true;
		Request.Value = 0.f;
		SpeedEffect::RequestSpeedEffect(Player, Request);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Player.Mesh.CanRequestLocomotion())
		{
			FHazeRequestLocomotionData Request;
			Request.AnimationTag = n"WreckingBallHanging";
			Player.RequestLocomotion(Request);
		}

		FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

		// Update blend space value
		UHazeSmoothSyncFloatComponent BSSyncFloatComp = Player.IsMay() ? WreckingBall.MayBSSyncFloat : WreckingBall.CodyBSSyncFloat;
		if (HasControl())	
			BSSyncFloatComp.Value = Input.DotProduct(WreckingBall.ActorForwardVector);	
		Player.SetAnimFloatParam(n"PlayerInput", BSSyncFloatComp.Value);

		FSpeedEffectRequest Request;
		Request.Instigator = this;
		Request.Value = WreckingBall.AngularVelocity.Size() * 5.f;
		SpeedEffect::RequestSpeedEffect(Player, Request);

		if(!HasControl())
			return;

		/*
			Create a 0-1 scale for the correctness of the input.
			Consider anything on the correct side as completely in the correct direction to make it less prone to input errors
		*/
		FVector Direction = WreckingBall.ActorForwardVector;

		if (!FMath::IsNearlyZero(WreckingBall.AngularVelocity.DotProduct(WreckingBall.ActorRightVector), 0.01f))
		{
			Direction = FVector::UpVector.CrossProduct(WreckingBall.AngularVelocity);
			Direction = Direction.ConstrainToDirection(WreckingBall.ActorForwardVector);
		}

		float CorrectInputScale = Direction.DotProduct(Input);
		CorrectInputScale = FMath::Sign(CorrectInputScale);
		CorrectInputScale *= Input.Size();

		AccelerationStrengthSyncFloatComp[Player].Value = CorrectInputScale;
	}
}