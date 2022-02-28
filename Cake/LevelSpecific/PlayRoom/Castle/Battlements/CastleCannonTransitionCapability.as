import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonShooterComponent;
import Cake.LevelSpecific.PlayRoom.Castle.Battlements.CastleCannonTransition;

class UCastleCannonTransitionCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Cannon";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UCastleCannonShooterComponent ShooterComponent;

	FPossibleCannonTransition ValidCannonTransition;
	ACastleCannon TargetCannon;

	float SplineDistanceCurrent;
	float SplineDistanceBeginning;
	float SplineDistanceEnd;

	FHazeTimeLike TransitionTimelike;
	default TransitionTimelike.Duration = 2.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		ShooterComponent = UCastleCannonShooterComponent::GetOrCreate(Owner);

        TransitionTimelike.BindUpdate(this, n"OnTransitionTimelikeUpdate");
        TransitionTimelike.BindFinished(this, n"OnTransitionTimelikeFinished");
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!IsActive())
			UpdateValidCannonTransition();
    }

	void UpdateValidCannonTransition()
	{
		FVector2D LeftStickInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);

		if (FMath::Abs(LeftStickInput.X) < 0.5)
		{
			ValidCannonTransition.TransitionActor = nullptr;
			return;
		}

		FVector MovementDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);

		for (FPossibleCannonTransition PossibleTransition : ShooterComponent.GetPossibleTransitionsFromActiveCannon())
		{
			if (PossibleTransition.TransitionDirection == ECastleCannonTransitionDirection::Right && Player.CurrentlyUsedCamera.RightVector.DotProduct(MovementDirection) > 0)
			{
				ValidCannonTransition = PossibleTransition;
				TargetCannon = ShooterComponent.GetCannonTargetFromTransition(PossibleTransition.TransitionActor, ShooterComponent.ActiveCannon);

				return;				
			}
			else if (PossibleTransition.TransitionDirection == ECastleCannonTransitionDirection::Left && Player.CurrentlyUsedCamera.RightVector.DotProduct(MovementDirection) < 0)
			{
				ValidCannonTransition = PossibleTransition;
				TargetCannon = ShooterComponent.GetCannonTargetFromTransition(PossibleTransition.TransitionActor, ShooterComponent.ActiveCannon);

				return;		
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		FVector2D LeftStickInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);

		if (FMath::Abs(LeftStickInput.X) < 0.5f)
			return EHazeNetworkActivation::DontActivate;

		if (ValidCannonTransition.TransitionActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (ShooterComponent.ActiveCannon != nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (ValidCannonTransition.TransitionDirection == ECastleCannonTransitionDirection::Right)
		{
			SplineDistanceBeginning = 0.f;
			SplineDistanceEnd = ValidCannonTransition.TransitionActor.Spline.GetSplineLength();
		}
		else
		{
			SplineDistanceBeginning = ValidCannonTransition.TransitionActor.Spline.GetSplineLength();
			SplineDistanceEnd = 0.f;
		}

		ShooterComponent.ActiveCannon = nullptr;

		TransitionTimelike.PlayFromStart();
	}

	UFUNCTION()
	void OnTransitionTimelikeUpdate(float CurrentValue)
	{
		float CurrentDistance = FMath::Lerp(SplineDistanceBeginning, SplineDistanceEnd, CurrentValue);

		FTransform NewTransform;
		NewTransform.Location = ValidCannonTransition.TransitionActor.Spline.GetLocationAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World);
		//NewTransform.Rotation = ValidCannonTransition.TransitionActor.Spline.GetRotationAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World).Rotator();
		NewTransform.Scale3D = FVector::OneVector;

		Owner.SetActorTransform(NewTransform);
	}

	UFUNCTION()
	void OnTransitionTimelikeFinished()
	{
		ShooterComponent.ActiveCannon = TargetCannon;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	

	}
}