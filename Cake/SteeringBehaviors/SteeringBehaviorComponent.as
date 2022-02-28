import Cake.SteeringBehaviors.BoidObstacleComponent;
import Cake.SteeringBehaviors.BoidObstacleInfo;
import Cake.SteeringBehaviors.BoidTargetLocation;
import Vino.Movement.Components.MovementComponent;
import Cake.SteeringBehaviors.BoidObstacleStatics;
import Cake.SteeringBehaviors.BoidArea;

#if EDITOR
const FConsoleVariable CVar_DebugDrawEverything("SteeringBehavior.DrawEverything", 0);
const FConsoleVariable CVar_DebugDrawFollowLocations("SteeringBehavior.DrawFollowLocations", 0);
const FConsoleVariable CVar_DebugDrawAheadLocations("SteeringBehavior.DrawAheadLocations", 0);
const FConsoleVariable CVar_DebugDrawLimitLocations("SteeringBehavior.DrawLimitLocations", 0);
const FConsoleVariable CVar_DebugDrawLocation("SteeringBehavior.DrawLocation", 0);

class USteeringBehaviorComponentVisualizer : UHazeScriptComponentVisualizer
{
    default VisualizedClass = USteeringBehaviorComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
    {
        USteeringBehaviorComponent Comp = Cast<USteeringBehaviorComponent>(Component);
        if (!ensure((Comp != nullptr) && (Comp.GetOwner() != nullptr)))
		{
			return;
		}

		TArray<FVector> Points;
		int Count = 0;

		for(const ABoidTargetlocation Location : Comp.Path)
		{
			if(Location == nullptr)
			{
				return;
			}

			DrawWireSphere(Location.ActorLocation, 120.0f, FLinearColor::Green);
			Points.Add(Location.ActorLocation);
		}

		if(Points.Num() > 1)
		{
			FVector LastLocation = Points[0];
			for(int Index = 1, Num = Points.Num(); Index < Num; ++Index)
			{
				DrawArrow(LastLocation, Points[Index], FLinearColor::DPink, 50.0f, 10.0f);
				LastLocation = Points[Index];
			}
		}
/*
		if(Comp.bEnableLimitsBehavior)
		{
			const FVector SphereLocation = Comp.Limits.RadiusCenter != nullptr ? Comp.Limits.RadiusCenter.ActorLocation : Comp.Owner.ActorLocation;

			DrawWireSphere(SphereLocation, Comp.Limits.RadiusLimit, FLinearColor::Green, 6.0f, 16);
		}
		*/
    }
}

#endif // EDITOR

struct FAvoidanceAheadInfo
{
	FVector ObstacleOrigin = FVector::ZeroVector;
	bool bHit = false;

	void Reset()
	{
		ObstacleOrigin = FVector::ZeroVector;
		bHit = false;
	}
}

struct FAvoidanceInfo
{
	FAvoidanceAheadInfo Inside;
	FAvoidanceAheadInfo Far;
	FAvoidanceAheadInfo Near;

	void Reset()
	{
		Inside.Reset();
		Far.Reset();
		Near.Reset();
	}
}

struct FSteeringBehaviorSeekInfo
{
	UPROPERTY(meta = (DisplayName = "Target Location"))
	private FVector _TargetLocation;

	UPROPERTY(meta = (DisplayName = "Target Actor"))
	private AHazeActor _TargetActor;

	FVector GetSeekLocation() const property
	{
		if(_TargetActor != nullptr)
			return _TargetActor.ActorLocation;

		return _TargetLocation;
	}

	void SetTargetLocation(const FVector& TargetLocation) property { _TargetLocation = TargetLocation; }
	void SetTargetActor(AHazeActor TargetActor) property { _TargetActor = TargetActor; }
	AHazeActor GetTargetActor() const property { return _TargetActor; }

	UPROPERTY()
	float Size = 5.0f;
}

struct FSteeringBehaviorEvasionInfo
{
	UPROPERTY()
	TArray<AHazeActor> TargetsToEvade;

	UPROPERTY()
	float EvadeMaximum = 8000.0f;

	UPROPERTY()
	float EvadeMinimum = 5000.0f;

	UPROPERTY()
	float Size = 1.0f;

	// Automatically add players to the list of targets to evade.
	UPROPERTY()
	bool bEvadePlayers = true;
}

struct FSteeringBehaviorPursuitInfo
{
	UPROPERTY()
	AHazeActor PursuitTarget;

	UPROPERTY()
	float Size = 5.0f;
}

struct FSteeringBehaviorFollowInfo
{
	// This is the Actor we want to follow.
	UPROPERTY()
	AHazeActor FollowTarget;

	// Distance to the FollowTarget considered 'enough' and we will not attempt to follow anymore.
	UPROPERTY(meta = (ClampMin = 0.0))
	float FollowDistance = 100.0f;

	// Offset relative to the FollowTarget which will be the location in world that the steering will attempt to move towards.
	UPROPERTY()
	FVector LocalOffset = FVector::ZeroVector;

	// How much we will attempt to move towards the FollowTarget.
	UPROPERTY()
	float Size = 5.0f;
}

struct FSteeringBehaviorAvoidanceInfo
{
	FAvoidanceInfo Info;

	// Impact point of the trace hit.
	FVector ImpactLocation;

	// Origin of the primitive that the trace hit.
	FVector ImpactOrigin;

	FVector AvoidanceLocation;

	// First and furthest check for avoiding obstacles.
	UPROPERTY(meta = (EditCondition = "bCheckInside", EditConditionHides))
	float InsideSize = 2.0f;

	// First and furthest check for avoiding obstacles.
	UPROPERTY(meta = (EditCondition = "bCheckFar", EditConditionHides))
	float AheadFar = 800.0f;

	UPROPERTY(meta = (EditCondition = "bCheckFar", EditConditionHides))
	float AheadFarSize = 3.0f;

	// Last check when attempting to avoid obstacles.
	UPROPERTY(meta = (EditCondition = "bCheckNear", EditConditionHides))
	float AheadNear = 400.0f;

	UPROPERTY(meta = (EditCondition = "bCheckNear", EditConditionHides))
	float AheadNearSize = .9f;

	float DistanceToImpactOriginSq = 0.0f;

	bool bIsInside = false;
	bool bAppliedAvoidance = false;

	UPROPERTY()
	bool bCheckInside = true;

	UPROPERTY()
	bool bCheckFar = true;

	// Check twice when avoiding forward
	UPROPERTY()
	bool bCheckNear = false;
}

struct FSteeringBehaviorFlockingInfo
{
	// Members of the flock must be specified here for flocking to work.
	UPROPERTY()
	TArray<AHazeActor> FlockMembers;

	// Minimum distance a member of the flock needs to be within in order to enable flocking behavior.
	UPROPERTY()
	float FlockingDistanceMinimum = 2000.0f;

	// Scalar for moving away from flock members
	UPROPERTY(meta = (ClampMin = 0.0))
	float SeparationScalar = 1.0f;

	// Scalar for moving towards flock members.
	UPROPERTY(meta = (ClampMin = 0.0))
	float CohesionScalar = 1.0f;

	// Scalar for moving towards the velocity of each flock member.
	UPROPERTY(meta = (ClampMin = 0.0))
	float AlignmentScalar = 1.0f;

	UPROPERTY()
	float FlockingSize = 1.0f;
}

struct FSteeringBehaviorLimitsInfo
{
	UPROPERTY()
	float Size = 5.0f;
}

// Calculates a directional vector based on the settings provided.
UCLASS(hidecategories = "Physics Rendering Activation Cooking Tags LOD AssetUserData Collision")
class USteeringBehaviorComponent : USceneComponent
{
	// Create a pre-defined path for this boid to move along
	UPROPERTY(Category = SteeringBehavior)
	TArray<ABoidTargetlocation> Path;

	UPROPERTY(Category = SteeringBehavior)
	ABoidArea BoidArea = nullptr;

	// Seek behavior attempts to move towards a location.
	UPROPERTY(Category = SteeringBehavior)
	bool bEnableSeekBehavior = false;

	// Attempt to move towards a location in world space.
	UPROPERTY(Category = SteeringBehavior, meta = (EditCondition = "bEnableSeekBehavior", EditConditionHides))
	FSteeringBehaviorSeekInfo Seek;

	UPROPERTY(Category = SteeringBehavior)
	bool bEnableAvoidanceBehavior = false;
	
	UPROPERTY(Category = SteeringBehavior, meta = (EditCondition = "bEnableAvoidanceBehavior", EditConditionHides))
	FSteeringBehaviorAvoidanceInfo Avoidance;

	UPROPERTY(Category = SteeringBehavior)
	bool bEnableEvasionBehavior = false;

	UPROPERTY(Category = SteeringBehavior, meta = (EditCondition = "bEnableEvasionBehavior", EditConditionHides))
	FSteeringBehaviorEvasionInfo Evasion;

	// Pursuit atempts to predict the movement of 
	UPROPERTY(Category = SteeringBehavior)
	bool bEnablePursuitBehavior = false;

	UPROPERTY(Category = SteeringBehavior, meta = (EditCondition = "bEnablePursuitBehavior", EditConditionHides))
	FSteeringBehaviorPursuitInfo Pursuit;

	UPROPERTY(Category = SteeringBehavior)
	bool bEnableFollowBehavior = false;

	UPROPERTY(Category = SteeringBehavior, meta = (EditCondition = "bEnableFollowBehavior", EditConditionHides))
	FSteeringBehaviorFollowInfo Follow;

	// Flocking can keep
	UPROPERTY(Category = SteeringBehavior)
	bool bEnableFlockingBehavior = false;

	UPROPERTY(Category = SteeringBehavior, meta = (EditCondition = "bEnableFlockingBehavior", EditConditionHides))
	FSteeringBehaviorFlockingInfo Flocking;

	// Enable limitations of movement within a radius.
	UPROPERTY(Category = SteeringBehavior)
	bool bEnableLimitsBehavior = false;

	UPROPERTY(Category = SteeringBehavior, meta = (EditCondition = "bEnableLimitsBehavior", EditConditionHides))
	FSteeringBehaviorLimitsInfo Limits;

	private FVector Internal_TargetLocation;
	private FVector Internal_DirectionToTarget;

	private FVector Internal_GetAheadForwardVector() const
	{
		return ForwardTransform == nullptr ? Internal_GetDirectionToTarget() : ForwardTransform.ForwardVector;
	}

	// Used in avoidance as a optional transform for looking ahead.
	private USceneComponent ForwardTransform = nullptr;

	FVector Velocity;
	float VelocityMagnitude = 0.0f;

	void SetCurrentForwardTransform(USceneComponent NewForwardTransform) { ForwardTransform = NewForwardTransform; }

	TArray<AHazeActor> TempTargetsToEvade;

	bool bDirty = false;

	void DisableAllBehaviors()
	{
		bEnableSeekBehavior = 
		bEnablePursuitBehavior = 
		bEnableEvasionBehavior = 
		bEnableLimitsBehavior = 
		bEnableAvoidanceBehavior = 
		bEnableFollowBehavior = bEnableFlockingBehavior = false;
	}

	FVector GetDirectionToTargetLocation() const property
	{
		return  (Internal_TargetLocation - WorldLocation).GetSafeNormal();
	}

	FVector GetAheadLocation() const property
	{
		return WorldLocation + (Internal_GetAheadForwardVector() * Avoidance.AheadNear);
	}

	FVector GetAheadFarLocation() const property
	{
		return WorldLocation + (Internal_GetAheadForwardVector() * Avoidance.AheadFar);
	}

	FVector GetFollowLocation() const property
	{
		if(bEnableFollowBehavior && Follow.FollowTarget != nullptr)
		{
			return Follow.FollowTarget.ActorTransform.TransformPosition(Follow.LocalOffset);
		}

		return FVector::ZeroVector;
	}

	float GetDistanceToTargetLocation() const property { return WorldLocation.Distance(Internal_TargetLocation); }
	float GetDistanceToTargetLocationSq() const property { return WorldLocation.DistSquared(Internal_TargetLocation); }

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// If flocking is wanted, clear the list of empty entries and pointers to ourselves.
		for(int Index = Flocking.FlockMembers.Num() - 1; Index >= 0; --Index)
		{
			if(Flocking.FlockMembers[Index] == nullptr)
			{
				devEnsure(false, "An empty flock entry was found in " + Owner.GetName());
				Flocking.FlockMembers.RemoveAt(Index);
			}
			else if(Flocking.FlockMembers[Index] == Owner)
			{
				devEnsure(false, "An entry in FlockMembers contains ourselves: " + Owner.GetName());
				Flocking.FlockMembers.RemoveAt(Index);
			}
		}

		Internal_TargetLocation = WorldLocation;
	}

	bool LookAhead(FAvoidanceAheadInfo& AheadInfo, FVector Forward) const
	{
		return LookAheadInternal(AheadInfo, Forward, Avoidance.AheadNear);
	}

	bool LookAheadFar(FAvoidanceAheadInfo& AheadInfo, FVector Forward) const
	{
		return LookAheadInternal(AheadInfo, Forward, Avoidance.AheadFar);
	}

	bool LookAhead(FAvoidanceAheadInfo& AheadInfo) const
	{
		return LookAheadInternal(AheadInfo, Internal_GetAheadForwardVector(), Avoidance.AheadNear);
	}

	bool LookAheadFar(FAvoidanceAheadInfo& AheadInfo) const
	{
		return LookAheadInternal(AheadInfo, Internal_GetAheadForwardVector(), Avoidance.AheadFar);
	}

	bool IsInsideObstacle(FAvoidanceAheadInfo& AheadInfo) const
	{
		AheadInfo.bHit = IsPointOverlappingBoidObstacle(WorldLocation, AheadInfo.ObstacleOrigin);
		return AheadInfo.bHit;
	}

	private bool LookAheadInternal(FAvoidanceAheadInfo& AheadInfo, FVector Forward, float AheadValue) const
	{
		const FVector AheadPoint =  WorldLocation + (Forward * AheadValue);
		//System::DrawDebugLine(WorldLocation, AheadPoint, FLinearColor::Green);
		AheadInfo.bHit = IsPointOverlappingBoidObstacle(AheadPoint, AheadInfo.ObstacleOrigin);

		return AheadInfo.bHit;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Avoidance.bAppliedAvoidance = false;
		bDirty = true;
		CalculateSteeringBehaviors();
#if EDITOR

	
	if(bEnableFollowBehavior && (CVar_DebugDrawFollowLocations.GetInt() == 1 || CVar_DebugDrawEverything.GetInt() == 1))
	{
		System::DrawDebugSphere(FollowLocation, 100, 12, FLinearColor::Green, 0.0f);
	}

	if(bEnableAvoidanceBehavior && (CVar_DebugDrawAheadLocations.GetInt() == 1 || CVar_DebugDrawEverything.GetInt() == 1))
	{
		const float LineThickness = 20.0f;
		System::DrawDebugLine(WorldLocation, AheadLocation, FLinearColor::Red, 0.0f, LineThickness);
		System::DrawDebugLine(AheadLocation, AheadFarLocation, FLinearColor::Green, 0.0f, LineThickness);
	}

	if(CVar_DebugDrawEverything.GetInt() == 1)
	{
		System::DrawDebugSphere(TargetLocation, 128.0f, 12, FLinearColor::Purple);
		System::DrawDebugArrow(WorldLocation, WorldLocation + (DirectionToTargetLocation * 800.0f), 5.0f, FLinearColor::Purple);
		System::DrawDebugSphere(Seek.SeekLocation, 128.0f, 12, FLinearColor::Blue);
	}

#endif // EDITOR
	}

	FVector GetTargetLocation() property
	{
		if(!bDirty)
		{
			//CalculateSteeringBehaviors();
		}

		return Internal_TargetLocation;
	}

	FVector GetDirectionToTarget() property
	{
		if(!bDirty)
		{
			//CalculateSteeringBehaviors();
		}

		return Internal_DirectionToTarget;
	}

	private FVector Internal_GetDirectionToTarget() const
	{
		return (Internal_TargetLocation - WorldLocation).GetSafeNormal();
	}

	private void CalculateSteeringBehaviors()
	{
		Internal_TargetLocation = WorldLocation;

		if(bEnableSeekBehavior)
		{
			RunSeekBehavior();
		}

		if(bEnableAvoidanceBehavior)
		{
			RunAvoidanceBehavior();
		}

		if(bEnableEvasionBehavior)
		{
			RunEvasionBehavior();
		}

		if(bEnableLimitsBehavior)
		{
			RunLimitsBehavior();
		}

		if(bEnablePursuitBehavior)
		{
			RunPursuitBehavior();
		}

		if(bEnableFollowBehavior)
		{
			RunFollowBehavior();
		}

		if(bEnableFlockingBehavior)
		{
			RunFlockingBehavior();
		}

		Internal_DirectionToTarget = (Internal_TargetLocation - WorldLocation).GetSafeNormal();
		//DirectionToTargetHalf = (Internal_TargetLocation + WorldLocation).GetSafeNormal();

		if(Internal_DirectionToTarget.IsNearlyZero())
		{
			Internal_DirectionToTarget = ForwardVector;
		}

		bDirty = false;
	}

	FVector DirectionToTargetHalf;

	private void RunSeekBehavior()
	{
		const FVector ToLocation = Seek.SeekLocation - WorldLocation;
		const float DistanceToLocation = ToLocation.Size();

		const FVector DirectionToLocation = ToLocation.GetSafeNormal();
		
		if(DistanceToLocation < Seek.Size)
		{
			Internal_TargetLocation += DirectionToLocation * DistanceToLocation;
		}
		else
		{
			Internal_TargetLocation += DirectionToLocation * Seek.Size;
		}
	}

	private void RunAvoidanceBehavior()
	{
		Avoidance.bIsInside = false;
		Avoidance.Info.Reset();

		if(Avoidance.bCheckFar && LookAheadFar(Avoidance.Info.Far))
		{
			Avoidance.ImpactLocation = AheadFarLocation;
			Avoidance.DistanceToImpactOriginSq = WorldLocation.DistSquared(Avoidance.Info.Far.ObstacleOrigin);
			Avoidance.ImpactOrigin = Avoidance.Info.Far.ObstacleOrigin;
			ApplyAvoidance(Avoidance.Info.Far, Avoidance.AheadFarSize);
		}

		if(Avoidance.bCheckNear && LookAhead(Avoidance.Info.Near))
		{
			Avoidance.ImpactLocation = AheadLocation;
			Avoidance.DistanceToImpactOriginSq = WorldLocation.DistSquared(Avoidance.Info.Near.ObstacleOrigin);
			Avoidance.ImpactOrigin = Avoidance.Info.Near.ObstacleOrigin;
			ApplyAvoidance(Avoidance.Info.Near, Avoidance.AheadNearSize);
		}

		if(Avoidance.bCheckInside && IsInsideObstacle(Avoidance.Info.Inside))
		{
			Avoidance.bIsInside = Avoidance.Info.Inside.bHit;
			Avoidance.ImpactOrigin = Avoidance.Info.Far.ObstacleOrigin;
			Avoidance.DistanceToImpactOriginSq = WorldLocation.DistSquared(Avoidance.Info.Inside.ObstacleOrigin);
			ApplyAvoidance(Avoidance.Info.Inside, Avoidance.InsideSize);
		}
	}

	private void ApplyAvoidance(FAvoidanceAheadInfo AheadInfo, float Size)
	{
		Avoidance.bAppliedAvoidance = true;

		// Direction away from our current target location.
		const FVector DirectionFromHit = (WorldLocation - AheadFarLocation).GetSafeNormal();
		const FVector DirectionToHit = DirectionFromHit * -1.0f;
		

		if(Avoidance.bIsInside)
		{
			// If we are already inside the object, push outwards.

			const FVector OutwardsDirection = (WorldLocation - AheadInfo.ObstacleOrigin).GetSafeNormal();
			Internal_TargetLocation += OutwardsDirection * Size;
			//System::DrawDebugLine(WorldLocation, WorldLocation + OutwardsDirection * 1000, FLinearColor::Red, 0, 50);
		}
		else
		{
			
			//const FVector DirectionToHit = Hit.ImpactPoint + Hit.ImpactNormal * Avoidance.AheadFarSize;
			const FVector DirectionToOrigin = (AheadInfo.ObstacleOrigin - WorldLocation).GetSafeNormal() * -1.0f;
			FVector Cross = (DirectionToOrigin + (ForwardVector)).GetSafeNormal();//DirectionToOrigin.CrossProduct(RightVector);
			const FVector AvoidanceDirection = DirectionFromHit.RotateAngleAxis(90.0f, RightVector);//((WorldLocation + DirectionToHit) + (WorldLocation + DirectionFromHit));//  * Avoidance.AheadFarSize;
			//System::DrawDebugArrow(WorldLocation, WorldLocation + Cross * 1500, 50, FLinearColor::Green, 0, 15);
			//System::DrawDebugArrow(WorldLocation, WorldLocation + RightVector * 1500, 50, FLinearColor::Red, 0, 15);
			//System::DrawDebugArrow(WorldLocation, WorldLocation + DirectionToOrigin * 1500, 50, FLinearColor::Blue, 0, 15);
			//System::DrawDebugArrow(WorldLocation, WorldLocation + DirectionFromHit * 1500, 50, FLinearColor::Red, 0, 15);
			//System::DrawDebugArrow(WorldLocation, WorldLocation + DirectionToHit * 1500, 50, FLinearColor::Blue, 0, 15);
			//Internal_TargetLocation += AvoidanceDirection;// * Size;
			Internal_TargetLocation += Cross * Size;
		}

		//Internal_TargetLocation + DirectionToHit * Size;
	}

	private void RunEvasionBehavior()
	{
		FVector EvasionDirection;
		bool bEvadeSomething = false;

		TempTargetsToEvade.Empty();
		
		if(Evasion.TargetsToEvade.Num() > 0)
		{
			TempTargetsToEvade.Append(Evasion.TargetsToEvade);
		}

		if(Evasion.bEvadePlayers)
		{
			TempTargetsToEvade.Add(Game::GetCody());
			TempTargetsToEvade.Add(Game::GetMay());
		}

		for(AHazeActor Target: TempTargetsToEvade)
		{
			if(Target == nullptr)
			{
				continue;
			}

			if(Target.ActorLocation.DistSquared(WorldLocation) > (Evasion.EvadeMinimum * Evasion.EvadeMinimum))
			{
				continue;
			}

			UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Target);

			if(MoveComp == nullptr)
			{
				continue;
			}
			
			const float DistanceToTarget = Target.ActorLocation.Distance(WorldLocation);
			const float DistanceScalar = FMath::Max(Evasion.EvadeMaximum, DistanceToTarget) / Evasion.EvadeMaximum;

			float TargetSpeed = MoveComp.Velocity.Size();
			TargetSpeed = (TargetSpeed < 0.1f ? 1.0f : TargetSpeed);
			const float AheadPursuit = (DistanceToTarget / TargetSpeed);

			const FVector AheadEvadeLocation = Target.ActorLocation + (MoveComp.Velocity * AheadPursuit);
			const FVector DirectionAwayFromTarget = (WorldLocation - Target.ActorLocation).GetSafeNormal();
			EvasionDirection += DirectionAwayFromTarget * DistanceScalar;
			bEvadeSomething = true;
		}

		if(bEvadeSomething)
		{
			EvasionDirection.Normalize();
			Internal_DirectionToTarget += EvasionDirection * Evasion.Size;
		}
	}

	private void RunFollowBehavior()
	{
		const FVector ToFollowLocation = FollowLocation - WorldLocation;
		const float DistanceToFollowLocation = FMath::Max(ToFollowLocation.Size() - Follow.FollowDistance, 0.0f);

		const FVector DirectionToFollowLocation = ToFollowLocation.GetSafeNormal();

		if(DistanceToFollowLocation < Follow.Size)
		{
			Internal_TargetLocation += DirectionToFollowLocation * DistanceToFollowLocation;
		}
		else
		{
			Internal_TargetLocation += DirectionToFollowLocation * Follow.Size;
		}
	}

	private void RunPursuitBehavior()
	{
		UHazeMovementComponent MoveComp = UHazeMovementComponent::Get(Pursuit.PursuitTarget);

		if(MoveComp == nullptr)
		{
			return;
		}

		float TargetSpeed = MoveComp.Velocity.Size();
		TargetSpeed = (TargetSpeed < 0.1f ? 1.0f : TargetSpeed);

		const float DistanceToTarget = (Pursuit.PursuitTarget.ActorLocation - WorldLocation).Size();
		const float AheadPursuit = DistanceToTarget / TargetSpeed;

		// Get ahead location
		const FVector TargetLocationAhead = Pursuit.PursuitTarget.ActorLocation + (MoveComp.Velocity * AheadPursuit);

		Internal_TargetLocation += (TargetLocationAhead - WorldLocation).GetSafeNormal() * Pursuit.Size;
	}

	private void RunFlockingBehavior()
	{
		FVector Alignment;
		FVector Cohesion;
		FVector Separation;
		int NumNeighbours = 0;

		for(AHazeActor Boid : Flocking.FlockMembers)
		{
			if(WorldLocation.Distance(Boid.ActorLocation) > Flocking.FlockingDistanceMinimum)
			{
				continue;
			}

			UHazeMovementComponent TargetMovementComp = UHazeMovementComponent::Get(Boid);

			if(TargetMovementComp == nullptr)
			{
				continue;
			}

			Alignment += TargetMovementComp.Velocity;
			Cohesion += Boid.ActorLocation;
			Separation += (Boid.ActorLocation - WorldLocation);
			NumNeighbours++;
		}

		if(NumNeighbours == 0)
		{
			return;
		}

		Alignment /= float(NumNeighbours);
		Alignment.Normalize();

		Cohesion /= float(NumNeighbours);
		Cohesion = FVector(Cohesion - WorldLocation);
		Cohesion.Normalize();

		Separation /= float(NumNeighbours);
		Separation *= -1.0f;
		Separation.Normalize();

		FVector FlockingVector = (Alignment * Flocking.AlignmentScalar) + (Cohesion * Flocking.CohesionScalar) + (Separation * Flocking.SeparationScalar);
		FlockingVector.Normalize();

		Internal_TargetLocation += FlockingVector * Flocking.FlockingSize;
	}

	private void RunLimitsBehavior()
	{
		if(!devEnsure(BoidArea != nullptr, "No BoidArea when trying to run LimitsBehavior"))
			return;
		
		FVector ObstacleOrigin;
		bool bInside = BoidArea.Shape.IsPointOverlapping(WorldLocation);
		
		if(!bInside)
		{
			//System::DrawDebugSphere(WorldLocation, 300.0f, 12, FLinearColor::DPink, 0.0f, 10.0f);
			const FVector DirectionToLimitTarget = (BoidArea.Shape.ShapeCenterLocation - WorldLocation).GetSafeNormal();
			Internal_TargetLocation += DirectionToLimitTarget * Limits.Size;
		}
	}

	FVector GetRandomLocationInBoidArea() const property
	{
		if(!devEnsure(BoidArea != nullptr, "No area selected"))
			return WorldLocation;
	
		return BoidArea.RandomPointInsideShape;
	}

	/*
	FVector GetRandomLocationInRadius() const
	{
		FVector Point;
		float L;

		do
		{
			Point.X = FMath::FRand() * 2.0f - 1.0f;
			Point.Y = FMath::FRand() * 2.0f - 1.0f;
			Point.Z = FMath::FRand() * 2.0f - 1.0f;
			L = Point.SizeSquared();
		}
		while(L > 1.0f);

		return Limits.TargetLocation + Point * Limits.RadiusLimit;
	}
	*/
}
