import Cake.LevelSpecific.PlayRoom.SpaceStation.PlasmaBall;
import Peanuts.Animation.Features.LocomotionFeaturePlasmaBall;
import Vino.Tutorial.TutorialStatics;

class UMovePlasmaBallCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 8;

	AHazePlayerCharacter Player;
    APlasmaBall PlasmaBall;

	UPROPERTY()
	UBlendSpace PushBlendSpace;

	FVector2D CurrentBlendSpaceValue;

	UPROPERTY()
	ULocomotionFeaturePlasmaBall PlasmaBallFeature;

	UPROPERTY(NotVisible)
	FVector2D DirectionInput;

	bool bEnterAnimationFinished = false;

	FVector2D ReplicaBSValues;
	FTimerHandle BSReplicaTimer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"MovingPlasmaBall"))
            return EHazeNetworkActivation::ActivateUsingCrumb;
        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (WasActionStarted(ActionNames::Cancel) && bEnterAnimationFinished)
		    return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		else
		    return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"PlasmaBall", GetAttributeObject(n"PlasmaBall"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.SetCapabilityActionState(n"MovingPlasmaBall", EHazeActionState::Inactive);
        PlasmaBall = Cast<APlasmaBall>(ActivationParams.GetObject(n"PlasmaBall"));
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		SetMutuallyExclusive(CapabilityTags::GameplayAction, true);
		Player.AttachToActor(PlasmaBall, AttachmentRule = EAttachmentRule::KeepWorld);
		Player.TriggerMovementTransition(this);
		FHazeAnimationDelegate OnEnterFinished;
		OnEnterFinished.BindUFunction(this, n"EnterFinished");
		Player.PlaySlotAnimation(OnBlendingOut = OnEnterFinished, Animation = PlasmaBallFeature.PlasmaBallEnter);
		Player.ApplyIdealDistance(1500.f, FHazeCameraBlendSettings(2.f), this);
		Player.ApplyPivotOffset(FVector(0.f, 0.f, 500.f), FHazeCameraBlendSettings(2.f), this);

		FVector Dir = (Player.ActorLocation - PlasmaBall.ActorLocation);
		Dir = Math::ConstrainVectorToPlane(Dir, FVector::UpVector);
		Dir.Normalize();

		TArray<AActor> IgnoreActors;
		IgnoreActors.Add(Game::GetMay());
		IgnoreActors.Add(Game::GetCody());

		FVector Loc;
		bool bLeftTrace = true;
		for (int Index = 0, Count = 360/5; Index < Count; ++ Index)
		{
			FHitResult Hit;
			float AngleOffset = Index * 5;
			if (bLeftTrace)
				AngleOffset *= -1.f;
			Dir = Dir.RotateAngleAxis(AngleOffset, FVector::UpVector);
			Loc = PlasmaBall.ActorLocation + (Dir * 720);
			Loc += FVector(0.f, 0.f, Game::GetCody().CapsuleComponent.GetScaledCapsuleHalfHeight() + 5.f);
			Loc.Z -= 500.f;
			System::CapsuleTraceSingle(Loc, Loc + FVector(0.f, 0.f, 1.f), Game::GetCody().CapsuleComponent.GetScaledCapsuleRadius(), Game::GetCody().CapsuleComponent.GetScaledCapsuleHalfHeight(), ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, Hit, true);
			FHitResult DownHit;
			System::LineTraceSingle(Loc, Loc - FVector(0.f, 0.f, 600.f), ETraceTypeQuery::Visibility, false, IgnoreActors, EDrawDebugTrace::None, DownHit, true);
			bLeftTrace = !bLeftTrace;
			if (!Hit.bBlockingHit && DownHit.bBlockingHit)
				break;
		}

		Loc.Z = PlasmaBall.ActorLocation.Z - 500.f;
		FVector InverseDir = -Dir;
		Player.SmoothSetLocationAndRotation(Loc, InverseDir.Rotation());

		if (Player.HasControl())
			BSReplicaTimer = System::SetTimer(this, n"UpdateBlendSpaceValues", 0.1f, true);

		ShowCancelPrompt(Player, this);
	}

	UFUNCTION()
	void UpdateBlendSpaceValues()
	{
		NetUpdateBlendSpaceValues(ReplicaBSValues);
	}

	UFUNCTION(NetFunction)
	void NetUpdateBlendSpaceValues(FVector2D BSValues)
	{
		ReplicaBSValues = BSValues;
	}

	UFUNCTION()
	void EnterFinished()
	{
		Player.PlayBlendSpace(PlasmaBallFeature.PlasmaBallBS);
		bEnterAnimationFinished = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::MovementGroundPound);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		SetMutuallyExclusive(CapabilityTags::GameplayAction, false);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Player.StopBlendSpace();
		Player.PlayEventAnimation(Animation = PlasmaBallFeature.PlasmaBallExit);
		PlasmaBall.InteractionCanceled();
		bEnterAnimationFinished = false;
		Player.ClearIdealDistanceByInstigator(this, 2.f);
		Player.ClearPivotOffsetByInstigator(this, 2.f);

		RemoveTutorialPromptByInstigator(Player, this);
		RemoveCancelPromptByInstigator(Player, this);

		System::ClearAndInvalidateTimerHandle(BSReplicaTimer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!bEnterAnimationFinished)
			return;

		if (HasControl())
		{
			DirectionInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);
			PlasmaBall.UpdatePlayerInput(DirectionInput);

			FVector Dir = PlasmaBall.MovementDirection;
			FVector Vec = Dir.CrossProduct(Player.ActorRightVector);
			FVector Vec2 = Dir.CrossProduct(Player.ActorForwardVector);
			FVector NewVec = FVector(-Vec2.Z, Vec.Z, 0.f);
			ReplicaBSValues = FVector2D(NewVec.X, NewVec.Y);
			
			if (DirectionInput.Size() != 0.f)
				Player.SetFrameForceFeedback(0.1f, 0.f);
		}
		
		Player.SetBlendSpaceValues(ReplicaBSValues.X, ReplicaBSValues.Y);
	}
}