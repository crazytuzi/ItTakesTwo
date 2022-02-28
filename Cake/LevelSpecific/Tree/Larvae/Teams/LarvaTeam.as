class ULarvaTeam : UHazeAITeam
{
	TMap<AHazeActor, int> PathfindingClaimaints;
	int LastGrantedPathfindingFrame = 0;

	TSet<AHazeActor> OutsideNavMeshClaimants;

	bool ClaimPathfinding(AHazeActor Larva)
	{
		PathfindingClaimaints.FindOrAdd(Larva);

		int CurFrame = Time::GetFrameNumber();
		if (LastGrantedPathfindingFrame == CurFrame)
		{
			// Someone has already been granted their request this frame
			return false;
		}
		
		// No request granted as yet this frame, check if we haven't had a request 
		// granted in as many frames as the number of PathfindingClaimaints
		if (PathfindingClaimaints[Larva] + PathfindingClaimaints.Num() <= CurFrame)
		{
			LastGrantedPathfindingFrame = CurFrame;
			PathfindingClaimaints[Larva] = CurFrame;
			return true;
		}
		return false; 
	}

	void ReleasePathfinding(AHazeActor Larva)
	{
		PathfindingClaimaints.Remove(Larva);
	}

	bool ClaimOutsideNavMeshMovement(AHazeActor Larva)
	{
		if (OutsideNavMeshClaimants.Num() < 2)
		{
			OutsideNavMeshClaimants.Add(Larva);
			return true;	
		}
		return OutsideNavMeshClaimants.Contains(Larva);
	}

	bool IsClaimingOutsideNavMeshMovement(AHazeActor Larva)
	{
		return OutsideNavMeshClaimants.Contains(Larva);
	}

	void ReleaseOutSideNavMeshMovement(AHazeActor Larva)
	{
		OutsideNavMeshClaimants.Remove(Larva);
	}

	UFUNCTION(BlueprintOverride)
	void OnMemberLeft(AHazeActor Member)
	{
		ReleasePathfinding(Member);
	}
}

