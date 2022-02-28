import Vino.Movement.Dash.CharacterDashComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Movement.Components.MovementComponent;
import Peanuts.Movement.GroundTraceFunctions;

class UCharacterDashWallHitPrediction : UHazeCapability
{
	default RespondToEvent(MovementActivationEvents::Grounded);

	UHazeMovementComponent MoveComp;
	UCharacterDashComponent DashComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		MoveComp = UHazeMovementComponent::Get(Owner);
		DashComp = UCharacterDashComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!DashComp.bHasWallHitFeature)
			return EHazeNetworkActivation::DontActivate;

		if (!DashComp.bDashActive)
			return EHazeNetworkActivation::DontActivate;
		
		if (DashComp.PredictedHit.bBlockingHit)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!DashComp.bHasWallHitFeature)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!DashComp.bDashActive)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (DashComp.PredictedHit.bBlockingHit)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeTraceParams PredictionTrace;
		PredictionTrace.InitWithMovementComponent(MoveComp);
		PredictionTrace.DebugDrawTime = IsDebugActive() ? 0.f : -1.f;

		float PredictionTime = 0.07f;
		PredictionTrace.From = MoveComp.OwnerLocation;
		PredictionTrace.To = PredictionTrace.From + MoveComp.Velocity * PredictionTime;

		// set the correct distance forward to trace.

		FHazeHitResult PredictionHit;
		if (PredictionTrace.Trace(PredictionHit))
		{
			if (!IsHitSurfaceWalkableDefault(PredictionHit.FHitResult, MoveComp.WalkableAngle, MoveComp.WorldUp))
				DashComp.PredictedHit = PredictionHit;
		}
	}
}
