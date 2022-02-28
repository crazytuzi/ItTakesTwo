
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Input.MovementDirectionInputCapability;
import Vino.Movement.PlaneLock.PlaneLockUserComponent;


class UMovementDirectionPlaneInputCapability : UMovementDirectionInputCapability
{
	default CapabilityDebugCategory = CapabilityTags::Movement;

	UPlaneLockUserComponent PlaneLockComponent = nullptr;

	AHazePlayerCharacter Player;

	default TickGroupOrder = TickGroupOrder + 1;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		Player = Cast<AHazePlayerCharacter>(Owner);
		PlaneLockComponent = UPlaneLockUserComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!PlaneLockComponent.IsActiveltyConstraining())
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
		if (!PlaneLockComponent.IsActiveltyConstraining())
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
			const FVector PlaneTangent = PlaneLockComponent.Constraint.Plane.Normal.CrossProduct(MoveComp.WorldUp).GetSafeNormal();
			const FVector WorldSpaceInput = GetAttributeVector(AttributeVectorNames::MovementDirection);
			const float DotInputAndTangent = PlaneTangent.DotProduct(WorldSpaceInput);

			CurrentInput = FVector::ZeroVector;
			if (FMath::Abs(DotInputAndTangent) > 0.25f)
				CurrentInput = PlaneTangent * DotInputAndTangent;

		}
		else
		{
			CurrentInput = GetReplicatedInput();
		}

		Owner.SetCapabilityAttributeVector(AttributeVectorNames::MovementDirection, CurrentInput);
		CrumbComp.SetReplicatedInputDirection(CurrentInput);
	}
};
