
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Vino.Movement.Grinding.GrindingCapabilityTags;
import Vino.Movement.Grinding.UserGrindComponent;

class UQueenGrabSplinePosComponent : USceneComponent 
{
	// Will player finish grinding with this time?
	const float Threshold_Time = 1.f; 

	// make sure that player has grinded long enough distance wise
	const float Threshold_Distance = 200.f;

	// the location for the parking spots. 
	UPROPERTY(Meta = (MakeEditWidget), Category = "Grabber")
	TArray<FTransform> GrabPositions_LocalSpace;

	// These will be cached on the begin play and thats it. 
	TArray<FTransform> GrabPositions_WorldSpace;

	UPROPERTY(NotEditable, Category = "Grabber")
	TMap<ASwarmActor, int32> ClaimedPositions;

	UPROPERTY(NotEditable, Category = "Grabber")
	TMap<ASwarmActor, USwarmBehaviourBaseSettings> SwarmToPrevBehaviourSettingsMap;

	// Will have to return the original swarm behaviour once they are done parking 
	UPROPERTY(NotEditable, Category = "Grabber")
	TMap<ASwarmActor, UHazeCapabilitySheet> SwarmToPrevBehaviourSheetMap;

	// Whether the swarm can park
	UPROPERTY(NotEditable, Category = "Grabber")
	TArray<int32> VacantPositions;

	bool IsAnySwarmGrabbing() const
	{
		return ClaimedPositions.Num() > 0;
	}

	bool IsAnyPlayerGrinding() const
	{
		for(const auto Player : Game::GetPlayers())
		{
			if(IsPlayerGrinding(Player))
			{
				return true;
			}
		}
		return false;
	}

	AHazePlayerCharacter GetPlayerGrinding() const
	{
		for (auto player : Game::GetPlayers())
		{
			if (IsPlayerGrinding(player))
			{
				return player;
			}
		}

		return nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay() 
	{
		for (int32 i = 0; i < GrabPositions_LocalSpace.Num(); ++i)
		{
			VacantPositions.Add(i);
			GrabPositions_WorldSpace.Add(GrabPositions_LocalSpace[i] * GetWorldTransform());
		}
	}

	UFUNCTION(Category = "Grabber", CallInEditor)
	void SnapPositionsToNearestSplinePos()
	{
		TArray<UHazeSplineComponent> SplineComps;
		TArray<AActor> ActorsInLvl;
		Gameplay::GetAllActorsOfClass(AActor::StaticClass(), ActorsInLvl);
		for(AActor Actor : ActorsInLvl)
		{
			TArray<UHazeSplineComponent> SplineComponentsOnActor;
			Actor.GetComponentsByClass(SplineComponentsOnActor);
			SplineComps.Append(SplineComponentsOnActor);
		}

		ensure(SplineComps.Num() != 0);

		for(FTransform& GrabPos_LocalSpace : GrabPositions_LocalSpace)
		{
			FTransform GrabPos_WorldSpace = GrabPos_LocalSpace * GetWorldTransform();
			FVector ClosestLocation = FVector::ZeroVector;;
			float ClosestDistanceSQ = BIG_NUMBER;

			for(const UHazeSplineComponent Spline : SplineComps)
			{
				FVector ClosestPos = Spline.FindLocationClosestToWorldLocation(
					GrabPos_WorldSpace.GetLocation(),
					 ESplineCoordinateSpace::World
				);

				const float DistSQ = ClosestPos.DistSquared(GrabPos_WorldSpace.GetLocation());

				if(DistSQ < ClosestDistanceSQ)
				{
					ClosestDistanceSQ = DistSQ;
					ClosestLocation = ClosestPos;
				}
			}

			const FVector TowardsTarget = ClosestLocation - GrabPos_WorldSpace.GetLocation();

			// we are already there.. Rotation will be messed up if we
			const float DistSQ = TowardsTarget.SizeSquared();
			if(FMath::IsNearlyZero(DistSQ, KINDA_SMALL_NUMBER))
				continue;

			if(GrabPos_LocalSpace.GetRotation().IsIdentity())
			{
				const FQuat TowardsPosQuat = Math::MakeQuatFromX(TowardsTarget);
				GrabPos_WorldSpace.SetRotation(TowardsPosQuat);
			}

			GrabPos_WorldSpace.SetLocation(ClosestLocation);

			GrabPos_LocalSpace = GrabPos_WorldSpace;
			GrabPos_LocalSpace.SetToRelativeTransform(GetWorldTransform());
		}
	}

	bool CanGrabSplinePos(const ASwarmActor InSwarm) const
	{
		return HasVacancy() && !HasClaimedSpot(InSwarm) && IsAnyPlayerGrinding();
	}

	UFUNCTION(Category = "Grabber")
	void UnclaimSplinePos(ASwarmActor InSwarm)
	{
		if(ClaimedPositions.Contains(InSwarm) == false)
		{
			// trying to release swarm that isn't assigned to anything yet!
			ensure(false);
			return;
		}

		int32 VacantPos = ClaimedPositions[InSwarm];
		ClaimedPositions.Remove(InSwarm);
		VacantPositions.Add(VacantPos);
	}

	UFUNCTION(Category = "Grabber")
	void ReleaseSplinePos(ASwarmActor InSwarm)
	{
		if(HasClaimedSpot(InSwarm) == false)
		{
			// did you input the correct swarm??
			// trying to release a swarm which hasn't grabbed anything! 
			ensure(false);
			return;
		}

		UnclaimSplinePos(InSwarm);

  		InSwarm.SwitchTo(
			SwarmToPrevBehaviourSheetMap[InSwarm],
			SwarmToPrevBehaviourSettingsMap[InSwarm]
		);  

		SwarmToPrevBehaviourSettingsMap.Remove(InSwarm);
		SwarmToPrevBehaviourSheetMap.Remove(InSwarm);
	}

	UFUNCTION(Category = "Grabber")
	void GrabSplinePos(
		const int32 InVacantPosIndex,
		ASwarmActor InSwarm,
		const AHazePlayerCharacter InPlayer,
		UHazeCapabilitySheet BehaviourSheet,
		USwarmBehaviourBaseSettings BehaviourSettings
	)
	{
		// Claim Spline Pos
		int32 VacantPos = VacantPositions[InVacantPosIndex];
		ClaimedPositions.Add(InSwarm, VacantPos);
		VacantPositions.RemoveAt(InVacantPosIndex);

		// save previous behaviour
		SwarmToPrevBehaviourSettingsMap.Add(InSwarm, InSwarm.BehaviourComp.CurrentBehaviourSettings);
		SwarmToPrevBehaviourSheetMap.Add(InSwarm, InSwarm.BehaviourComp.CurrentBehaviourSheet);

		InSwarm.SetCapabilityAttributeObject(n"GrabSplinePosComp", this);
  		InSwarm.SwitchTo(BehaviourSheet, BehaviourSettings);  
	}

	int32 FindBestVacantPositionIndex(
		const ASwarmActor InSwarm,
		const AHazePlayerCharacter Player
	)
	{
		// @TODO: We can account for how long time it takes the swarm
		// to reach the destination and the players velocity. This will 
		// enable us to always pick the _best_ location possible based on PHYSICS

		// We'll pick the one furthest away from the player
		float FurthestDistanceSQ = 0.f;
		int32 FurthestIndex = 0;

		FVector PlayerLoc = Player.GetActorLocation();

		// System::FlushPersistentDebugLines();

		// Use Spline location instead..
		auto FollowSplineComp = UHazeSplineFollowComponent::Get(Player);
		if(FollowSplineComp.HasActiveSpline())
		{
			const FHazeSplineSystemPosition SplinePosData = FollowSplineComp.GetPosition(); 
			UHazeSplineComponentBase GrindSpline = SplinePosData.GetSpline();
			const auto VictimMoveComp = UHazeBaseMovementComponent::Get(Player);
			FVector PredictedVictimLocation = Player.GetActorLocation() + VictimMoveComp.Velocity * (1.f / 60.f);
			PlayerLoc = GrindSpline.FindLocationClosestToWorldLocation(PredictedVictimLocation, ESplineCoordinateSpace::World);

			// System::DrawDebugSphere(PlayerLoc, Duration = 5.f);
		}

		for (int32 i = 0; i < VacantPositions.Num(); ++i)
		for(const int32 VacantIndex : VacantPositions)
		{
			const FTransform GrabTM = GrabPositions_WorldSpace[VacantPositions[i]];
			const float DistSQ = GrabTM.GetLocation().DistSquared(PlayerLoc);
			if(DistSQ > FurthestDistanceSQ)
			{
				FurthestDistanceSQ = DistSQ;
				FurthestIndex = i;
			}
			// System::DrawDebugSphere(GrabTM.GetLocation(), 100.f, 12, FLinearColor::Yellow, 5.f);
		}

		// System::DrawDebugSphere(
		// 	GrabPositions_WorldSpace[VacantPositions[FurthestIndex]].GetLocation(),
		// 	100.f,
		// 	12,
		// 	FLinearColor::Blue,
		// 	5.f
		// );

		return FurthestIndex;
	}

	UFUNCTION(Category = "Grabber")
	void ClaimSplinePos(
		const int32 VacantPositionIndex,
		const ASwarmActor InSwarm,
		const AHazePlayerCharacter Player
	)
	{
		int32 VacantPos = VacantPositions[VacantPositionIndex];
		ClaimedPositions.Add(InSwarm, VacantPos);
		VacantPositions.RemoveAt(VacantPositionIndex);
	}

	bool HasClaimedSpot(const ASwarmActor InSwarm) const
	{
		return ClaimedPositions.Contains(InSwarm);
	}

	bool IsPlayerGrinding(AHazePlayerCharacter Player) const
	{
		// const bool bPlayerIsFollowingSpline = IsPlayerFollowingSpline(Player); 
		// if(!bPlayerIsFollowingSpline)
		// 	return false;


		const bool bPlayerGrindingTagIsActive = IsPlayerGrindingTagActive(Player);
		if(!bPlayerGrindingTagIsActive)
			return false;

		const bool bPlayerIsActuallyGoingToGrind = IsPlayerActuallyGoingToGrind(Player); 
		if(!bPlayerIsActuallyGoingToGrind)
			return false;

		const bool bPlayerIsGoingToFinishGrindWithinTime = IsPlayerGoingToFinishGrindWithinTime(Player); 
		if(bPlayerIsGoingToFinishGrindWithinTime)
			return false;

		return true;
	}

	bool HasVacancy() const
	{
		return VacantPositions.Num () != 0;
	}

	bool IsPlayerGrindingTagActive(AHazePlayerCharacter Player) const
	{
		// This is temp until simon completes his refactor of spline locking
		const auto PlayerGrindComp = UUserGrindComponent::Get(Player);
		const bool bActiveGrindSpline = PlayerGrindComp.HasActiveGrindSpline();
		return bActiveGrindSpline || Player.IsAnyCapabilityActive(GrindingCapabilityTags::Jump);

		// return Player.IsAnyCapabilityActive(GrindingCapabilityTags::Movement);
	}

	bool IsPlayerFollowingSpline(const AHazePlayerCharacter Player) const
	{
		auto FollowSplineComp = UHazeSplineFollowComponent::Get(Player);
		return FollowSplineComp == nullptr ? false : FollowSplineComp.HasActiveSpline();
	}

	bool IsPlayerGoingToFinishGrindWithinTime(AHazePlayerCharacter Player) const
	{
		auto FollowSplineComp = UHazeSplineFollowComponent::Get(Player);

		// Temp fix for not being able to get the followsplinecomp when the player is in air
		if(FollowSplineComp == nullptr || !FollowSplineComp.HasActiveSpline())
			return !IsPlayerGrindingTagActive(Player);

		const FHazeSplineSystemPosition SplinePosData = FollowSplineComp.GetPosition(); 
		UHazeSplineComponentBase GrindSpline = SplinePosData.GetSpline();

		const auto VictimMoveComp = UHazeBaseMovementComponent::Get(Player);
		FVector PredictedVictimLocation = Player.GetActorLocation() + VictimMoveComp.Velocity * Threshold_Time;

		const float PredictedDist = GrindSpline.GetDistanceAlongSplineAtWorldLocation(PredictedVictimLocation);

		const float SplineLength = SplinePosData.GetSpline().GetSplineLength(); 
		const float EndDist = SplinePosData.IsForwardOnSpline() ? SplineLength: 0.f;

		const float Threshold = Threshold_Distance;

		// players seems to switch sides when he is on the very end of the spline
		if(PredictedDist < Threshold || PredictedDist > (SplineLength - Threshold))
			return true;

		if(SplinePosData.IsForwardOnSpline())
			return PredictedDist >= EndDist;
		else
			return PredictedDist <= EndDist;
	}

	bool IsPlayerActuallyGoingToGrind(AHazePlayerCharacter Player) const
	{
		auto SplineFollowComp = UHazeSplineFollowComponent::Get(Player);

		// Temp fix for not being able to get the followsplinecomp when the player is in air
		if(SplineFollowComp == nullptr || !SplineFollowComp.HasActiveSpline())
			return IsPlayerGrindingTagActive(Player);

		const FHazeSplineSystemPosition SplinePosData = SplineFollowComp.GetPosition(); 
		UHazeSplineComponentBase GrindSpline = SplinePosData.GetSpline();

		const float CurrentDist = GrindSpline.GetDistanceAlongSplineAtWorldLocation(
			Player.GetActorLocation()
		);
		const float StartDist = !SplinePosData.IsForwardOnSpline() ? SplinePosData.GetSpline().GetSplineLength() : 0.f;
		const float Threshold = Threshold_Distance;

		return FMath::Abs(CurrentDist - StartDist) > Threshold;
	}
};
