
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.MovementSystemTags;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureZeroGravity;
import Vino.Tutorial.TutorialStatics;
import Vino.Tutorial.TutorialPrompt;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeComponent;

class UCharacterZeroGravityCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Gravity");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100.f;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UHazeAkComponent HazeAkComp;

	float DefaultVerticalSpeed = 2500.f;
	float DefaultHorizontalSpeed = 1650.f;
	float VerticalSpeed = 2500.f;
	float HorizontalSpeed = 1650.f;

	float HorizontalInterpSpeed = 2000.f;
	float VerticalInterpSpeed = 3500.f;

	float XBlendValue = 0.f;
	float YBlendValue = 0.f;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureZeroGravity CodyZeroGFeature;
	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureZeroGravity MayZeroGFeature;

	UPROPERTY()
	FText UpText;

	UPROPERTY()
	FText DownText;

	UFUNCTION()
	void OnResetSyncLocation()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);
		HazeAkComp = UHazeAkComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"ZeroG") && !MoveComp.IsGrounded() && MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::ActivateLocal;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"ZeroG") || MoveComp.IsGrounded() || !MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UCharacterChangeSizeComponent ChangeSizeComp = UCharacterChangeSizeComponent::Get(Player);
		if (ChangeSizeComp != nullptr)
			Player.SetCapabilityActionState(n"ForceResetSize", EHazeActionState::ActiveForOneFrame);

		ConsumeAttribute(n"ZeroGVerticalSpeed", VerticalSpeed);
		ConsumeAttribute(n"ZeroGHorizontalSpeed", HorizontalSpeed);
		FVector NewVelocity = MoveComp.Velocity/2;
		MoveComp.SetVelocity(NewVelocity);

		Owner.BlockCapabilities(MovementSystemTags::GroundPound, this);
		Owner.BlockCapabilities(MovementSystemTags::WallSlide, this);
		Owner.BlockCapabilities(MovementSystemTags::WallRun, this);
		Owner.BlockCapabilities(CapabilityTags::TotemMovement, this);
		
		Player == Game::GetCody() ? Player.AddLocomotionFeature(CodyZeroGFeature) : Player.AddLocomotionFeature(MayZeroGFeature);

		if (IsActioning(n"ZeroGTutorial"))
		{
			FTutorialPrompt UpPrompt;
			UpPrompt.Action = ActionNames::MovementJump;
			UpPrompt.Text = UpText;
			ShowTutorialPrompt(Player, UpPrompt, this);

			FTutorialPrompt DownPrompt;
			DownPrompt.Action = ActionNames::MovementCrouch;
			DownPrompt.Text = DownText;
			ShowTutorialPrompt(Player, DownPrompt, this);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		VerticalSpeed = DefaultVerticalSpeed;
		HorizontalSpeed = DefaultHorizontalSpeed;
		Owner.UnblockCapabilities(MovementSystemTags::GroundPound, this);
		Owner.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		Owner.UnblockCapabilities(MovementSystemTags::WallRun, this);
		Owner.UnblockCapabilities(CapabilityTags::TotemMovement, this);

		Player == Game::GetCody() ? Player.RemoveLocomotionFeature(CodyZeroGFeature) : Player.RemoveLocomotionFeature(MayZeroGFeature);

		RemoveTutorialPromptByInstigator(Player, this);

		if (!MoveComp.IsGrounded())
		{
			float VerticalImpulse = MoveComp.VerticalVelocity;
			VerticalImpulse = FMath::Clamp(VerticalImpulse, 750.f, 1000.f);
			Player.AddImpulse(MoveComp.WorldUp * VerticalImpulse);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (Owner.HasControl())
		{
			FVector HorizontalInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
			FVector VerticalInput = CalculateVerticalInput();
			HorizontalInput /= Owner.ActorScale3D.Z;
			VerticalInput /= Owner.ActorScale3D.Z;

			FVector Velocity = CalculateVelocity(HorizontalInput, VerticalInput, DeltaTime);
			SetAnimationValues(DeltaTime, Velocity);
			
			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"ZeroGravity");
			MoveData.ApplyVelocity(Velocity);
			if (Velocity.GetSafeNormal().Size() != 0)
				MoveComp.SetTargetFacingDirection(Velocity.GetSafeNormal(), 5.f);
			else
				MoveComp.SetTargetFacingDirection(MoveComp.TargetFacingRotation.Vector(), 1.f);
			MoveData.ApplyTargetRotationDelta();
			MoveData.OverrideStepDownHeight(0.f);
			MoveCharacter(MoveData, n"ZeroGravity");
			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"ZeroGravity");
			MoveData.ApplyDelta(ConsumedParams.DeltaTranslation);

			FRotator TargetRot = ConsumedParams.Rotation;
			MoveComp.SetTargetFacingRotation(TargetRot, 5.f);
			MoveData.ApplyTargetRotationDelta();

			MoveCharacter(MoveData, n"ZeroGravity");
		}

		UpdateAudioParameters();
	}

	FVector CalculateVerticalInput()
	{
		float VerticalDirection = 0.f;
		if (IsActioning(ActionNames::MovementJump))
			VerticalDirection += 1;
		if (IsActioning(ActionNames::MovementCrouch))
			VerticalDirection -= 1;

		return MoveComp.WorldUp * VerticalDirection;
	}

	FVector CalculateVelocity(FVector HorizontalInput, FVector VerticalInput, float DeltaTime)
	{
		FVector CurrentVelocity = MoveComp.Velocity;
		FVector ConstrainedVertical = Math::ConstrainVectorToDirection(CurrentVelocity, MoveComp.WorldUp);
		FVector ConstrainedHorizontal = Math::ConstrainVectorToPlane(CurrentVelocity, MoveComp.WorldUp);

		FVector HSpeed = HorizontalInput * HorizontalSpeed;
		FVector VSpeed = VerticalInput * VerticalSpeed;
		
		FVector HorizontalVelocity = FMath::VInterpConstantTo(ConstrainedHorizontal, HSpeed, DeltaTime, HorizontalInterpSpeed);
		FVector VerticalVelocity = FMath::VInterpConstantTo(ConstrainedVertical, VSpeed, DeltaTime, VerticalInterpSpeed);

		FVector NewVelocity = HorizontalVelocity + VerticalVelocity;

		return NewVelocity;
	}

	void SetAnimationValues(float DeltaTime, FVector Velocity)
	{
		FVector LocalVelocity = Owner.ActorTransform.InverseTransformVector(Velocity);

		float BlendX = 0.f;
		float BlendY = -(LocalVelocity.X / VerticalSpeed) * 100.f;

		XBlendValue = FMath::FInterpConstantTo(XBlendValue, BlendX, DeltaTime, 25.f);
		YBlendValue = FMath::FInterpConstantTo(YBlendValue, BlendY, DeltaTime, 25.f);

		Owner.SetAnimFloatParam(AnimationFloats::LocomotionBlendSpaceX, XBlendValue);
		Owner.SetAnimFloatParam(AnimationFloats::LocomotionBlendSpaceY, YBlendValue);
	}

	void UpdateAudioParameters()
	{
		FVector PlayerVelocity = Player.ActualVelocity;

		float VerticalVelocity = PlayerVelocity.Z;
		VerticalVelocity = VerticalVelocity/VerticalSpeed;
		HazeAkComp.SetRTPCValue("Rtpc_World_Shared_Platform_GravityVolume_Move_Vertical", VerticalVelocity);

		float HorizontalVelocity = Math::ConstrainVectorToPlane(PlayerVelocity, FVector::UpVector).Size();
		HorizontalVelocity = HorizontalVelocity/HorizontalSpeed;
		HazeAkComp.SetRTPCValue("Rtpc_World_Shared_Platform_GravityVolume_Move_Horizontal", HorizontalVelocity);
	}
}
