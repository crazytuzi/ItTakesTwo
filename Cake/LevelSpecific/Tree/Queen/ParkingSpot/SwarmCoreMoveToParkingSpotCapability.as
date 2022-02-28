
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Queen.ParkingSpot.QueenParkingSpotComponent;

class USwarmCoreMoveToParkingSpotCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmMovement");

	default TickGroup = ECapabilityTickGroups::LastMovement;

	ASwarmActor SwarmActor = nullptr;
	UQueenParkingSpotComponent ParkingSpotComp = nullptr;
	int32 AssignedIndex = -1;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SwarmActor = Cast<ASwarmActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BlackboardContainsQueen())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"Queen", ConsumeQueenFromBlackboard());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(n"SwarmBehaviour", this);

		UObject QueenObject = ActivationParams.GetObject(n"Queen");
		AHazeActor QueenActor = Cast<AHazeActor>(QueenObject);

		ParkingSpotComp = UQueenParkingSpotComponent::Get(QueenActor); 
		AssignedIndex = ParkingSpotComp.SwarmParkingSpotIndiciesMap[SwarmActor];
	}

	bool BlackboardContainsQueen() const
	{
		return GetAttributeObject(n"Queen") != nullptr;
	}

	AHazeActor ConsumeQueenFromBlackboard()
	{
		UObject OutObject;
		ConsumeAttribute(n"Queen", OutObject);
		return Cast<AHazeActor>(OutObject);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"SwarmBehaviour", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{
		UpdateParkingSpotWorldTransforms(DeltaTime);
	}

	void UpdateParkingSpotWorldTransforms(const float Dt)
	{
		FTransform ParkingSpotWorldTransform = FTransform::Identity;

		if (ParkingSpotComp.bUseFixedRootLocation)
		{
			ParkingSpotWorldTransform = ParkingSpotComp.ParkingSpots_WorldSpaceFixed[AssignedIndex];
		}
		else
		{
			ParkingSpotWorldTransform = ParkingSpotComp.ParkingSpots_LocalSpace[AssignedIndex];

			// Follow Queen Translation AND Rotation
			if (ParkingSpotComp.bRotateParkingSpotsWithQueen)
			{
				ParkingSpotWorldTransform *= ParkingSpotComp.GetWorldTransform();
			}
			// Follow Queen Translation only. 
			else
			{
				ParkingSpotWorldTransform.AddToTranslation(ParkingSpotComp.GetWorldLocation());
			}
		}

		SwarmActor.MovementComp.SpringToTargetWithTime(
			ParkingSpotWorldTransform.GetLocation(),
			1.5f, // Duration = 1.5 seconds	 
			Dt
		);

		SwarmActor.MovementComp.InterpolateToTargetRotation(
			ParkingSpotWorldTransform.GetRotation(),
			3.f,
			false,
			Dt
		);

//		SwarmActor.MovementComp.InterpolateToTarget(ParkingSpotWorldTransform, 5000.f, true, Dt);

//		auto T = SwarmActor.MovementComp.DesiredSwarmActorTransform;
//		System::DrawDebugCoordinateSystem(T.GetLocation(), T.GetRotation().Rotator(), 100.f, 0.f, 10.f);

		//DEBUG
		// for(const FTransform& T : ParkingSpotComp.ParkingSpots_WorldSpace)
		// 	System::DrawDebugCoordinateSystem(T.Location, T.Rotation.Rotator(), 100.f, 0.f, 10.f);
		// RootPrim.AddAngularImpulseInDegrees(FVector(1.f, 2.f, 9.f), NAME_None, true);
 		// Swarmy.SetActorTransform(ParkingSpotComp.ParkingSpots_WorldSpace.Last());
		// Swarmy.MovementComp.DesiredSwarmActorTransform = ParkingSpotComp.ParkingSpots_WorldSpace.Last();  
	}

};