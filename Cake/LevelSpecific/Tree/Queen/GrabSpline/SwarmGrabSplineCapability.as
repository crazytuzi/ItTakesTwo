
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Queen.GrabSpline.QueenGrabSplinePosComponent;
import Cake.LevelSpecific.Tree.Swarm.Behaviour.SwarmBehaviourSettingsContainer;

class USwarmGrabSplineCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmMovement");

	default TickGroup = ECapabilityTickGroups::LastMovement;

	ASwarmActor SwarmActor = nullptr;
	USwarmBehaviourSettings Settings = nullptr;
	UQueenGrabSplinePosComponent GrabSplinePosComp = nullptr;
	int32 AssignedIndex = -1;

	float ActivationTimeStamp = 0.f;
	bool bArrived = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SwarmActor = Cast<ASwarmActor>(Owner);
		Settings = USwarmBehaviourSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// auto FollowSplineComp = UHazeSplineFollowComponent::Get(SwarmActor.VictimComp.PlayerVictim);
		// if(FollowSplineComp == nullptr || !FollowSplineComp.HasActiveSpline())
		// 	return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	// Setting used before the capability activated
	bool PreCanAlwaysAttackVictim = false;

	FHazeSplineSystemPosition SplinePosData;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SwarmActor.PlaySwarmAnimation(
			Settings.Grab.AnimWhileMoving,
			this
		);

		Owner.BlockCapabilities(n"SwarmBehaviour", this);

		UObject GrabSplineComp;
		ConsumeAttribute(n"GrabSplinePosComp", GrabSplineComp);

		ensure(GrabSplineComp != nullptr);

		GrabSplinePosComp =  Cast<UQueenGrabSplinePosComponent>(GrabSplineComp); 
		AssignedIndex = GrabSplinePosComp.ClaimedPositions[SwarmActor];

		bArrived = false;
		ActivationTimeStamp = Time::GetGameTimeSeconds();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"SwarmBehaviour", this);
		SwarmActor.VictimComp.bCanAlwaysAttackVictim = PreCanAlwaysAttackVictim;
		SwarmActor.StopSwarmAnimationByInstigator(this);

		FollowSplineData = FHazeSplineSystemPosition();
	}

	bool bDone = false;
	FHazeSplineSystemPosition FollowSplineData;

	UFUNCTION(BlueprintOverride)
	void TickActive(const float DeltaTime)
	{

		if(FollowSplineData.GetSpline() == nullptr)
		{
			auto FollowSplineComp = UHazeSplineFollowComponent::Get(SwarmActor.VictimComp.PlayerVictim);
			if(FollowSplineComp != nullptr && FollowSplineComp.HasActiveSpline())
			{
				FollowSplineData = FollowSplineComp.GetPosition(); 
				FollowSplineData.Move(20000.f);
				FollowSplineData.Reverse();
				// PrintToScreenScaled("Reseting that guuy", 3.f, Scale = 2.f);
			}
		}

		// const FTransform SplinePosTransform = GrabSplinePosComp.GrabPositions_LocalSpace[AssignedIndex] * GrabSplinePosComp.GetWorldTransform();
		const FTransform SplinePosTransform = GrabSplinePosComp.GrabPositions_WorldSpace[AssignedIndex];

		const FVector QueenPos = GrabSplinePosComp.GetOwner().GetActorLocation();
		const FVector SwarmPos = SwarmActor.GetActorLocation();
		const FQuat SwarmToPosQuat = Math::MakeQuatFromX(SplinePosTransform.GetLocation() - SwarmPos);

 		// const FVector AlignOffset = SwarmToPosQuat.RotateVector(SwarmActor.SkelMeshComp.GetAlignBoneLocalLocation());
 		const FVector AlignOffset = SplinePosTransform.GetRotation().RotateVector(SwarmActor.SkelMeshComp.GetAlignBoneLocalLocation());

		FTransform DesiredTransform = FTransform(
			SwarmToPosQuat,
			SplinePosTransform.GetLocation() - AlignOffset 
		);

		if(!bDone || Time::GetGameTimeSince(ActivationTimeStamp) < (Settings.Grab.TimeToReachSplinePos*0.5f))
		{
			FollowSplineData.Move(-6000.f * DeltaTime);

			const FVector CurrentLocation = FollowSplineData.GetWorldLocation();
			const float CurrentDist = CurrentLocation.Distance(SplinePosTransform.GetLocation());
			if(CurrentDist < 2000.f)
				bDone = true;

			const FVector PlayerPos = SwarmActor.VictimComp.PlayerVictim.GetActorLocation();
			const FVector TelegraphPos = FollowSplineData.GetWorldLocation();
			// const FVector TelegraphPos = QueenPos + (FollowSplineData.GetWorldLocation() - QueenPos) * 0.8f;
			DesiredTransform.SetLocation(TelegraphPos);

			// System::DrawDebugSphere(TelegraphPos);
			// System::DrawDebugSphere(SplinePosTransform.GetLocation());
			// Print("CurrentDist: " + CurrentDist);
		}

		if(!bArrived && Time::GetGameTimeSince(ActivationTimeStamp) >= Settings.Grab.TimeUntilHandStartsClosing)
		{
			SwarmActor.PlaySwarmAnimation(
				Settings.Grab.GrabAnim,
				this
				// , FMath::Max(0.f, Settings.Grab.TimeToReachSplinePos - Settings.Grab.TimeUntilHandStartsClosing)
			);
			bArrived = true;

			// We'll clean this up OnDeactivated()
			// (the alternative was using animNotifies + another grab animation that was looping)
			PreCanAlwaysAttackVictim = SwarmActor.VictimComp.bCanAlwaysAttackVictim;
			SwarmActor.VictimComp.bCanAlwaysAttackVictim = true;
		}

		// Rotate towards the point -- unless we've started grabbing
		// it, in which case we'll apply the assigned rotation
		if(bArrived)
			DesiredTransform.SetRotation(SplinePosTransform.GetRotation());

		SwarmActor.MovementComp.SpringToTargetWithTime
		(
			DesiredTransform.GetLocation(),
			Settings.Grab.TimeToReachSplinePos,
			DeltaTime
		);

		SwarmActor.MovementComp.InterpolateToTargetRotation(
			DesiredTransform.GetRotation(),
			3.f,
			false,
			DeltaTime	
		);

//		const FVector AlignBone = SwarmActor.SkelMeshComp.GetSocketTransform(
//			n"Align",
//			ERelativeTransformSpace::RTS_World
//		).GetLocation();
//		System::DrawDebugSphere(AlignBone, LineColor = FLinearColor::Blue);
//		System::DrawDebugSphere(SplinePosTransform.GetLocation());
//		System::DrawDebugSphere(SwarmPos, LineColor = FLinearColor::Red);

	}

};