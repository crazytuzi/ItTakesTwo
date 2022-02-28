import Cake.LevelSpecific.Tree.Larvae.Movement.LarvaMovementDataComponent;
import Cake.LevelSpecific.Tree.Wasps.Spawning.WaspRespawnerComponent;
import Cake.LevelSpecific.Tree.Larvae.Settings.LarvaComposableSettings;
import Cake.LevelSpecific.Tree.Larvae.Teams.LarvaTeam;
import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourComponent;

class ULarvaPathfollowingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Pathfinding");

	// This should run between behaviours setting destination and movement 
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	ULarvaBehaviourComponent BehaviourComp;
	ULarvaMovementDataComponent MoveDataComp;
	UHaze2DPathfindingComponent PathfindingComp;
	UHazeCrumbComponent CrumbComp;
	ULarvaComposableSettings Settings;
	ULarvaTeam Team;

	FVector OwnPrevLoc; 
	bool bAccuratePath = false;
	float OutsideDestinationWaitDistance = 200.f;
	float StuckDuration = 0.f; 
	float GotStuckTime = 0.f;
	float OutsideNavMeshEndTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = ULarvaBehaviourComponent::Get(Owner);
		MoveDataComp = ULarvaMovementDataComponent::Get(Owner);	
		PathfindingComp = UHaze2DPathfindingComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
		Settings = ULarvaComposableSettings::GetSettings(Owner);
		Team = Cast<ULarvaTeam>(Owner.GetJoinedTeam(n"LarvaTeam"));
		ensure((MoveDataComp != nullptr) && (PathfindingComp != nullptr) && (Settings != nullptr) && (Team != nullptr) && (BehaviourComp != nullptr) && (CrumbComp != nullptr));

		UWaspRespawnerComponent RespawnComp = UWaspRespawnerComponent::Get(Owner);
		RespawnComp.OnReset.AddUFunction(this, n"Reset");
	}	

	UFUNCTION(NotBlueprintCallable)
	void Reset()
	{
		MoveDataComp.Path.Locations.Empty();
		MoveDataComp.PathIndex = -1;
		OwnPrevLoc = Owner.ActorLocation;
		bAccuratePath = false;
		StuckDuration = 0.f;
		GotStuckTime = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Only active on control side when we want to crawl somewhere
		if (!HasControl())
            return EHazeNetworkActivation::DontActivate;
		if (BehaviourComp.bIsDead)
            return EHazeNetworkActivation::DontActivate;
        if (!MoveDataComp.bHasDestination)
			return EHazeNetworkActivation::DontActivate;	
        if (MoveDataComp.MoveType != ELarvaMovementType::Crawl)
            return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HasControl())
            return EHazeNetworkDeactivation::DeactivateLocal;
		if (BehaviourComp.bIsDead)
			return EHazeNetworkDeactivation::DeactivateLocal;
        if (!MoveDataComp.bHasDestination)
			return EHazeNetworkDeactivation::DeactivateLocal;
        if (MoveDataComp.MoveType != ELarvaMovementType::Crawl)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		Reset();
	}	

    UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
    {
		Team.ReleasePathfinding(Owner);
		Team.ReleaseOutSideNavMeshMovement(Owner);
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector OwnLoc = Owner.ActorLocation;
		FVector Destination = MoveDataComp.Destination;
		if (NeedsNewPath())
		{
			if (Team.ClaimPathfinding(Owner))
				bAccuratePath = FindPath(OwnLoc, Destination, MoveDataComp.PathIndex);
			else
				bAccuratePath = false; // Not allowed to pathfind right now, keep using old path but treat it as inaccurate
			OutsideDestinationWaitDistance = FMath::RandRange(200.f, 400.f);
		}
	
		// We're moving along path, have we reached current node?
		if (IsAt(MoveDataComp.PathIndex))
			MoveDataComp.PathIndex++;

		bool bOutsidePathMovement = false;
		if (MoveDataComp.Path.Locations.IsValidIndex(MoveDataComp.PathIndex))
		{
			// If we're at the end of a fresh path, we can move straight to destination. 
			// Otherwise move towards next path node
			if (MoveDataComp.PathIndex == MoveDataComp.Path.Locations.Num() - 1)
			{
				// We're at last leg of path
				if (bAccuratePath)
				{
					// Move directly to destination
					MoveDataComp.Destination = Destination;
				}
				else // Inaccurate path 
				{
					if ((Time::GetGameTimeSince(OutsideNavMeshEndTime) > 0.5f) && 
						(Time::GetGameTimeSince(GotStuckTime) > 2.f) && 
						Team.ClaimOutsideNavMeshMovement(Owner))
					{
						// A few lucky larvae at a time will be allowed to continue to destination.
						bOutsidePathMovement = true;
						MoveDataComp.Destination = Destination;
					}
					else if (MoveDataComp.Path.Locations.Last().IsNear(OwnLoc, OutsideDestinationWaitDistance))
					{
						// Almost there, wait for our turn or better path
						MoveDataComp.bTurnOnly = true; 
					}
					else
					{
						// Continue to last location in nav mesh
						MoveDataComp.Destination = GetPathLocation(MoveDataComp.PathIndex);
					}
				}
			}
			else
			{
				// Move to current path node
				MoveDataComp.Destination = GetPathLocation(MoveDataComp.PathIndex);
			}				
		}
		else
		{
			// Can't move along path right now, idle and turn towards destination instead
			MoveDataComp.bTurnOnly = true;
		}

		UpdateOutsidePathMovement(bOutsidePathMovement, DeltaTime);
		OwnPrevLoc = Owner.ActorLocation;

#if EDITOR
		//Owner.bHazeEditorOnlyDebugBool = true;
		if (Owner.bHazeEditorOnlyDebugBool)
			DebugDrawPath(OwnLoc, Destination, bAccuratePath, bOutsidePathMovement);
#endif		
	}

	FVector GetPathLocation(int Index)
	{
		FVector2D Loc = MoveDataComp.Path.Locations[MoveDataComp.PathIndex].Location;
		return FVector(Loc.X, Loc.Y, Owner.ActorLocation.Z);
	}

	bool NeedsNewPath()
	{
		if (!bAccuratePath)
			return true;

		if (MoveDataComp.Path.Locations.Num() == 0)
			return true;

		if (FVector2D(MoveDataComp.Destination).DistSquared(MoveDataComp.Path.Locations.Last().Location) > FMath::Square(Settings.AttackDistance * 0.25f))
		{
			// Only care about distance if we've also switched navpoly
			if (!PathfindingComp.IsWithinSamePolygon(MoveDataComp.Destination, MoveDataComp.Path.Locations.Last()))
				return true;
		}
		
		return false;
	}

	bool FindPath(FVector Start, FVector Destination, int& OutPathIndex)
	{
		// Allow path finding from outside the navmesh, ignore how far out we are 
		FHaze2DPathLocation PathStart = PathfindingComp.FindClosestPathLocation(Start);
		if (!ensure(PathStart.IsValid(PathfindingComp.NavMesh)))
		 	return false;

		FHaze2DPathLocation PathDest = PathfindingComp.FindClosestPathLocation(Destination);
		if (!ensure(PathDest.IsValid(PathfindingComp.NavMesh)))
		 	return false;

		if (!PathfindingComp.FindPath(PathStart, PathDest, MoveDataComp.Path))
			return false;

		// We have a new path to follow
		OutPathIndex = 1;

		// Is destination outside navmesh?
		if (!PathDest.IsNear(Destination, 20.f))
			return false;

		// Are we starting far outside
		if (!PathStart.IsNear(Start, 100.f))
			return false;

		// Path is good
		return true;
	}

	bool IsAt(int Index)
	{
		if (!MoveDataComp.Path.Locations.IsValidIndex(Index))
			return false;

		// Never move beyond end of path
		if (Index == MoveDataComp.Path.Locations.Num() - 1)
			return false;

		// Check if close enough
		FVector2D OwnLoc = FVector2D(Owner.ActorLocation);
		FVector2D PathLoc = MoveDataComp.Path.Locations[Index].Location;
		if (OwnLoc.DistSquared(PathLoc) < 16.f*16.f)
			return true;

		// Check for overshoot
		FVector2D PrevTo = PathLoc - FVector2D(OwnPrevLoc.X, OwnPrevLoc.Y);
		FVector2D CurTo = PathLoc - OwnLoc;
		if (PrevTo.DotProduct(CurTo) < 0.f)
			return true;

		return false;
	}

	void UpdateOutsidePathMovement(bool bOutsidePathMovement, float DeltaTime)
	{
		if (bOutsidePathMovement && MoveDataComp.bUsingPathfindingCollision)
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbUseNonPathfindingCollision"), FHazeDelegateCrumbParams());			
		else if (!bOutsidePathMovement && !MoveDataComp.bUsingPathfindingCollision)
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbUsePathfindingCollision"), FHazeDelegateCrumbParams());			

		if (bOutsidePathMovement)
		{
			if (Owner.ActualVelocity.IsNearlyZero(100.f))
				StuckDuration += DeltaTime;
			else 
				StuckDuration = 0.f;

			if (StuckDuration > 0.5f)
			{
				// We're stuck, let someone else try their luck for a while
				GotStuckTime = Time::GetGameTimeSeconds();
				Team.ReleaseOutSideNavMeshMovement(Owner);
				
				if (MoveDataComp.Path.Locations.Num() > 0)
					OutsideDestinationWaitDistance = MoveDataComp.Path.Locations.Last().GetDistance(Owner.ActorLocation) * 0.5f;
			}
		}
		else 
		{
			// We don't want to move outside navmesh
			Team.ReleaseOutSideNavMeshMovement(Owner);
			StuckDuration = 0.f;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void CrumbUsePathfindingCollision(const FHazeDelegateCrumbData& CrumbData)
	{
		MoveDataComp.UsePathfindingCollisionSolver();
		OutsideNavMeshEndTime = Time::GameTimeSeconds;
	}

	UFUNCTION(NotBlueprintCallable)
	void CrumbUseNonPathfindingCollision(const FHazeDelegateCrumbData& CrumbData)
	{
		MoveDataComp.UseNonPathfindingCollisionSolver();
	}

	void DebugDrawPath(FVector Start, FVector Destination, bool bAccuratePath, bool bOutsidePathMovement)
	{
		if (false)
		{
			float HeightOffset = Game::May.ActorLocation.Z - PathfindingComp.NavMesh.Owner.ActorLocation.Z + 100.f;
			PathfindingComp.NavMesh.DebugDrawOutline(0.f, FLinearColor::Green.ToFColor(true), 5.f, HeightOffset);
		}

		if (MoveDataComp.Path.Locations.Num() < 2)
		{
			System::DrawDebugLine(Start + FVector(0,0,100), Destination + FVector(0,0,100), FLinearColor::Red, 0.f, 5.f);
		}
		else
		{
			float Z = Start.Z + 100.f;
			float ZDelta = (Destination.Z + 150.f - Z) / (MoveDataComp.Path.Locations.Num() - 1.f);
			FVector PrevLoc = FVector(MoveDataComp.Path.Locations[0].Location.X, MoveDataComp.Path.Locations[0].Location.Y, Z);
			for (int i = 1; i < MoveDataComp.Path.Locations.Num(); i++)
			{
				FVector Loc = FVector(MoveDataComp.Path.Locations[i].Location.X, MoveDataComp.Path.Locations[i].Location.Y, Z);
				FLinearColor Color = (i < MoveDataComp.PathIndex) ? FLinearColor::Green : (bAccuratePath ? FLinearColor::LucBlue : FLinearColor::Yellow);
				System::DrawDebugLine(PrevLoc, Loc, Color, 0.f, 5.f);
				Z += ZDelta;
				PrevLoc = Loc;
			}
		}

		if (bOutsidePathMovement)
			System::DrawDebugSphere(Owner.ActorLocation + FVector(0.f,0.f,100.f), 50.f, 4, FLinearColor::Red);
	}
}

