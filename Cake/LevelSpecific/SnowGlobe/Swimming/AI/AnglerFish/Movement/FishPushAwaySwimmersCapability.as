import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourComponent;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Settings.FishComposableSettings;
import Vino.Movement.Helpers.BurstForceStatics;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class UFishPushAwaySwimmersCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Push");
	default CapabilityTags.Add(n"Movement");
	default TickGroup = ECapabilityTickGroups::GamePlay;

	UFishBehaviourComponent BehaviourComp;
	UFishComposableSettings Settings;
	TMap<AHazeActor, float> OngoingPushes;
	TSet<AHazeActor> BlockedBoosters;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BehaviourComp = UFishBehaviourComponent::Get(Owner);
		Settings = UFishComposableSettings::GetSettings(Owner);
		ensure((BehaviourComp != nullptr) && (Settings != nullptr));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Running locally, pushing is replicated using delegate crumbs on respective players crumb component 
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		TArray<AHazePlayerCharacter> Pushees = Game::GetPlayers();
		for (AHazePlayerCharacter Pushee : Pushees)
		{
			FVector PushVelocity = FVector::ZeroVector;
			if (ShouldPushAway(Pushee, PushVelocity))
			{
				UHazeCrumbComponent TargetCrumbComp = UHazeCrumbComponent::Get(Pushee);
				if (TargetCrumbComp != nullptr)
				{
					FHazeDelegateCrumbParams CrumbParams;
					CrumbParams.AddObject(n"Pushee", Pushee);
					CrumbParams.AddVector(n"PushVelocity", PushVelocity);
					TargetCrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbPush"), CrumbParams);
				}	
			}
		}

		// Clear push movement settings when they're over
		for (auto Entry : OngoingPushes)
		{
			if ((Entry.Value != 0.f) && (Entry.Key != nullptr) && (Time::GetGameTimeSince(Entry.Value) > Settings.PushDuration))
			{
				Entry.Key.ClearSettingsByInstigator(this);
				OngoingPushes[Entry.Key] = 0.f;
				if (BlockedBoosters.Contains(Entry.Key))
				{
					BlockedBoosters.Remove(Entry.Key);
					Entry.Key.UnblockCapabilities(SwimmingTags::Boost, this);
				}
				// Clear any queued bursts
				UHazeBurstForceComponent BurstComp = UHazeBurstForceComponent::Get(Entry.Key);
				if (BurstComp != nullptr)
					BurstComp.ClearAllForces();
			}
		}
	}

	bool ShouldPushAway(AHazeActor Target, FVector& OutPushVelocity)
	{
		// Only trigger pushes on target local side 
		if (!Target.HasControl())
			return false;

		// Never push away our target when attacking
		if ((BehaviourComp.State == EFishState::Attack) && (Target == BehaviourComp.Target))
			return false;

		// Never push away food
		if (BehaviourComp.Food.Contains(Target))
			return false;

		float PushTime = 0.f;
		if (OngoingPushes.Find(Target, PushTime) && (Time::GetGameTimeSince(PushTime) < 0.5f))
		{
			return false;
		}

		for (UCapsuleComponent Capsule : BehaviourComp.PushCapsules)
		{
			// Project target location to capsule center line
			FVector UpDir = Capsule.WorldTransform.Rotation.UpVector;
			FVector HalfCylinder = UpDir * (Capsule.CapsuleHalfHeight - Capsule.CapsuleRadius);
			FVector ProjectedLoc = Capsule.WorldLocation;
			float Dummy = 0.f; 
			Math::ProjectPointOnLineSegment(Capsule.WorldLocation + HalfCylinder, Capsule.WorldLocation - HalfCylinder, Target.ActorLocation, ProjectedLoc, Dummy);
			if (Target.ActorLocation.IsNear(ProjectedLoc, Capsule.CapsuleRadius))
			{
				FVector AwayNormal = (Target.ActorLocation - ProjectedLoc).GetSafeNormal();
				FVector TargetVel = Target.ActorVelocity;
				FVector TargetVelNormal = (TargetVel.IsNearlyZero(10.f) ? FVector::ZeroVector : TargetVel.GetSafeNormal());
				OutPushVelocity = (AwayNormal * 2.f + TargetVelNormal) / 3.f;
				OutPushVelocity *= Settings.PushForce;
				return true;
			}
		}
		return false;
	}

	UFUNCTION()
	void CrumbPush(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazeActor Pushee = Cast<AHazeActor>(CrumbData.GetObject(n"Pushee"));
		if (Pushee == nullptr)
			return;
		
		OngoingPushes.Add(Pushee, Time::GetGameTimeSeconds());

		FVector PushVelocity = CrumbData.GetVector(n"PushVelocity");
		FBurstForceFeaturePart BurstSettings;
		BurstSettings.GroundFriction = 0.f;
		BurstSettings.MinDuration = Settings.PushDuration;
		AddBurstForce(Pushee, PushVelocity, Pushee.ActorRotation, BurstSettings);

		UHazeBaseMovementComponent MoveComp = UHazeBaseMovementComponent::Get(Pushee);
		if (MoveComp != nullptr)
			MoveComp.SetAnimationToBeRequested(n"SwimmingTumble");

		if (!BlockedBoosters.Contains(Pushee))
		{
			BlockedBoosters.Add(Pushee);
			Pushee.BlockCapabilities(SwimmingTags::Boost, this);
		}

		UMovementSettings::SetGravityMultiplier(Pushee, 0.1f, Instigator = this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		for (auto Entry : OngoingPushes)
		{
			if (Entry.Key != nullptr)
				Entry.Key.ClearSettingsByInstigator(this);
		}
		for (AHazeActor Actor : BlockedBoosters)
		{
			Actor.UnblockCapabilities(SwimmingTags::Boost, this);
		}
		BlockedBoosters.Empty();
	}
}