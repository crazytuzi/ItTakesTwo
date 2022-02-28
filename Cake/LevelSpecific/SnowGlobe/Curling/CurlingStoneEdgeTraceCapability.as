import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;

class UCurlingStoneEdgeTraceCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingStoneEdgeTraceCapability");
	default CapabilityTags.Add(n"Curling");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ACurlingStone CurlingStone;

	bool bFallingCompletely;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CurlingStone = Cast<ACurlingStone>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FHazeTraceParams TraceParamsWhole;
		TraceParamsWhole.InitWithMovementComponent(CurlingStone.MoveComp);
		TraceParamsWhole.IgnoreActor(CurlingStone);
		TraceParamsWhole.From = CurlingStone.ActorLocation;
		TraceParamsWhole.To = CurlingStone.ActorLocation + (-CurlingStone.ActorUpVector * 10.f);

		FHazeHitResult WholeHit;

		if(TraceParamsWhole.Trace(WholeHit))
			bFallingCompletely = false;
		else
			bFallingCompletely = true;

		if (bFallingCompletely)
		{
			CurlingStone.bOffEdge = false;
			return;
		}

		FHazeTraceParams TraceParamsLine;
		TraceParamsLine.InitWithMovementComponent(CurlingStone.MoveComp);
		TraceParamsLine.SetToLineTrace();
		TraceParamsLine.IgnoreActor(CurlingStone);
		TraceParamsLine.From = CurlingStone.ActorLocation;
		TraceParamsLine.To = CurlingStone.ActorLocation + (-CurlingStone.ActorUpVector * 200.f);

		FHazeHitResult LineHit;

		if(TraceParamsLine.Trace(LineHit))
		{
			CurlingStone.bOffEdge = false;
			CurlingStone.LastEdgeHitLocation = CurlingStone.ActorLocation;
		}
		else
		{
			CurlingStone.bOffEdge = true;
			CurlingStone.DistanceFromLastHit = (CurlingStone.LastEdgeHitLocation - CurlingStone.ActorLocation).Size();
			CurlingStone.FallDirection = CurlingStone.ActorLocation - CurlingStone.LastEdgeHitLocation;
			CurlingStone.FallDirection.Normalize();
		}
	}
}