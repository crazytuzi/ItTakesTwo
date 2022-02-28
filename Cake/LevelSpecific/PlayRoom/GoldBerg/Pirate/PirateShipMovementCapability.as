import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateShipActor;

class UPirateShipMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PirateEnemy");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 60;

	APirateShipActor Ship;
	UHazeAkComponent HazeAkComp;

	UHazeSplineComponent Spline;
	UBoxComponent CollisionPrimitive;

	float LastDistance = 0.f;
	float CurrentDistance;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Ship = Cast<APirateShipActor>(Owner);
		HazeAkComp = UHazeAkComponent::Get(Owner);
		CollisionPrimitive = UBoxComponent::Get(Ship, n"BlockingBox");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Ship.SplineToFollow == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!Ship.bActivated)
			return EHazeNetworkActivation::DontActivate;

		if (!Ship.CannonBallDamageableComponent.CanTakeDamage())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Ship.SplineToFollow == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!Ship.CannonBallDamageableComponent.CanTakeDamage())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!Ship.bActivated)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		Spline = Ship.SplineToFollow;
		GetDistanceDelta(Ship.WheelBoat);
		float StartDistance = Spline.GetDistanceAlongSplineAtWorldLocation(Ship.ActorLocation);

		FTransform StartTransform = Spline.GetTransformAtDistanceAlongSpline(StartDistance, ESplineCoordinateSpace::World);

		Ship.MovementEventID = Ship.AkComponent.HazePostEvent(Ship.MovementStart).PlayingID;

		CurrentDistance = StartDistance;
		StartTransform.Scale3D = FVector::OneVector;
		Ship.SetActorTransform(StartTransform);

		Ship.SplineFollowComp.ActivateSplineMovement(Spline, true);
		Ship.SplineFollowComp.IncludeSplineInActorReplication(this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Ship.SplineFollowComp.DeactivateSplineMovement();
		Ship.CleanupCurrentMovementTrail();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeSplineSystemPosition SplinePosition;

		const FVector LastActorLocation = Ship.GetActorLocation();

		if (HasControl())
		{
			float MoveDelta = Ship.Speed * DeltaTime;
			EHazeUpdateSplineStatusType Result = Ship.SplineFollowComp.UpdateSplineMovement(MoveDelta, SplinePosition);
			Ship.CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			FHazeActorReplicationFinalized ReplicationParams;
			Ship.CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ReplicationParams);	
			Ship.SplineFollowComp.UpdateReplicatedSplineMovement(ReplicationParams);
			SplinePosition = Ship.SplineFollowComp.GetPosition();
		}

		FTransform SplineTransform = SplinePosition.GetWorldTransform();
		SplineTransform.Scale3D = FVector::OneVector;
		Ship.SetActorTransform(SplineTransform);

		if (HasControl() && CollisionPrimitive != nullptr)
		{
			FHazeTraceParams TraceParams;
			TraceParams.InitWithPrimitiveComponent(CollisionPrimitive);
			TraceParams.IgnoreActor(Ship);
			
			TraceParams.From = LastActorLocation;
			TraceParams.To = Ship.ActorLocation;
			TraceParams.To += (TraceParams.To - TraceParams.From).GetSafeNormal() * 200;

			if(Ship.WheelBoat != nullptr)
			{
				FHazeHitResult TraceHit;
				if(TraceParams.Trace(TraceHit))
				{
					if(TraceHit.Actor == Ship.WheelBoat)
					{	
						Ship.WheelBoat.PendingImpactWithActor = Ship;
					}
				}
			}
		}		

		HazeAkComp.SetRTPCValue("Rtpc_Vehicle_Wheelboat_Enemy_DistanceDelta", GetDistanceDelta(Ship.WheelBoat), 0.f);	
	}

	float GetDistanceDelta(AHazeActor Target)
	{
		if(Ship.WheelBoat != nullptr)
		{
			float DistanceDeltaValue = 0.f;
			float Distance = Ship.GetActorLocation().Distance(Target.GetActorLocation());

			if(Distance > LastDistance)
			{
				DistanceDeltaValue  = 1;
			}
			else
			{
				DistanceDeltaValue = -1;
			}

			LastDistance = Distance;
			return DistanceDeltaValue;
		}
		else
		{
			LastDistance = BIG_NUMBER;
			return 0;
		}
	}
}