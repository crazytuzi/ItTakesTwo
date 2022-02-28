import Cake.LevelSpecific.Clockwork.SplineBoat.SplineBoatActor;

class USplineBoatTurningCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SplineBoatTurn");
	default CapabilityTags.Add(n"SplineBoat");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 110;

	ASplineBoatActor BoatActor;

	float NewTime;
	float TimeRate = 1.f;
	float MinAngle = 0.05f;
	float TurnInterp = 0.05f;

	FVector TurnDirectionTarget;
	FRotator TargetRotation;

	float CurrentRotation;
	FRotator StartRot;
	float OurRotationYaw; 

	bool bCanStartTurn;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BoatActor = Cast<ASplineBoatActor>(Owner);
		BoatActor.TimeLike.BindUpdate(this, n"OnTimeLikeUpdateMate");
		BoatActor.TimeLike.BindFinished(this, n"OnTimeLikeFinished");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BoatActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (BoatActor.SplineStatus != EHazeUpdateSplineStatusType::AtEnd)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"IsTurningSpline"))
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BoatActor.BlockCapabilities(n"SplineBoatMovement", BoatActor);
		BoatActor.SetCapabilityActionState(n"IsTurningSpline", EHazeActionState::Active);

		BoatActor.SplineFollowComponent.Reverse();
		BoatActor.SplineStatus = EHazeUpdateSplineStatusType::Valid;

		NewTime = System::GameTimeInSeconds + TimeRate;

		TurnDirectionTarget = -BoatActor.GetActorForwardVector();
		TargetRotation = FRotator::MakeFromX(TurnDirectionTarget);
		StartRot = BoatActor.ActorRotation;
		OurRotationYaw = StartRot.Yaw;

		if (BoatActor.Turntable != nullptr)
			BoatActor.Turntable.AttachBoatState(BoatActor, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		BoatActor.UnblockCapabilities(n"SplineBoatMovement", BoatActor);
		bCanStartTurn = false;

		if (BoatActor.Turntable != nullptr)
			BoatActor.Turntable.AttachBoatState(BoatActor, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (NewTime < System::GameTimeInSeconds && !bCanStartTurn)
		{
			bCanStartTurn = true;
			BoatActor.TimeLike.PlayFromStart();
		}
	}

	UFUNCTION()
	void OnTimeLikeUpdateMate(float Value)
	{
		float TurnAngle = FMath::Abs((OurRotationYaw - TargetRotation.Yaw) * Value);
		FRotator NewRot = FRotator(BoatActor.ActorRotation.Pitch, OurRotationYaw + TurnAngle, BoatActor.ActorRotation.Roll);
		BoatActor.SetActorRotation(NewRot);
	}

	UFUNCTION()
	void OnTimeLikeFinished()
	{
		BoatActor.SetCapabilityActionState(n"IsTurningSpline", EHazeActionState::Inactive);
	}
}