import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

/*

	Makes sure that the shield slerps around the queen,
	and not go straight through her.
*/

UCLASS(HideCategories = "Cooking ComponentReplication Tags Sockets Clothing ClothingSimulation AssetUserData Mobile MeshOffset Collision Activation")
class USwarmTowardsVictimSlerper : UActorComponent
{
	AHazePlayerCharacter PreviousPlayer = nullptr;
	FVector SwarmToVictim = FVector::ZeroVector;
	FVector QueenToVictim = FVector::ZeroVector;
	FHazeSplineSystemPosition CurrentFollowSplineData;
	FHazeSplineSystemPosition StartFollowSplineData;
	float SlerpTimeRemaining = -1.f;
	float DesiredSlerpTime = 3.f;

	ASwarmActor SwarmActor = nullptr;
	UPrimitiveComponent QueenRootPrim = nullptr;
	USwarmVictimComponent VictimComp = nullptr;

	void ResetData()
	{
		PreviousPlayer = nullptr;
		SwarmToVictim = FVector::ZeroVector;
		QueenToVictim = FVector::ZeroVector;

		CurrentFollowSplineData = FHazeSplineSystemPosition();
		StartFollowSplineData = FHazeSplineSystemPosition();

		DirectionMultiplier = 1.f;

		SlerpTimeRemaining = -1.f;

		SwarmActor = nullptr;
		QueenRootPrim = nullptr;
		VictimComp = nullptr;
	}

	void InitTowardsVictimSlerper()
	{
		SwarmActor = Cast<ASwarmActor>(Owner);
		QueenRootPrim = Cast<UPrimitiveComponent>(SwarmActor.MovementComp.ArenaMiddleActor.GetRootComponent());
		VictimComp = SwarmActor.VictimComp;

		if(SlerpTimeRemaining <= 0.f)
		{
			DirectionMultiplier = 1.f;
			PreviousPlayer = VictimComp.PlayerVictim;
			SlerpTimeRemaining = -1.f;

			CurrentFollowSplineData = FHazeSplineSystemPosition();
			auto FollowSplineComp = UHazeSplineFollowComponent::Get(VictimComp.CurrentVictim);
			if (FollowSplineComp != nullptr && FollowSplineComp.HasActiveSpline())
			{
				CurrentFollowSplineData = FollowSplineComp.GetPosition().GetSpline().FindSystemPositionClosestToWorldLocation(
					SwarmActor.GetActorLocation()
				);
				StartFollowSplineData = CurrentFollowSplineData;
			}

			const FVector Queen_COM = QueenRootPrim.GetCenterOfMass(); 
			const FVector VictimPos = VictimComp.PlayerVictim.GetActorLocation();
			QueenToVictim = VictimPos - Queen_COM;
			SwarmToVictim = VictimPos - SwarmActor.GetActorLocation();
		}
	}

	float DirectionMultiplier = 1.f;

	float SlerpSpeed = 6000.f;

	void UpdateTowardsVictimSlerper(const float Dt)
	{
		const FVector Queen_COM = QueenRootPrim.GetCenterOfMass(); 

		FHazeSplineSystemPosition TargetFollowSplineData = FHazeSplineSystemPosition();

		auto FollowSplineComp = UHazeSplineFollowComponent::Get(VictimComp.CurrentVictim);
		if(FollowSplineComp != nullptr && FollowSplineComp.HasActiveSpline())
		{
			TargetFollowSplineData = FollowSplineComp.GetPosition();

			// player has jumped
			if(CurrentFollowSplineData.GetSpline() == nullptr)
			{
				CurrentFollowSplineData = TargetFollowSplineData.GetSpline().FindSystemPositionClosestToWorldLocation(
					SwarmActor.GetSwarmCenterOfParticles()
				);
				StartFollowSplineData = CurrentFollowSplineData;

				const float DistPositive = StartFollowSplineData.DistancePositive(TargetFollowSplineData);
				const float DistNegative = StartFollowSplineData.DistanceNegative(TargetFollowSplineData);
				DirectionMultiplier = FMath::Abs(DistPositive) < FMath::Abs(DistNegative) ? 1.f : -1.f;
			}

			// re-init
			if(PreviousPlayer != VictimComp.CurrentVictim)
			{
				PreviousPlayer = VictimComp.CurrentVictim;
				SlerpTimeRemaining = DesiredSlerpTime;

				CurrentFollowSplineData = TargetFollowSplineData.GetSpline().FindSystemPositionClosestToWorldLocation(
					SwarmActor.GetSwarmCenterOfParticles()
				);
				StartFollowSplineData = CurrentFollowSplineData;

				const float DistPositive = StartFollowSplineData.DistancePositive(TargetFollowSplineData);
				const float DistNegative = StartFollowSplineData.DistanceNegative(TargetFollowSplineData);
				DirectionMultiplier = FMath::Abs(DistPositive) < FMath::Abs(DistNegative) ? 1.f : -1.f;
			}
		}
		else
		{
			// no longer grinding. Stop lerping
			SlerpTimeRemaining = -1.f;
		}

		if(SlerpTimeRemaining > 0.f)
		{
			SlerpTimeRemaining = FMath::Clamp(SlerpTimeRemaining - Dt, 0.f, DesiredSlerpTime);
			// float SlerpAlpha = 1.f - (SlerpTimeRemaining / DesiredSlerpTime);
			// SlerpAlpha = FMath::SmoothStep(0.f, 1.f, SlerpAlpha);
			// PrintToScreen("Slerpin: " + SlerpAlpha);

			// if(DirectionMultiplier == 1.f)
			// 	CurrentFollowSplineData = StartFollowSplineData.LerpNegative(TargetFollowSplineData, SlerpAlpha);
			// else
			// 	CurrentFollowSplineData = StartFollowSplineData.LerpPositive(TargetFollowSplineData, SlerpAlpha);

			// CurrentFollowSplineData = StartFollowSplineData.LerpClosest(TargetFollowSplineData, SlerpAlpha);
			const float StepSize = SlerpSpeed * Dt; 
			CurrentFollowSplineData.Move(StepSize * DirectionMultiplier);

			const float DistToTarget = CurrentFollowSplineData.DistanceClosest(TargetFollowSplineData);
			const float Threshold = FMath::Max(500.f, StepSize); 
			if(FMath::Abs(DistToTarget) < Threshold)
				SlerpTimeRemaining = -1.f;

			const FVector VictimPos = CurrentFollowSplineData.GetWorldLocation();
			QueenToVictim = VictimPos - Queen_COM;
			SwarmToVictim = VictimPos - SwarmActor.GetActorLocation();

			// System::DrawDebugSphere(VictimPos);
			// System::DrawDebugSphere(StartFollowSplineData.GetWorldLocation(), LineColor = FLinearColor::Yellow);
			// System::DrawDebugSphere(TargetFollowSplineData.GetWorldLocation(), LineColor = FLinearColor::Green);
		}
		else
		{
			const FVector VictimPos = VictimComp.PlayerVictim.GetActorLocation();
			QueenToVictim = VictimPos - Queen_COM;
			SwarmToVictim = VictimPos - SwarmActor.GetActorLocation();
		}
	}

}
