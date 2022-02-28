import Vino.Movement.Components.MovementComponent;
import Peanuts.Movement.GroundTraceFunctions;

class UCharacterStartMovementGroundCheckCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 2;

	UHazeMovementComponent MoveComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		FHazeTraceParams FloorTrace;
		FloorTrace.InitWithMovementComponent(MoveComp);
		FloorTrace.UnmarkToTraceWithOriginOffset();
		FloorTrace.To = FloorTrace.From - MoveComp.WorldUp * MoveComp.GetStepAmount(40.f);

		FHazeHitResult Hit;
		if (!FloorTrace.Trace(Hit))
		{
			OverrideToAirborne();
			return;
		}
		
		if (!IsHitSurfaceWalkableDefault(Hit.FHitResult, MoveComp.WalkableAngle, MoveComp.WorldUp))
		{
			OverrideToAirborne();
			return;
		}
			
		FMovementPhysicsState GroundState;
		GroundState.Impacts.DownImpact = Hit.FHitResult;
		GroundState.bIsSquished = false;
		GroundState.GroundedState = EHazeGroundedState::Grounded;
		
		MoveComp.OverridePhysicalStateHistory(GroundState, GroundState, true);
		if (!HasControl())
			Owner.SetCapabilityActionState(n"RemoteForceGroundedState", EHazeActionState::ActiveForOneFrame);
		
		if (Hit.ActorLocation.Distance(Owner.ActorLocation) > 1.f)
		{
			auto Player = Cast<AHazePlayerCharacter>(Owner);
			if (Player != nullptr)
				Player.RootOffsetComponent.FreezeAndResetWithTime(0.1f);
		}
	}

	void OverrideToAirborne()
	{
		FMovementPhysicsState GroundState;
		GroundState.bIsSquished = false;
		GroundState.GroundedState = EHazeGroundedState::Airborne;
		MoveComp.OverridePhysicalStateHistory(GroundState, GroundState, true);
	}
}
