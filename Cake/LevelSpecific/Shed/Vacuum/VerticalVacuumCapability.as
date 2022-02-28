import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Cake.LevelSpecific.Shed.Vacuum.VerticalVacuum;
import Vino.Movement.Jump.AirJumpsComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Animation.Features.Shed.LocomotionFeatureShedAirBoosted;

class UVerticalVacuumCapability : UCharacterMovementCapability
{
    default CapabilityTags.Add(n"Vacuuum");
	default CapabilityTags.Add(n"LevelSpecific");

    default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 150;

	UPROPERTY()
	AHazePlayerCharacter Player;

	UPROPERTY()
	ULocomotionFeatureShedAirBoosted MayFeature;
	
	UPROPERTY()
	ULocomotionFeatureShedAirBoosted CodyFeature;

	ULocomotionFeatureShedAirBoosted Feature;

	UPROPERTY()
	FText JumpText;

	UPROPERTY()
	FText DashText;

    AVerticalVacuum VerticalVacuum;

	UPROPERTY()
	FHazeTimeLike BobTimeLike;
	default BobTimeLike.bLoop = true;
	default BobTimeLike.Duration = 1.f;

	FVector2D BobRange = FVector2D(-80.f, 80.f);
	float CurrentBobModifier = 0.f;

	FVector TargetLocation;

	float TutorialDelay = 1.5f;

	FTimerHandle DashTutorialTimerHandle;

	bool bAirMovesReset = false;
	bool bAirMovesBlocked = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		Player = Cast<AHazePlayerCharacter>(Owner);

		BobTimeLike.BindUpdate(this, n"UpdateBob");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (!IsActioning(n"VerticalVacuum"))
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (!IsActioning(n"VerticalVacuum"))
		    return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"VertVac", GetAttributeObject(n"VerticalVacuum"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        VerticalVacuum = Cast<AVerticalVacuum>(ActivationParams.GetObject(n"VertVac"));

		BobTimeLike.PlayFromStart();

		DashTutorialTimerHandle = System::SetTimer(this, n"ShowDashTutorial", TutorialDelay, false);

		bAirMovesReset = false;
		ResetAirMoves();

		Feature = Player.IsMay() ? MayFeature : CodyFeature;
		Player.AddLocomotionFeature(Feature);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		BobTimeLike.Stop();

		System::ClearAndInvalidateTimerHandle(DashTutorialTimerHandle);

		RemoveTutorialPromptByInstigator(Player, this);

		if (bAirMovesBlocked)
		{
			bAirMovesBlocked = false;
			Player.UnblockCapabilities(MovementSystemTags::Dash, this);
			Player.UnblockCapabilities(MovementSystemTags::Jump, this);
		}

		Player.RemoveLocomotionFeature(Feature);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!MoveComp.CanCalculateMovement())
			return;

		if (HasControl())
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementDirection) * 5;

			TargetLocation = VerticalVacuum.ActorLocation + VerticalVacuum.TopLocation;
			TargetLocation.Z += CurrentBobModifier;

			if (VerticalVacuum.VacuumMode == EVacuumMode::Suck)
				TargetLocation = VerticalVacuum.ActorLocation;

			FVector Velocity = FMath::VInterpTo(Player.ActorLocation, TargetLocation, DeltaTime, 2.f);
			Velocity = Velocity - Player.ActorLocation;

			Velocity.X += Input.X;
			Velocity.Y += Input.Y;

			if (Input.Size() != 0)
				MoveComp.SetTargetFacingDirection(FVector(Input.X, Input.Y, 0.f).GetSafeNormal(), 8.f);
			else
				MoveComp.SetTargetFacingDirection(Player.ActorForwardVector, 8.f);

			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"VerticalVacuum");
			MoveData.ApplyDelta(Velocity);
			MoveData.ApplyTargetRotationDelta();
			MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
			MoveData.OverrideStepUpHeight(0.f);
			MoveData.OverrideStepDownHeight(0.f);
			MoveCharacter(MoveData, n"AirBoosted");

			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);

			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"VerticalVacuum");
			MoveData.ApplyDelta(ConsumedParams.DeltaTranslation);

			MoveData.ApplyTargetRotationDelta();

			MoveData.OverrideGroundedState(EHazeGroundedState::Airborne);
			MoveData.OverrideStepUpHeight(0.f);
			MoveData.OverrideStepDownHeight(0.f);

			MoveCharacter(MoveData, n"AirBoosted");
		}

		if (!IsActive())
			return;

		if (VerticalVacuum.VacuumMode == EVacuumMode::Suck)
		{
			Player.SetAnimBoolParam(n"Sucking", true);
			if (!bAirMovesBlocked)
			{
				bAirMovesBlocked = true;
				bAirMovesReset = false;
				Player.BlockCapabilities(MovementSystemTags::Dash, this);
				Player.BlockCapabilities(MovementSystemTags::Jump, this);
			}
		}
		else
		{
			Player.SetAnimBoolParam(n"Sucking", false);
			if (bAirMovesBlocked)
			{
				ResetAirMoves();
				bAirMovesBlocked = false;
				Player.UnblockCapabilities(MovementSystemTags::Dash, this);
				Player.UnblockCapabilities(MovementSystemTags::Jump, this);
			}
		}
	}

	UFUNCTION()
	void UpdateBob(float Value)
	{
		CurrentBobModifier = FMath::Lerp(BobRange.X, BobRange.Y, Value);
	}

	UFUNCTION()
    void ShowDashTutorial()
	{
		FTutorialPrompt JumpPrompt;
		JumpPrompt.Action = ActionNames::MovementJump;
		JumpPrompt.Text = JumpText;
		ShowTutorialPrompt(Player, JumpPrompt, this);

		FTutorialPrompt DashPrompt;
		DashPrompt.Action = ActionNames::MovementDash;
		DashPrompt.Text = DashText;
		ShowTutorialPrompt(Player, DashPrompt, this);
	}

	void ResetAirMoves()
	{
		if (bAirMovesReset)
			return;

		if (VerticalVacuum.VacuumMode == EVacuumMode::Blow)
		{
			UCharacterAirJumpsComponent AirJumpComp = UCharacterAirJumpsComponent::Get(Player);
			if (AirJumpComp != nullptr)
			{
				AirJumpComp.ResetJumpAndDash();
				bAirMovesReset = true;
			}
		}
	}
}