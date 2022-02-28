
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Input.MovementDirectionInputCapability;
import Vino.Movement.SplineLock.SplineLockComponent;

class UMovementDirectionSplineInputCapability : UMovementDirectionInputCapability
{
	default CapabilityDebugCategory = CapabilityTags::Movement;

	USplineLockComponent SplineLockComponent = nullptr;

	AHazePlayerCharacter Player;

	default TickGroupOrder = TickGroupOrder + 1;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (SplineLockComponent == nullptr)
			SplineLockComponent = USplineLockComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SplineLockComponent == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!SplineLockComponent.IsActiveltyConstraining())
		 	return EHazeNetworkActivation::DontActivate;

		if(HasControl())
		{
			if(MoveComp != nullptr)
			{
				return EHazeNetworkActivation::ActivateLocal;
			}
		}
		else
		{
			if(CrumbComp != nullptr)
			{
				return EHazeNetworkActivation::ActivateLocal;
			}
		}

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate()const
	{
		if (!SplineLockComponent.IsActiveltyConstraining())
		 	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Force tick when activated because all the calculation is done there,
		// and sometimes, we get activated from another capability unblocking.
		TickActive(Owner.GetActorDeltaSeconds());	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			UHazeSplineComponentBase Spline = SplineLockComponent.Spline;
			
			// Get the spline-tangent and contraint it to movement up
			FVector SplineTangent = Spline.FindTangentClosestToWorldLocation(Owner.ActorLocation, ESplineCoordinateSpace::World).GetSafeNormal();
			SplineTangent = SplineTangent.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

			const FVector WorldSpaceInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
			const float DotInputAndTangent = SplineTangent.DotProduct(WorldSpaceInput);

			CurrentInput = FVector::ZeroVector;
			if (FMath::Abs(DotInputAndTangent) > 0.25f)
				CurrentInput = SplineTangent * DotInputAndTangent;

		}
		else
		{
			CurrentInput = GetReplicatedInput();
		}

		Owner.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, CurrentInput);
		CrumbComp.SetReplicatedInputDirection(CurrentInput);
	}
};
